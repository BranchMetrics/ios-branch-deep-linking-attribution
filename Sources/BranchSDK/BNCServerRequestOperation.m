//
//  BNCServerRequestOperation.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//

#import "BNCServerRequestOperation.h"
#import "BNCServerRequestQueue.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "NSError+Branch.h"
#import "BNCCallbackMap.h"

static const NSInteger kBNCMaxRetryCount = 3;
static const NSTimeInterval kBNCRetryDelay = 1.0;

@interface BNCServerRequestOperation ()
@property (nonatomic, assign, readwrite, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, readwrite, getter = isFinished) BOOL finished;
@end

@implementation BNCServerRequestOperation {
    BNCServerRequest *_request;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(BNCServerRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start {
    if (self.isCancelled) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Operation cancelled before starting: %@", self.request.requestUUID] error:nil];
        self.finished = YES;
        return;
    }

    self.executing = YES;
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation starting for request: %@", self.request.requestUUID] error:nil];

    BNCPreferenceHelper *preferenceHelper = self.preferenceHelper ?: [BNCPreferenceHelper sharedInstance];

    if (preferenceHelper.trackingDisabled) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Tracking disabled. Skipping request: %@", self.request.requestUUID] error:nil];
        self.executing = NO;
        self.finished = YES;
        return;
    }

    if ([self.request isKindOfClass:[BranchInstallRequest class]]) {
        // Install requests: no session validation needed
    } else if ([self.request isKindOfClass:[BranchOpenRequest class]]) {
        if (!preferenceHelper.randomizedBundleToken) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"User session not initialized (missing bundle token). Dropping request: %@", self.request.requestUUID] error:nil];
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
            });
            self.executing = NO;
            self.finished = YES;
            return;
        }
    } else {
        if (!preferenceHelper.randomizedDeviceToken || !preferenceHelper.sessionID || !preferenceHelper.randomizedBundleToken) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Missing session items (device token or session ID or bundle token). Dropping request: %@", self.request.requestUUID] error:nil];
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
            });
            self.executing = NO;
            self.finished = YES;
            return;
        }
    }

    // TODO: Handle specific `BranchOpenRequest` lock
    // `waitForOpenResponseLock` will block the current thread (the NSOperation's background thread)
    // until the global open response lock is released. This ensures proper sequencing
    // if another init session is in progress.
    /* if ([self.request isKindOfClass:[BranchOpenRequest class]]) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"BranchOpenRequest detected. Waiting for open response lock for %@", self.request.requestUUID] error:nil];
        [BranchOpenRequest waitForOpenResponseLock];
    }*/

    [self.request makeRequest:self.serverInterface
                          key:self.branchKey
                     callback:^(BNCServerResponse *response, NSError *error) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }

        if ([self shouldProcessWithoutRetry:error]) {
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:response error:error];
                if ([self.request isKindOfClass:[BranchEventRequest class]]) {
                    [[BNCCallbackMap shared] callCompletionForRequest:self.request withSuccessStatus:(error == nil) error:error];
                }
            });
            [self finishOperation];
        } else if ([self isReplayableRequest] && self.retryCount < kBNCMaxRetryCount) {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Scheduling retry %ld/%ld for request: %@", (long)(self.retryCount + 1), (long)kBNCMaxRetryCount, self.request.requestUUID] error:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kBNCRetryDelay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                BNCServerRequestQueue *queue = self.requestQueue;
                if (queue && !self.isCancelled) {
                    [queue enqueueRetry:self.request withRetryCount:self.retryCount + 1];
                }
            });
            [self finishOperation];
        } else {
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:response error:error];
                if ([self.request isKindOfClass:[BranchEventRequest class]]) {
                    [[BNCCallbackMap shared] callCompletionForRequest:self.request withSuccessStatus:NO error:error];
                }
            });
            [self finishOperation];
        }
    }];
}

- (BOOL)shouldProcessWithoutRetry:(NSError *)error {
    if (!error) return YES;

    NSInteger code = error.code;
    if (code == BNCTrackingDisabledError || code == BNCBadRequestError || code == BNCDuplicateResourceError) {
        return YES;
    }
    // HTTP client errors (4xx mapped to 100-499 range) are not retryable
    if (code >= 100 && code <= 499) {
        return YES;
    }
    return NO;
}

- (BOOL)isReplayableRequest {
    if (![self.request isKindOfClass:[BranchEventRequest class]]) {
        return NO;
    }
    // Requests with explicit callbacks should not be silently retried
    if ([[BNCCallbackMap shared] containsRequest:self.request]) {
        return NO;
    }
    return YES;
}

- (void)finishOperation {
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation finished for request: %@", self.request.requestUUID] error:nil];
    self.executing = NO;
    self.finished = YES;
}

- (void)cancel {
    [super cancel]; // Sets `isCancelled` to YES

    if (!self.isExecuting) {
        self.finished = YES;
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled before execution for request: %@", self.request.requestUUID] error:nil];
    } else {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled during execution for request: %@", self.request.requestUUID] error:nil];
    }
}

static inline void BNCPerformBlockOnMainThreadSync(dispatch_block_t block) {
    if (block) {
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
}

@end

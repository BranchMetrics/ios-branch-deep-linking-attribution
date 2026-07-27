//
//  BNCServerRequestOperation.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//

#import "BNCServerRequestOperation.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "NSError+Branch.h"
#import "BNCCallbackMap.h"
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"

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

+ (BOOL)requestRequiresSession:(BNCServerRequest *)request {
    // BranchInstallRequest is a subclass of BranchOpenRequest, listed for clarity.
    if ([request isKindOfClass:[BranchInstallRequest class]] ||
        [request isKindOfClass:[BranchOpenRequest class]] ||
        [request isKindOfClass:[BranchRequestOpen class]] ||
        [request isKindOfClass:[BranchRequestDeepLink class]]) {
        return NO;
    }
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

    if (![self.request isKindOfClass:[BranchRequestDeepLink class]]) {
        if ([preferenceHelper.attributionLevel isEqualToString:BranchAttributionLevelNone]) {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Attribution Level is 'NONE'. Skipping request: %@", self.request.requestUUID] error:nil];
            self.executing = NO;
            self.finished = YES;
            return;
        }
    }

    // Install, open and deep link requests establish the session, so they carry no session
    // tokens of their own. If we do not have a randomized bundle token, we receive one from
    // the service (via the v3/deeplink callback).
    if ([[self class] requestRequiresSession:self.request]) {
        if (!preferenceHelper.randomizedDeviceToken || !preferenceHelper.randomizedBundleToken) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Missing session items (device token or bundle token). Dropping request: %@. Initialize the Branch session before calling this API.", self.request.requestUUID] error:nil];
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
            });
            self.executing = NO;
            self.finished = YES;
            return;
        }
    }

    if ([self.request isKindOfClass:[BranchOpenRequest class]]) {
        [BranchOpenRequest setWaitNeededForOpenResponseLock];
    }
    
    if ([self.request isKindOfClass:[BranchRequestDeepLink class]]) {
        [BranchRequestDeepLink setWaitNeededForOpenResponseLock];
    }
    
    if ([self.request isKindOfClass:[BranchRequestOpen class]]) {
        [BranchRequestOpen setWaitNeededForOpenResponseLock];
    }

    [self executeRequest];
}

- (void)executeRequest {
    [self.request makeRequest:self.serverInterface
                          key:self.branchKey
                     callback:^(BNCServerResponse *response, NSError *error) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }

        BNCPerformBlockOnMainThreadSync(^{
            [self.request processResponse:response error:error];
            if ([self.request isKindOfClass:[BranchEventRequest class]]) {
                [[BNCCallbackMap shared] callCompletionForRequest:self.request withSuccessStatus:(error == nil) error:error];
            }
        });
        [self finishOperation];
    }];
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

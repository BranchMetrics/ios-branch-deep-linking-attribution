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

    // The KVO-observed state is read by the queue from threads other than the one writing it.
    _Atomic(BOOL) _executing;
    _Atomic(BOOL) _finished;

    // Guards the claim flags below, which elect the single owner of a one-shot transition.
    NSLock *_stateLock;
    BOOL _completionClaimed;
    BOOL _callbackClaimed;
}

- (instancetype)initWithRequest:(BNCServerRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
        _executing = NO;
        _finished = NO;
        _stateLock = [[NSLock alloc] init];
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isFinished {
    return _finished;
}

// Elects the single owner of this operation's completion transition. Returns YES to the
// first caller only; every later caller must leave the state alone. The queue treats a
// second completion notification for one operation as a fatal inconsistency.
- (BOOL)claimCompletion {
    [_stateLock lock];
    BOOL claimed = !_completionClaimed;
    _completionClaimed = YES;
    [_stateLock unlock];
    return claimed;
}

// Same election for the response callback, which can be invoked more than once.
- (BOOL)claimCallback {
    [_stateLock lock];
    BOOL claimed = !_callbackClaimed;
    _callbackClaimed = YES;
    [_stateLock unlock];
    return claimed;
}

- (void)setExecuting:(BOOL)executing {
    if (_executing == executing) {
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    if (_finished == finished) {
        return;
    }
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)start {
    if (self.isCancelled) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Operation cancelled before starting: %@", self.request.requestUUID] error:nil];
        [self finishOperation];
        return;
    }

    self.executing = YES;
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation starting for request: %@", self.request.requestUUID] error:nil];

    BNCPreferenceHelper *preferenceHelper = self.preferenceHelper ?: [BNCPreferenceHelper sharedInstance];

    if (![self.request isKindOfClass:[BranchRequestDeepLink class]]) {
        if ([preferenceHelper.attributionLevel isEqualToString:BranchAttributionLevelNone]) {
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Attribution Level is 'NONE'. Skipping request: %@", self.request.requestUUID] error:nil];
            [self finishOperation];
            return;
        }
    }

    if ([self.request isKindOfClass:[BranchInstallRequest class]]) {
        // Install requests: no session validation needed
    } else if ([self.request isKindOfClass:[BranchOpenRequest class]] || [self.request isKindOfClass:[BranchRequestOpen class]] || [self.request isKindOfClass:[BranchRequestDeepLink class]]) {
       // If we do not have a randomized bundle token, we should receive one from the service
        // We will receive from callback in v3/deeplink
    } else {
        if (!preferenceHelper.randomizedDeviceToken || !preferenceHelper.randomizedBundleToken) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Missing session items (device token or bundle token). Dropping request: %@", self.request.requestUUID] error:nil];
            BNCPerformBlockOnMainThreadSync(^{
                [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
            });
            [self finishOperation];
            return;
        }
    }

    if ([self.request isKindOfClass:[BranchOpenRequest class]]) {
        [BranchOpenRequest setWaitNeededForOpenResponseLock];
    }
    
    if ([self.request isKindOfClass:[BranchRequestDeepLink class]]) {
        [BranchRequestDeepLink setWaitNeededForDeepLinkResponseLock];
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
        if (![self claimCallback]) {
            [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Ignoring repeat response callback for request: %@", self.request.requestUUID] error:nil];
            return;
        }

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
    if (![self claimCompletion]) {
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation already completed, ignoring repeat finish for request: %@", self.request.requestUUID] error:nil];
        return;
    }
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation finished for request: %@", self.request.requestUUID] error:nil];
    self.executing = NO;
    self.finished = YES;
}

- (void)cancel {
    [super cancel]; // Sets `isCancelled` to YES

    // Completion belongs to `start`/`finishOperation` on the queue's thread. Finishing a
    // not-yet-started operation from here races `start`, and hands the queue a completion
    // for an operation it never started.
    if (!self.isExecuting) {
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

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
    // One-shot gate for the terminal transition. See -finishOperation.
    BOOL _didSignalFinish;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(BNCServerRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
        _executing = NO;
        _finished = NO;
        _didSignalFinish = NO;
    }
    return self;
}

- (BOOL)isAsynchronous {
    return YES;
}

// The queue reads these from its own threads while the network callback writes them, so the flags
// are read and written under the instance lock.
- (BOOL)isExecuting {
    @synchronized (self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized (self) {
        return _finished;
    }
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    @synchronized (self) {
        _executing = executing;
    }
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    @synchronized (self) {
        _finished = finished;
    }
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

// Moves the operation to its terminal state exactly once. Every path that ends the operation --
// cancellation, the attribution gate, failed session validation and the network callback -- funnels
// through here.
//
// NSOperationQueue watches isExecuting/isFinished to know when to drop its reference to an operation
// and schedule the next one. Signalling isFinished twice makes it complete, and release, the same
// operation twice; the freed entry is then walked on the next enqueue or completion, crashing inside
// __NSOQSchedule far from the code that caused it. The gate below keeps that transition single.
- (void)finishOperation {
    @synchronized (self) {
        if (_didSignalFinish) {
            return;
        }
        _didSignalFinish = YES;
    }

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation finished for request: %@", self.request.requestUUID] error:nil];
    if (self.isExecuting) {
        self.executing = NO;
    }
    self.finished = YES;
}

- (void)cancel {
    [super cancel]; // Sets `isCancelled` to YES

    // Deliberately does not finish the operation. The queue still calls -start on a cancelled
    // operation that has not begun, and -start finishes it. Note that cancelling does NOT make an
    // operation skip its dependencies: one cancelled behind an unfinished dependency is not started
    // until that dependency finishes, so a cancelled request may stay in the queue for a while.
    // Signalling isFinished from here instead would complete an operation the queue has not started,
    // corrupting the same bookkeeping described in -finishOperation.
    if (self.isExecuting) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled during execution for request: %@", self.request.requestUUID] error:nil];
    } else {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled before execution for request: %@", self.request.requestUUID] error:nil];
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

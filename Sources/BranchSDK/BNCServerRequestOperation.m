//
//  BNCServerRequestOperation.m
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/22/25.
//

#import "Private/BNCServerRequestOperation.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "NSError+Branch.h"
#import "BNCCallbackMap.h"

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

 /*TODO - This can be used for initSafetyCheck and adding dependencies
- (BOOL)isReady {
    BOOL ready = [super isReady];
    if (ready) {

    }
    return ready;
}*/

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

    // Check if tracking is disabled
    if (preferenceHelper.trackingDisabled) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Tracking disabled. Skipping request: %@", self.request.requestUUID] error:nil];
        self.executing = NO;
        self.finished = YES;
        return;
    }

    //  Session validation for requests
    if (!([self.request isKindOfClass:[BranchInstallRequest class]])) {
        if (!preferenceHelper.randomizedBundleToken) {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"User session not initialized (missing bundle token). Dropping request: %@", self.request.requestUUID] error:nil];
            BNCPerformBlockOnMainThreadSync(^{
             [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
             });
            self.executing = NO;
            self.finished = YES;
            return;
        }
    } else if (!([self.request isKindOfClass:[BranchOpenRequest class]])) {
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
        BNCPerformBlockOnMainThreadSync(^{
            [self.request processResponse:response error:error];
            if ([self.request isKindOfClass:[BranchEventRequest class]]) {
                [[BNCCallbackMap shared] callCompletionForRequest:self.request withSuccessStatus:(error == nil) error:error];
            }
        });
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation finished for request: %@", self.request.requestUUID] error:nil];
            self.executing = NO;
            self.finished = YES;

    }];
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

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

@interface BNCServerRequestOperation ()
@property (nonatomic, assign, readwrite, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, readwrite, getter = isFinished) BOOL finished;
@end

@implementation BNCServerRequestOperation {
    BNCServerRequest *_request; // Internal strong reference to the request
}

// Synthesize properties manually to control KVO notifications
@synthesize executing = _executing;
@synthesize finished = _finished;

// MARK: - Initialization

- (instancetype)initWithRequest:(BNCServerRequest *)request {
    self = [super init];
    if (self) {
        // Retain the request strongly for the lifetime of the operation
        _request = request;
        _executing = NO;
        _finished = NO;
    }
    return self;
}

// MARK: - NSOperation Overrides

// Declare this operation as asynchronous
- (BOOL)isAsynchronous {
    return YES;
}

// Determine if the operation is ready to execute
- (BOOL)isReady {
    BOOL ready = [super isReady];
    
    if (ready) {
        
    }
    
    return ready;
}

// KVO-compliant setter for `executing`
- (void)setExecuting:(BOOL)executing {
    // Notify KVO observers before and after state change
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

// KVO-compliant setter for `finished`
- (void)setFinished:(BOOL)finished {
    // Notify KVO observers before and after state change
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
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

// The entry point for the operation's execution
- (void)start {
    // 1. Always check for cancellation before starting work
    if (self.isCancelled) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Operation cancelled before starting: %@", self.request.requestUUID] error:nil];
        self.finished = YES; // Mark as finished if cancelled before execution
        return;
    }

    self.executing = YES; // Mark operation as executing

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation starting for request: %@", self.request.requestUUID] error:nil];

    
    // TODO: If tracking is disabled or if session prerequisites are not met,
    // we might prematurely fail and finish the operation.
    
    BNCPreferenceHelper *preferenceHelper = self.preferenceHelper ?: [BNCPreferenceHelper sharedInstance];
    
    //  Session validation for requests
    if (!Branch.trackingDisabled) {
        
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
            if (!preferenceHelper.randomizedDeviceToken || !preferenceHelper.sessionID) {
                [[BranchLogger shared] logError:[NSString stringWithFormat:@"Missing session items (device token or session ID). Dropping request: %@", self.request.requestUUID] error:nil];
                BNCPerformBlockOnMainThreadSync(^{
                    [self.request processResponse:nil error:[NSError branchErrorWithCode:BNCInitError]];
                 });
                self.executing = NO;
                self.finished = YES;
                return;
            }
        }
    }

    // 3. Handle specific `BranchOpenRequest` lock
    // `waitForOpenResponseLock` will block the current thread (the NSOperation's background thread)
    // until the global open response lock is released. This ensures proper sequencing
    // if another init session is in progress.
   /* if ([self.request isKindOfClass:[BranchOpenRequest class]]) {
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"BranchOpenRequest detected. Waiting for open response lock for %@", self.request.requestUUID] error:nil];
        [BranchOpenRequest waitForOpenResponseLock];
    }*/

    // 4. Make the actual network request
    // The `makeRequest` method calls the `BNCServerCallback` when it completes.
    [self.request makeRequest:self.serverInterface
                          key:self.branchKey
                     callback:^(BNCServerResponse *response, NSError *error) {
       
            
        BNCPerformBlockOnMainThreadSync(^{
            [self.request processResponse:response error:error];
            if ([self.request isKindOfClass:[BranchEventRequest class]]) {
                [[BNCCallbackMap shared] callCompletionForRequest:self.request withSuccessStatus:(error == nil) error:error];
            }
        });

            // 7. Mark operation as finished
            // This happens after `processResponse` completes, which for `BranchOpenRequest` also releases its specific lock.
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCServerRequestOperation finished for request: %@", self.request.requestUUID] error:nil];
            self.executing = NO;
            self.finished = YES;
        
    }];
}

// MARK: - Cancellation

- (void)cancel {
    [super cancel]; // Sets `isCancelled` to YES

    // If the operation is not yet executing, mark it as finished immediately.
    if (!self.isExecuting) {
        self.finished = YES;
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled before execution for request: %@", self.request.requestUUID] error:nil];
    } else {
        // If the request itself has a cancellation mechanism (e.g., cancelling the underlying NSURLSessionTask),
        // trigger it here.
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"BNCServerRequestOperation cancelled during execution for request: %@", self.request.requestUUID] error:nil];
    }
}

@end

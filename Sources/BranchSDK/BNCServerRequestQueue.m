//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"
#import "BranchRequestDeepLink.h"
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "Private/BNCServerRequestOperation.h"
#import "Branch.h"

// Safety net only. The wait lock is normally released as soon as the session establishing
// request finishes, whether it succeeded or failed. This timeout covers the case where the
// host app never initializes the session at all, so held requests cannot leak forever.
static NSTimeInterval const BNCSessionWaitLockDefaultTimeout = 15.0;

@interface BNCServerRequestQueue ()
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) BNCServerInterface *serverInterface;
@property (copy, nonatomic) NSString *branchKey;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;
@property (weak, nonatomic) BNCServerRequestOperation *currentInitOperation;

// Requests that need a session but were enqueued before one was established.
@property (strong, nonatomic) NSMutableArray<BNCServerRequestOperation *> *sessionWaitingOperations;
@property (assign, nonatomic) BOOL sessionWaitLockReleased;
@property (assign, nonatomic) NSTimeInterval sessionWaitLockTimeout;

@end

@implementation BNCServerRequestQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationQueue = [NSOperationQueue new];
        // Set maxConcurrentOperationCount to 1 for serial execution
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.name = @"com.branch.sdk.serverRequestQueue";
        self.sessionWaitingOperations = [NSMutableArray array];
        self.sessionWaitLockReleased = NO;
        self.sessionWaitLockTimeout = BNCSessionWaitLockDefaultTimeout;
    }
    return self;
}

- (void)configureWithServerInterface:(BNCServerInterface *)serverInterface
                           branchKey:(NSString *)branchKey
                    preferenceHelper:(BNCPreferenceHelper *)preferenceHelper {
    self.serverInterface = serverInterface;
    self.branchKey = branchKey;
    self.preferenceHelper = preferenceHelper;
}

- (void)enqueue:(BNCServerRequest *)request{
    [self enqueue:request withPriority:NSOperationQueuePriorityNormal];
}

- (void)enqueue:(BNCServerRequest *)request withPriority:(NSOperationQueuePriority)priority {
    if (!request) {
        [[BranchLogger shared] logError:@"Attempted to enqueue nil request." error:nil];
        return;
    }

    BNCServerRequestOperation *operation = [[BNCServerRequestOperation alloc] initWithRequest:request];

    operation.serverInterface = self.serverInterface;
    operation.branchKey = self.branchKey;
    operation.preferenceHelper = self.preferenceHelper;
    operation.queuePriority = priority;

    if (![BNCServerRequestOperation requestRequiresSession:request]) {
        // Session establishing request. Track it so requests held behind it are released
        // as soon as it finishes, whether it succeeds or fails.
        [self trackSessionEstablishingOperation:operation];
        [self.operationQueue addOperation:operation];
    } else if ([self holdOperationIfSessionNotReady:operation]) {
        // A request that needs a session is held until the session is established, instead
        // of racing ahead of the open with the device token persisted by a previous launch.
        return;
    } else {
        [self addInitDependencyIfNeeded:operation];
        [self.operationQueue addOperation:operation];
    }

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Enqueued request: %@. Current queue depth: %lu", request.requestUUID, (unsigned long)self.operationQueue.operationCount] error:nil];
}

- (BOOL)isSessionWaitLockReleased {
    @synchronized (self) {
        return self.sessionWaitLockReleased;
    }
}

- (NSUInteger)sessionWaitingRequestCount {
    @synchronized (self) {
        return self.sessionWaitingOperations.count;
    }
}

- (void)trackSessionEstablishingOperation:(BNCServerRequestOperation *)operation {
    if ([operation.request isKindOfClass:[BranchOpenRequest class]]) {
        @synchronized (self) {
            self.currentInitOperation = operation;
        }
    }

    __weak __typeof(self) weakSelf = self;
    NSString *requestUUID = operation.request.requestUUID;
    operation.completionBlock = ^{
        [weakSelf releaseSessionWaitLockWithReason:
            [NSString stringWithFormat:@"session request %@ finished", requestUUID]];
    };
}

// Holds the operation if the session is not ready yet. Deciding and holding under one lock
// keeps a concurrent release from stranding an operation that was just added to the list.
- (BOOL)holdOperationIfSessionNotReady:(BNCServerRequestOperation *)operation {
    BOOL isFirstHeldOperation = NO;
    @synchronized (self) {
        if (self.sessionWaitLockReleased) {
            return NO;
        }
        [self.sessionWaitingOperations addObject:operation];
        isFirstHeldOperation = (self.sessionWaitingOperations.count == 1);
    }

    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Request %@ needs a session. Holding it until session initialization completes.", operation.request.requestUUID] error:nil];

    if (isFirstHeldOperation) {
        [self scheduleSessionWaitLockTimeout];
    }
    return YES;
}

- (void)scheduleSessionWaitLockTimeout {
    NSTimeInterval timeout = self.sessionWaitLockTimeout;
    if (timeout <= 0) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [weakSelf releaseSessionWaitLockWithReason:@"timed out waiting for session initialization"];
    });
}

// Releases every held request into the operation queue. Once released, the lock stays open
// for the lifetime of the queue: later requests take the regular init dependency path.
- (void)releaseSessionWaitLockWithReason:(NSString *)reason {
    NSArray<BNCServerRequestOperation *> *heldOperations = nil;
    @synchronized (self) {
        if (self.sessionWaitLockReleased && self.sessionWaitingOperations.count == 0) {
            return;
        }
        self.sessionWaitLockReleased = YES;
        heldOperations = [self.sessionWaitingOperations copy];
        [self.sessionWaitingOperations removeAllObjects];
    }

    if (heldOperations.count == 0) {
        return;
    }

    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Releasing %lu held request(s): %@.", (unsigned long)heldOperations.count, reason] error:nil];

    for (BNCServerRequestOperation *operation in heldOperations) {
        if (operation.isCancelled || operation.isFinished) {
            continue;
        }
        [self addInitDependencyIfNeeded:operation];
        [self.operationQueue addOperation:operation];
    }
}

- (NSInteger)queueDepth {
    NSInteger count = 0;
    for (NSOperation *op in self.operationQueue.operations) {
        if (!op.isExecuting && !op.isFinished && !op.isCancelled) {
            count++;
        }
    }
    // Requests held for session initialization have not reached the operation queue yet.
    return count + (NSInteger)[self sessionWaitingRequestCount];
}

- (void)addInitDependencyIfNeeded:(BNCServerRequestOperation *)operation {
    // Non-init requests depend on the current init operation (if one is active)
    BNCServerRequestOperation *initOp = nil;
    @synchronized (self) {
        initOp = self.currentInitOperation;
    }
    if (initOp && initOp != operation && !initOp.isFinished && !initOp.isCancelled) {
        [operation addDependency:initOp];
    }
}

- (void)clearQueue {
    [[BranchLogger shared] logDebug:@"Clearing all pending operations from the queue." error:nil];

    NSArray<BNCServerRequestOperation *> *heldOperations = nil;
    @synchronized (self) {
        heldOperations = [self.sessionWaitingOperations copy];
        [self.sessionWaitingOperations removeAllObjects];
    }
    for (BNCServerRequestOperation *operation in heldOperations) {
        [operation cancel];
    }

    [self.operationQueue cancelAllOperations];
}

- (void)cancelPendingDeepLinkRequests {
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCServerRequestOperation class]]) {
            BNCServerRequestOperation *reqOp = (BNCServerRequestOperation *)op;
            if ([reqOp.request isKindOfClass:[BranchRequestDeepLink class]] && !op.isExecuting) {
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Cancelling pending BranchRequestDeepLink operation: %@", reqOp.request.requestUUID] error:nil];
                [op cancel];
            }
        }
    }
}

// These methods now need to iterate through the operations in the NSOperationQueue.
- (BOOL)containsInstallOrOpen {
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCServerRequestOperation class]]) {
            BNCServerRequestOperation *requestOp = (BNCServerRequestOperation *)op;
            if ([requestOp.request isKindOfClass:[BranchOpenRequest class]]) {
                return YES;
            }
        }
    }
    return NO;
}

- (BranchOpenRequest *)findExistingInstallOrOpen {
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCServerRequestOperation class]]) {
            BNCServerRequestOperation *requestOp = (BNCServerRequestOperation *)op;
            BNCServerRequest *request = requestOp.request;
            if ([request isKindOfClass:[BranchOpenRequest class]]) {
                BranchOpenRequest *openRequest = (BranchOpenRequest *)request;
                return openRequest;
            }
        }
    }
    return nil;
}

- (NSString *)description {
    NSMutableArray<NSString *> *requestUUIDs = [NSMutableArray array];
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCServerRequestOperation class]]) {
            if (!op.isFinished && !op.isCancelled) {
                [requestUUIDs addObject:((BNCServerRequestOperation *)op).request.requestUUID];
            } else {
                [requestUUIDs addObject:[NSString stringWithFormat:@"(Completed/Cancelled: %@)", ((BNCServerRequestOperation *)op).request.requestUUID]];
            }
        }
    }
    NSArray<BNCServerRequestOperation *> *heldOperations = nil;
    @synchronized (self) {
        heldOperations = [self.sessionWaitingOperations copy];
    }
    for (BNCServerRequestOperation *operation in heldOperations) {
        [requestUUIDs addObject:[NSString stringWithFormat:@"(Awaiting session: %@)", operation.request.requestUUID]];
    }

    return [NSString stringWithFormat:@"<BNCServerRequestQueue: %p> Operations (%ld): %@", self, (long)self.queueDepth, [requestUUIDs description]];
}

+ (instancetype)getInstance {
    static BNCServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        sharedQueue = [[BNCServerRequestQueue alloc] init];
    });
    return sharedQueue;
}

@end

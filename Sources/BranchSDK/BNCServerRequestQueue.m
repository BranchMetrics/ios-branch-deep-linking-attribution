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
#import "BranchRequestOpen.h"
#import "BranchRequestDeepLink.h"
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "Private/BNCServerRequestOperation.h"
#import "Branch.h"

// Runs a foreground open check after the resolves it depends on finish.
@interface BNCForegroundOpenCheckOperation : NSOperation
@property (copy, nonatomic) dispatch_block_t block;
@end

@implementation BNCForegroundOpenCheckOperation

- (void)main {
    dispatch_block_t block = self.block;
    if (block) block();
}

@end

@interface BNCServerRequestQueue ()
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) BNCServerInterface *serverInterface;
@property (copy, nonatomic) NSString *branchKey;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;
@property (weak, nonatomic) BNCServerRequestOperation *currentInitOperation;

@end

@implementation BNCServerRequestQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationQueue = [NSOperationQueue new];
        // Set maxConcurrentOperationCount to 1 for serial execution
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.operationQueue.name = @"com.branch.sdk.serverRequestQueue";
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

    // Cancels pending foreground open checks when an install or open is enqueued.
    if ([self isInstallOrOpenRequest:request]) {
        [self cancelDeferredForegroundOpenChecks];
    }

    [self addInitDependencyIfNeeded:operation];
    [self.operationQueue addOperation:operation];

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Enqueued request: %@. Current queue depth: %lu", request.requestUUID, (unsigned long)self.operationQueue.operationCount] error:nil];
}

- (NSInteger)queueDepth {
    NSInteger count = 0;
    for (NSOperation *op in self.operationQueue.operations) {
        if (!op.isExecuting && !op.isFinished && !op.isCancelled) {
            count++;
        }
    }
    return count;
}

// Init traffic is not a single class. BranchRequestOpen and BranchRequestDeepLink are siblings of
// BranchOpenRequest, not subclasses, so a BranchOpenRequest-only test reports no init in flight for
// every 4.0 session. Same enumeration as BNCServerRequestOperation -start.
- (BOOL)isInitRequest:(BNCServerRequest *)request {
    return [self isInstallOrOpenRequest:request] ||
           [request isKindOfClass:[BranchRequestDeepLink class]];
}

// YES for an install or open request.
- (BOOL)isInstallOrOpenRequest:(BNCServerRequest *)request {
    return [request isKindOfClass:[BranchOpenRequest class]] ||
           [request isKindOfClass:[BranchRequestOpen class]];
}

// -isInitRequest: over operations neither finished nor cancelled.
- (BOOL)hasUnfinishedInitRequest {
    for (NSOperation *op in self.operationQueue.operations) {
        if (![op isKindOfClass:[BNCServerRequestOperation class]]) continue;
        if (op.isFinished || op.isCancelled) continue;
        if ([self isInitRequest:((BNCServerRequestOperation *)op).request]) return YES;
    }
    return NO;
}

// Adds a check that runs after every live nil-URL resolve. NO when an install or open is live, or no such resolve is. Main thread only.
- (BOOL)addDeferredForegroundOpenCheck:(dispatch_block_t)block {
    NSAssert([NSThread isMainThread], @"The foreground open check must be added on the main thread.");
    NSMutableArray<NSOperation *> *liveResolves = [NSMutableArray array];

    for (NSOperation *op in self.operationQueue.operations) {
        if (![op isKindOfClass:[BNCServerRequestOperation class]]) continue;
        if (op.isFinished || op.isCancelled) continue;

        BNCServerRequest *request = ((BNCServerRequestOperation *)op).request;
        if ([self isInstallOrOpenRequest:request]) {
            return NO;
        }
        if ([request isKindOfClass:[BranchRequestDeepLink class]] &&
            ((BranchRequestDeepLink *)request).urlString.length == 0) {
            [liveResolves addObject:op];
        }
    }

    if (liveResolves.count == 0) return NO;

    BNCForegroundOpenCheckOperation *check = [BNCForegroundOpenCheckOperation new];
    check.block = block;
    for (NSOperation *resolve in liveResolves) {
        [check addDependency:resolve];
    }
    [self.operationQueue addOperation:check];

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Deferred the foreground open behind %lu resolve(s).", (unsigned long)liveResolves.count] error:nil];
    return YES;
}

- (void)cancelDeferredForegroundOpenChecks {
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCForegroundOpenCheckOperation class]]) {
            [op cancel];
        }
    }
}

- (void)addInitDependencyIfNeeded:(BNCServerRequestOperation *)operation {
    if ([self isInitRequest:operation.request]) {
        // This is an init/open request — track it as the current init operation
        self.currentInitOperation = operation;
    } else {
        // Non-init requests depend on the current init operation (if one is active)
        BNCServerRequestOperation *initOp = self.currentInitOperation;
        if (initOp && !initOp.isFinished && !initOp.isCancelled) {
            [operation addDependency:initOp];
        }
    }
}

- (void)clearQueue {
    [[BranchLogger shared] logDebug:@"Clearing all pending operations from the queue." error:nil];
    [self.operationQueue cancelAllOperations];
}

- (void)cancelPendingDeepLinkRequests {
    // Before the resolves, so cancelling them cannot release a check.
    [self cancelDeferredForegroundOpenChecks];

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
            if ([self isInitRequest:requestOp.request]) {
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

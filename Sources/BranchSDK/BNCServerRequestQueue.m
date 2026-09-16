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

// A foreground open that cannot be decided when the foreground happens. Whether a live resolve
// chains its own open is known only when that resolve completes, so this operation waits on the
// resolve as a dependency and runs the block afterwards. It stores nothing and leaves the queue
// either by running or by being cancelled.
@interface BNCDeferredForegroundOpenOperation : NSOperation
@property (copy, nonatomic) dispatch_block_t block;
@end

@implementation BNCDeferredForegroundOpenOperation

- (void)main {
    if (self.isCancelled) return;
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

    // This request owns the foreground's open now, so a deferred check still waiting on a resolve
    // would send a second one.
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
    return [request isKindOfClass:[BranchOpenRequest class]] ||
           [request isKindOfClass:[BranchRequestOpen class]] ||
           [request isKindOfClass:[BranchRequestDeepLink class]];
}

// The init requests that are themselves an open, which is -isInitRequest: without the resolve.
- (BOOL)isInstallOrOpenRequest:(BNCServerRequest *)request {
    return [request isKindOfClass:[BranchOpenRequest class]] ||
           [request isKindOfClass:[BranchRequestOpen class]];
}

// YES when an init request is still live. Same enumeration as -isInitRequest:, but skipping
// finished and cancelled operations, because NSOperationQueue does not guarantee that a finished
// dependency has left -operations by the time its dependent runs.
- (BOOL)hasUnfinishedInitRequest {
    for (NSOperation *op in self.operationQueue.operations) {
        if (![op isKindOfClass:[BNCServerRequestOperation class]]) continue;
        if (op.isFinished || op.isCancelled) continue;
        if ([self isInitRequest:((BNCServerRequestOperation *)op).request]) return YES;
    }
    return NO;
}

// Adds a check that runs `block` once every live resolve carrying no URL has finished, and
// returns YES when it did. Returns NO, adding nothing, when an install or open is already live,
// since that request owns the foreground's open, or when no such resolve is live, since then
// there is nothing to wait for. Call on the main thread, where the chained open is also enqueued,
// so the read and the add cannot interleave with it.
- (BOOL)addDeferredForegroundOpenCheck:(dispatch_block_t)block {
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

    BNCDeferredForegroundOpenOperation *check = [BNCDeferredForegroundOpenOperation new];
    check.block = block;
    check.queuePriority = NSOperationQueuePriorityNormal;
    for (NSOperation *resolve in liveResolves) {
        [check addDependency:resolve];
    }
    [self.operationQueue addOperation:check];

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Deferred the foreground open behind %lu resolve(s).", (unsigned long)liveResolves.count] error:nil];
    return YES;
}

- (void)cancelDeferredForegroundOpenChecks {
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCDeferredForegroundOpenOperation class]]) {
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
    // Cancelled first, so that cancelling the resolves below cannot release a check into a queue
    // whose replacing resolve has not been enqueued yet.
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

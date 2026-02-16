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
#import "BranchEvent.h"
#import "BranchLogger.h"
#import "Private/BNCServerRequestOperation.h"
#import "Branch.h"



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
    operation.requestQueue = self;

    [self addInitDependencyIfNeeded:operation];
    [self.operationQueue addOperation:operation];

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Enqueued request: %@. Current queue depth: %lu", request.requestUUID, (unsigned long)self.operationQueue.operationCount] error:nil];
}

- (NSInteger)queueDepth {
    return (NSInteger) self.operationQueue.operationCount;
}

- (void)enqueueRetry:(BNCServerRequest *)request withRetryCount:(NSInteger)retryCount {
    if (!request) return;

    BNCServerRequestOperation *operation = [[BNCServerRequestOperation alloc] initWithRequest:request];
    operation.serverInterface = self.serverInterface;
    operation.branchKey = self.branchKey;
    operation.preferenceHelper = self.preferenceHelper;
    operation.retryCount = retryCount;
    operation.requestQueue = self;

    [self addInitDependencyIfNeeded:operation];
    [self.operationQueue addOperation:operation];

    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Enqueued retry %ld for request: %@", (long)retryCount, request.requestUUID] error:nil];
}

- (void)addInitDependencyIfNeeded:(BNCServerRequestOperation *)operation {
    if ([operation.request isKindOfClass:[BranchOpenRequest class]]) {
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

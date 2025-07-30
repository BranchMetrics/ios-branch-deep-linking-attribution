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
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchLogger.h"
#import "BNCPreferenceHelper.h"
#import "Branch.h"



@interface BNCServerRequestQueue ()
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) BNCServerInterface *serverInterface;
@property (copy, nonatomic) NSString *branchKey;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;

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

- (void)enqueue:(BNCServerRequest *)request withPriority:(NSOperationQueuePriority)priority{
    if (!request) {
        [[BranchLogger shared] logError:@"Attempted to enqueue nil request." error:nil];
        return;
    }
    
    // Create an operation for the request
    BNCServerRequestOperation *operation = [[BNCServerRequestOperation alloc] initWithRequest:request];
    
    // Inject the necessary dependencies into the operation
    operation.serverInterface = self.serverInterface;
    operation.branchKey = self.branchKey;
    operation.preferenceHelper = self.preferenceHelper;
    operation.queuePriority = priority;

    // Add the operation to the queue. It will begin executing automatically when its turn comes.
    [self.operationQueue addOperation:operation];

    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Enqueued request: %@. Current queue depth: %lu", request.requestUUID, (unsigned long)self.operationQueue.operationCount] error:nil];
}

/*
- (BNCServerRequest *)peek {
    @synchronized (self) {
        return [self peekAt:0];
    }
}

- (BNCServerRequest *)peekAt:(NSUInteger)index {
    @synchronized (self) {
        if (index >= self.queue.count) {
            [[BranchLogger shared] logError:@"Invalid queue operation: index out of bound!" error:nil];
            return nil;
        }
        BNCServerRequest *request = nil;
       //ND request = [self.queue objectAtIndex:index];
        return request;
    }
}
 */
- (NSInteger)queueDepth {
    // The NSOperationQueue's `operationCount` directly reflects the depth
    return (NSInteger) self.operationQueue.operationCount;
}
 

- (void)clearQueue {
    [[BranchLogger shared] logDebug:@"Clearing all pending operations from the queue." error:nil];
    // `cancelAllOperations` attempts to cancel operations that are pending or currently executing.
    // For `isExecuting` operations, their `cancel` method will be called, but they must
    // handle cancellation internally (e.g., stopping network task and marking as finished).
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
            // BranchInstallRequest is a subclass of BranchOpenRequest
            if ([request isKindOfClass:[BranchOpenRequest class]]) {
                // Your original code had `!((BranchOpenRequest *)request).isFromArchivedQueue`
                // Ensure `isFromArchivedQueue` is a property on `BranchOpenRequest`.
                BranchOpenRequest *openRequest = (BranchOpenRequest *)request;
                if (!openRequest.isFromArchivedQueue) { // Apply original condition
                    return openRequest;
                }
            }
        }
    }
    return nil;
}

- (NSString *)description {
    // Provides a description of the operations currently in the queue
    NSMutableArray<NSString *> *requestUUIDs = [NSMutableArray array];
    for (NSOperation *op in self.operationQueue.operations) {
        if ([op isKindOfClass:[BNCServerRequestOperation class]]) {
            // Check if the operation is finished before accessing its request, just to be safe.
            // Or only include non-finished operations.
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

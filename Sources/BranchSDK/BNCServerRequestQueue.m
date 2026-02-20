//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"

// Analytics requests
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"
#import "BranchEvent.h"

#import "BranchLogger.h"

@interface BNCServerRequestQueue()
@property (strong, nonatomic) NSMutableArray<BNCServerRequest *> *queue;
@end


@implementation BNCServerRequestQueue

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    self.queue = [NSMutableArray<BNCServerRequest *> new];
    return self;
}

- (void)enqueue:(BNCServerRequest *)request {
    @synchronized (self) {
        if (request) {
            [self.queue addObject:request];
        }
    }
}

- (void)insert:(BNCServerRequest *)request at:(NSUInteger)index {
    @synchronized (self) {
        if (index > self.queue.count) {
            [[BranchLogger shared] logError:@"Invalid queue operation: index out of bound!" error:nil];
            return;
        }
        if (request) {
            [self.queue insertObject:request atIndex:index];
        }
    }
}

- (BNCServerRequest *)dequeue {
    @synchronized (self) {
        BNCServerRequest *request = nil;
        if (self.queue.count > 0) {
            request = [self.queue objectAtIndex:0];
            [self.queue removeObjectAtIndex:0];
        }
        return request;
    }
}

- (BNCServerRequest *)removeAt:(NSUInteger)index {
    @synchronized (self) {
        BNCServerRequest *request = nil;
        if (index >= self.queue.count) {
            [[BranchLogger shared] logError:@"Invalid queue operation: index out of bound!" error:nil];
            return nil;
        }
        request = [self.queue objectAtIndex:index];
        [self.queue removeObjectAtIndex:index];
        return request;
    }
}

- (void)remove:(BNCServerRequest *)request {
    @synchronized (self) {
        [self.queue removeObject:request];
    }
}

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
        request = [self.queue objectAtIndex:index];
        return request;
    }
}

- (NSInteger)queueDepth {
    @synchronized (self) {
        return (NSInteger) self.queue.count;
    }
}

- (NSString *)description {
    @synchronized(self) {
        return [self.queue description];
    }
}

- (void)clearQueue {
    @synchronized (self) {
        [self.queue removeAllObjects];
    }
}

- (BOOL)containsInstallOrOpen {
    @synchronized (self) {
        for (NSUInteger i = 0; i < self.queue.count; i++) {
            BNCServerRequest *req = [self.queue objectAtIndex:i];
            // Install extends open, so only need to check open.
            if ([req isKindOfClass:[BranchOpenRequest class]]) {
                return YES;
            }
        }
        return NO;
    }
}

- (BranchOpenRequest *)findExistingInstallOrOpen {
    @synchronized (self) {
        for (NSUInteger i = 0; i < self.queue.count; i++) {
            BNCServerRequest *request = [self.queue objectAtIndex:i];

            // Install subclasses open, so only need to check open
            // Request should not be the one added from archived queue
            if ([request isKindOfClass:[BranchOpenRequest class]] && !((BranchOpenRequest *)request).isFromArchivedQueue) {
                return (BranchOpenRequest *)request;
            }
        }
        return nil;
    }
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

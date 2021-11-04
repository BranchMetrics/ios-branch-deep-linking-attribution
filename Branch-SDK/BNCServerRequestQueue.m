//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"
#import "BranchCloseRequest.h"

// Analytics requests
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"
#import "BranchEvent.h"
#import "BNCCommerceEvent.h"
#import "BranchUserCompletedActionRequest.h"
#import "BranchSetIdentityRequest.h"
#import "BranchLogoutRequest.h"

#import "BNCLog.h"


static NSString * const BRANCH_QUEUE_FILE = @"BNCServerRequestQueue";
static NSTimeInterval const BATCH_WRITE_TIMEOUT = 3.0;


static inline uint64_t BNCNanoSecondsFromTimeInterval(NSTimeInterval interval) {
    return interval * ((NSTimeInterval) NSEC_PER_SEC);
}


@interface BNCServerRequestQueue()
@property (strong, nonatomic) NSMutableArray<BNCServerRequest *> *queue;
@property (strong, nonatomic) dispatch_queue_t asyncQueue;
@property (strong, nonatomic) dispatch_source_t persistTimer;
@end


@implementation BNCServerRequestQueue

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    self.queue = [NSMutableArray<BNCServerRequest *> new];
    self.asyncQueue = dispatch_queue_create("io.branch.persist_queue", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)dealloc {
    @synchronized (self) {
        if (self.persistTimer) {
            dispatch_source_cancel(self.persistTimer);
            self.persistTimer = nil;
        }
        [self persistImmediately];
        self.queue = nil;
    }
}

- (void)enqueue:(BNCServerRequest *)request {
    @synchronized (self) {
        if (request) {
            [self.queue addObject:request];
            [self persistEventually];
        }
    }
}

- (void)insert:(BNCServerRequest *)request at:(NSUInteger)index {
    @synchronized (self) {
        if (index > self.queue.count) {
            BNCLogError(@"Invalid queue operation: index out of bound!");
            return;
        }
        if (request) {
            [self.queue insertObject:request atIndex:index];
            [self persistEventually];
        }
    }
}

- (BNCServerRequest *)dequeue {
    @synchronized (self) {
        BNCServerRequest *request = nil;
        if (self.queue.count > 0) {
            request = [self.queue objectAtIndex:0];
            [self.queue removeObjectAtIndex:0];
            [self persistEventually];
        }
        return request;
    }
}

- (BNCServerRequest *)removeAt:(NSUInteger)index {
    @synchronized (self) {
        BNCServerRequest *request = nil;
        if (index >= self.queue.count) {
            BNCLogError(@"Invalid queue operation: index out of bound!");
            return nil;
        }
        request = [self.queue objectAtIndex:index];
        [self.queue removeObjectAtIndex:index];
        [self persistEventually];
        return request;
    }
}

- (void)remove:(BNCServerRequest *)request {
    @synchronized (self) {
        [self.queue removeObject:request];
        [self persistEventually];
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
            BNCLogError(@"Invalid queue operation: index out of bound!");
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
        [self persistImmediately];
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

- (BOOL)removeInstallOrOpen {
    @synchronized (self) {
        for (NSUInteger i = 0; i < self.queue.count; i++) {
            BNCServerRequest *request = [self.queue objectAtIndex:i];
            // Install extends open, so only need to check open.
            if ([request isKindOfClass:[BranchOpenRequest class]]) {
                BNCLogDebugSDK(@"Removing open request.");
                ((BranchOpenRequest *)request).callback = nil;
                [self remove:request];
                return YES;
            }
        }
        return NO;
    }
}

- (BranchOpenRequest *)moveInstallOrOpenToFront:(NSInteger)networkCount {
    @synchronized (self) {

        BOOL requestAlreadyInProgress = networkCount > 0;

        BNCServerRequest *openOrInstallRequest;
        for (NSUInteger i = 0; i < self.queue.count; i++) {
            BNCServerRequest *req = [self.queue objectAtIndex:i];
            if ([req isKindOfClass:[BranchOpenRequest class]]) {
                
                // Already in front, nothing to do
                if (i == 0 || (i == 1 && requestAlreadyInProgress)) {
                    return (BranchOpenRequest *)req;
                }

                // Otherwise, pull this request out and stop early
                openOrInstallRequest = [self removeAt:i];
                break;
            }
        }
        
        if (!openOrInstallRequest) {
            BNCLogError(@"No install or open request in queue while trying to move it to the front.");
            return nil;
        }
        
        if (!requestAlreadyInProgress || !self.queue.count) {
            [self insert:openOrInstallRequest at:0];
        }
        else {
            [self insert:openOrInstallRequest at:1];
        }
        
        return (BranchOpenRequest *)openOrInstallRequest;
    }
}

- (BOOL)containsClose {
    @synchronized (self) {
        for (NSUInteger i = 0; i < self.queue.count; i++) {
            BNCServerRequest *req = [self.queue objectAtIndex:i];
            if ([req isKindOfClass:[BranchCloseRequest class]]) {
                return YES;
            }
        }
        return NO;
    }
}

#pragma mark - Private Methods

- (void)persistEventually {
    @synchronized (self) {
        if (self.persistTimer) return;

        self.persistTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.asyncQueue);
        if (!self.persistTimer) return;

        dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, BNCNanoSecondsFromTimeInterval(BATCH_WRITE_TIMEOUT));
        dispatch_source_set_timer(
            self.persistTimer,
            startTime,
            BNCNanoSecondsFromTimeInterval(BATCH_WRITE_TIMEOUT),
            BNCNanoSecondsFromTimeInterval(BATCH_WRITE_TIMEOUT / 10.0)
        );
        __weak __typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.persistTimer, ^ {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf cancelTimer];
                [strongSelf persistImmediately];
            }
        });
        dispatch_resume(self.persistTimer);
    }
}

- (void)cancelTimer {
    @synchronized (self) {
        if (self.persistTimer) {
            dispatch_source_cancel(self.persistTimer);
            self.persistTimer = nil;
        }
    }
}

- (void)persistImmediately {
    @synchronized (self) {
        if (!self.queue || self.queue.count == 0) {
            return;
        }
        NSArray *queueCopy = [self.queue copy];
        
        // encode the list of encoded request objects
        NSData *data = [self archiveQueue:queueCopy];
        if (data) {
            NSError *error = nil;
            [data writeToURL:self.class.URLForQueueFile options:NSDataWritingAtomic error:&error];
            
            if (error) {
                BNCLogError([NSString stringWithFormat:@"Failed to persist queue to disk: %@.", error]);
            }
        } else {
            BNCLogError([NSString stringWithFormat:@"Failed to encode queue."]);
        }
    }
}

// assumes queue no longer mutable
- (NSData *)archiveQueue:(NSArray<BNCServerRequest *> *)queue {
    NSMutableArray<BNCServerRequest *> *archivedRequests = [NSMutableArray<BNCServerRequest *> new];
    NSSet<Class> *requestClasses = [BNCServerRequestQueue replayableRequestClasses];
    for (BNCServerRequest *request in queue) {
        
        // only persist analytics requests, skip the rest
        if ([requestClasses containsObject:request.class]) {
            [archivedRequests addObject:request];
        }
    }
    return [self archiveObject:archivedRequests];
}

// For testing backwards compatibility
// The old version did a double archive and didn't filter replayable requests
- (NSData *)oldArchiveQueue:(NSArray<BNCServerRequest *> *)queue {
    NSMutableArray<NSData *> *archivedRequests = [NSMutableArray<NSData *> new];
    for (BNCServerRequest *request in queue) {
        
        // only close requests were ignored
        if (![BranchCloseRequest.class isEqual:request.class]) {
            
            // archive every request
            NSData *encodedRequest = [self archiveObject:request];
            [archivedRequests addObject:encodedRequest];
        }
    }
    return [self archiveObject:archivedRequests];
}

- (NSData *)archiveObject:(NSObject *)object {
    NSData *data = nil;
    NSError *error = nil;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:&error];
        
        if (!data && error) {
            BNCLogWarning([NSString stringWithFormat:@"Failed to archive: %@", error]);
        }
        
    } else {
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
        #endif
    }
    return data;
}

// Loads saved requests from disk. Only called on app start.
- (void)retrieve {
    @synchronized (self) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:self.class.URLForQueueFile options:0 error:&error];
        if (!error && data) {
            NSMutableArray *decodedQueue = [self unarchiveQueueFromData:data];
            self.queue = decodedQueue;
        }
    }
}

- (NSMutableArray<BNCServerRequest *> *)unarchiveQueueFromData:(NSData *)data {
    NSMutableArray<BNCServerRequest *> *queue = [NSMutableArray new];
    
    NSArray *requestArray = nil;
    id tmp = [self unarchiveObjectFromData:data];
    if ([tmp isKindOfClass:[NSArray class]]) {
        requestArray = (NSArray *)tmp;
    }
    
    // validate request array
    // There should never be an object that is not a replayable class or NSData
    for (id request in requestArray) {
        id tmpRequest = request;
        
        // handle legacy NSData
        if ([request isKindOfClass:[NSData class]]) {
            tmpRequest = [self unarchiveObjectFromData:request];
        }
          
        // make sure we didn't unarchive something unexpected
        if ([[BNCServerRequestQueue replayableRequestClasses] containsObject:[tmpRequest class]]) {
            [queue addObject:tmpRequest];
        }
    }

    return queue;
}

- (id)unarchiveObjectFromData:(NSData *)data {
    id object = nil;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        object = [NSKeyedUnarchiver unarchivedObjectOfClasses:[BNCServerRequestQueue encodableClasses] fromData:data error:nil];

    } else {
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        #endif
    }
    return object;
}

// only replay analytics requests, the others are time sensitive
+ (NSSet<Class> *)replayableRequestClasses {
    static NSSet<Class> *requestClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        NSArray *tmp = @[
            [BranchOpenRequest class],
            [BranchInstallRequest class],
            [BranchEventRequest class],
            [BranchCommerceEventRequest class],
            [BranchUserCompletedActionRequest class],
            [BranchSetIdentityRequest class],
            [BranchLogoutRequest class],
        ];
        requestClasses = [NSSet setWithArray:tmp];
    });
        
    return requestClasses;
}

// encodable classes also includes NSArray and NSData
+ (NSSet<Class> *)encodableClasses {
    static NSSet<Class> *classes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        NSMutableArray *tmp = [NSMutableArray new];
        [tmp addObject:[NSArray class]]; // root object
        [tmp addObject:[NSData class]]; // legacy format compatibility
        
        // add all replayable request objects
        [tmp addObjectsFromArray: [[BNCServerRequestQueue replayableRequestClasses] allObjects]];
        
        classes = [NSSet setWithArray:tmp];
    });
        
    return classes;
}

+ (NSURL * _Nonnull) URLForQueueFile {
    static NSURL *URL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        URL = BNCURLForBranchDirectory();
        URL = [URL URLByAppendingPathComponent:BRANCH_QUEUE_FILE isDirectory:NO];
    });
    return URL;
}

+ (instancetype)getInstance {
    static BNCServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        sharedQueue = [[BNCServerRequestQueue alloc] init];
        [sharedQueue retrieve];
        BNCLogDebugSDK([NSString stringWithFormat:@"Retrieved from storage: %@.", sharedQueue]);
    });
    return sharedQueue;
}

@end

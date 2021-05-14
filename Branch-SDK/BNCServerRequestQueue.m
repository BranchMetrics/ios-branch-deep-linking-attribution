//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"

// ignored requests
#import "BranchCloseRequest.h"

// all other requests
#import "BranchInstallRequest.h"
#import "BranchOpenRequest.h"

#import "BranchCPIDRequest.h"
#import "BranchLATDRequest.h"

#import "BranchSetIdentityRequest.h"
#import "BranchLogoutRequest.h"

#import "BranchShortUrlRequest.h"
#import "BranchShortUrlSyncRequest.h"

#import "BranchLoadRewardsRequest.h"
#import "BranchRedeemRewardsRequest.h"
#import "BranchCreditHistoryRequest.h"

#import "BranchUserCompletedActionRequest.h"

#import "BranchSpotlightUrlRequest.h"
#import "BranchRegisterViewRequest.h"

// includes Event Requests
#import "BranchEvent.h"
#import "BNCCommerceEvent.h"

#import "BNCLog.h"


static NSString * const BRANCH_QUEUE_FILE = @"BNCServerRequestQueue";
static NSTimeInterval const BATCH_WRITE_TIMEOUT = 3.0;


static inline uint64_t BNCNanoSecondsFromTimeInterval(NSTimeInterval interval) {
    return interval * ((NSTimeInterval) NSEC_PER_SEC);
}


@interface BNCServerRequestQueue()
@property (strong) NSMutableArray *queue;
@property (strong) dispatch_queue_t asyncQueue;
@property (strong) dispatch_source_t persistTimer;
@end


@implementation BNCServerRequestQueue

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    self.queue = [NSMutableArray array];
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
            BranchOpenRequest *req = [self.queue objectAtIndex:i];
            // Install extends open, so only need to check open.
            if ([req isKindOfClass:[BranchOpenRequest class]]) {
                BNCLogDebugSDK(@"Removing open request.");
                req.callback = nil;
                [self remove:req];
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
        if (!self.queue) {
            return;
        }
        
        NSArray *requestsToPersist = [self.queue copy];
        NSMutableArray *encodedRequests = [[NSMutableArray alloc] init];
        NSArray<Class> *requestClasses = [self replayableRequestClasses];
        
        for (BNCServerRequest *req in requestsToPersist) {

            if (![requestClasses containsObject:req.class]) {
                continue;
            }
            
            // encode each request object
            NSData *encodedReq = [self archiveObject:req];
            if (encodedReq) {
                [encodedRequests addObject:encodedReq];
            }
        }
        
        // encode the list of encoded request objects
        NSData *data = [self archiveObject:encodedRequests];
        if (!data) {
            BNCLogError(@"Cannot create archive data.");
            return;
        }
        NSError *error = nil;
        [data writeToURL:self.class.URLForQueueFile options:NSDataWritingAtomic error:&error];
        if (error) {
            BNCLogError([NSString stringWithFormat:@"Failed to persist queue to disk: %@.", error]);
        }
    }
}

- (BOOL)isDirty {
    @synchronized (self) {
        return (self.persistTimer != nil);
    }
}

- (void)retrieve {
    @synchronized (self) {
        NSMutableArray *queue = [[NSMutableArray alloc] init];
        NSArray *encodedRequests = nil;
        
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:self.class.URLForQueueFile options:0 error:&error];
        if (!error && data) {
            encodedRequests = [self decodeArrayFromData:data];
        }

        for (NSData *encodedRequest in encodedRequests) {
            BNCServerRequest *request = [self decodeRequestFromData:encodedRequest];
            if (request) {
                [queue addObject:request];
            }
        }
        self.queue = queue;
    }
}

- (NSData *)archiveObject:(NSObject *)object {
    NSData *data = nil;
    if (@available( iOS 12.0, *)) {
        data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:NULL];
    } else {
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
        data = [NSKeyedArchiver archivedDataWithRootObject:object];
        #endif
    }
    return data;
}

- (NSArray<Class> *)replayableRequestClasses {
    /*
     Elsewhere only these are considered replayable.
     I see no reason to save anything other than these and install.
     
     BranchEventRequest.class,
     BranchUserCompletedActionRequest.class,
     BranchSetIdentityRequest.class,
     BranchCommerceEventRequest.class,
     
     TODO: verify behavior with team.
     
     */
    NSArray<Class> *requestClasses = @[
        [BranchEventRequest class],
        [BranchCommerceEventRequest class],
        [BranchUserCompletedActionRequest class],
        [BranchSetIdentityRequest class],
        [BranchLogoutRequest class],
        [BranchInstallRequest class],

//        [BranchOpenRequest class],
//        [BranchShortUrlRequest class],
//        [BranchShortUrlSyncRequest class],
//        [BranchLoadRewardsRequest class],
//        [BranchRedeemRewardsRequest class],
//        [BranchCreditHistoryRequest class],
//        [BranchSpotlightUrlRequest class],
//        [BranchRegisterViewRequest class],
    ];
    
    return requestClasses;
}

- (BNCServerRequest *)decodeRequestFromData:(NSData *)data {
    NSArray<Class> *requestClasses = [self replayableRequestClasses];
    
    BNCServerRequest *request = nil;
    for (Class class in requestClasses) {
        request = [self decodeObjectFromData:data withClass:class];
        if (request && [request isKindOfClass:class]) {
            return (BNCServerRequest *)request;
        }
    }
    
    if (request) {
        NSLog(@"Unexpected Object found in queue: %@", request);
    }
    return nil;
}

- (NSArray *)decodeArrayFromData:(NSData *)data {
    id tmp = [self decodeObjectFromData:data withClass:[NSArray class]];
    if ([tmp isKindOfClass:[NSArray class]]) {
        return (NSArray *)tmp;
    }
    return nil;
}

- (id)decodeObjectFromData:(NSData *)data withClass:(Class)class {
    id object = nil;
    if (@available(iOS 12.0, *)) {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:class fromData:data error:NULL];
    } else {
        #if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
        object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedRequest];
        #endif
    }
    return object;
}

+ (NSString *)exceptionString:(NSException *)exception {
    return [NSString stringWithFormat:@"Name: %@\nReason: %@\nStack:\n\t%@\n\n",
        exception.name, exception.reason,
            [exception.callStackSymbols componentsJoinedByString:@"\n\t"]];
}

+ (NSURL * _Nonnull) URLForQueueFile {
    NSURL *URL = BNCURLForBranchDirectory();
    URL = [URL URLByAppendingPathComponent:BRANCH_QUEUE_FILE isDirectory:NO];
    return URL;
}

#pragma mark - Shared Method

+ (id)getInstance {
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

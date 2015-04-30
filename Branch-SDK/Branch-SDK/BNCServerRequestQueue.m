//
//  BNCServerRequestQueue.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 9/6/14.
//
//

#import "BNCServerRequestQueue.h"
#import "BranchServerInterface.h"
#import "BNCPreferenceHelper.h"

NSString * const STORAGE_KEY = @"BNCServerRequestQueue";
NSUInteger const BATCH_WRITE_TIMEOUT = 3;

@interface BNCServerRequestQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic) dispatch_queue_t asyncQueue;
@property (strong, nonatomic) NSTimer *writeTimer;

+ (NSMutableArray *)retrieve;

@end


@implementation BNCServerRequestQueue

- (id)init {
    if (self = [super init]) {
        self.queue = [NSMutableArray array];
        self.asyncQueue = dispatch_queue_create("brnch_persist_queue", NULL);
    }
    return self;
}

- (void)enqueue:(BNCServerRequest *)request {
    @synchronized(self.queue) {
        if (request) {
            [self.queue addObject:request];
            [self persistEventually];
        }
    }
}

- (void)insert:(BNCServerRequest *)request at:(unsigned int)index {
    @synchronized(self.queue) {
        if (index > self.queue.count) {
            [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Invalid queue operation: index out of bound!"];
            return;
        }
        
        if (request) {
            [self.queue insertObject:request atIndex:index];
            [self persistEventually];
        }
    }
}

- (BNCServerRequest *)dequeue {
    BNCServerRequest *request = nil;
    
    @synchronized(self.queue) {
        if (self.queue.count > 0) {
            request = [self.queue objectAtIndex:0];
            [self.queue removeObjectAtIndex:0];
            [self persistEventually];
        }
    }
    
    return request;
}

- (BNCServerRequest *)removeAt:(unsigned int)index {
    BNCServerRequest *request = nil;
    @synchronized(self.queue) {
        if (index >= self.queue.count) {
            [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Invalid queue operation: index out of bound!"];
            return nil;
        }
        
        request = [self.queue objectAtIndex:index];
        [self.queue removeObjectAtIndex:index];
        [self persistEventually];
    }
    
    return request;
}

- (void)remove:(BNCServerRequest *)request {
    [self.queue removeObject:request];
    [self persistEventually];
}

- (BNCServerRequest *)peek {
    return [self peekAt:0];
}

- (BNCServerRequest *)peekAt:(unsigned int)index {
    if (index >= self.queue.count) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Invalid queue operation: index out of bound!"];
        return nil;
    }
    
    BNCServerRequest *request = nil;
    request = [self.queue objectAtIndex:index];
    
    return request;
}

- (unsigned int)size {
    return (unsigned int)self.queue.count;
}

- (NSString *)description {
    return [self.queue description];
}

- (void)clearQueue {
    [self.queue removeAllObjects];
    [self persistEventually];
}

- (BOOL)containsInstallOrOpen {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if (req && ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) && req.callback) {
            return YES;
        }
    }
    return NO;
}

- (void)moveInstallOrOpen:(NSString *)tag ToFront:(NSInteger)networkCount {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [self removeAt:i];
            break;
        }
    }
    
    BNCServerRequest *req = [[BNCServerRequest alloc] initWithTag:tag];
    if (networkCount == 0) {
        [self insert:req at:0];
    } else {
        [self insert:req at:1];
    }
}

- (BOOL)containsClose {
    for (int i = 0; i < self.queue.count; i++) {
        BNCServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Private method

- (void)persistEventually {
    if (!self.writeTimer.valid) {
        self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:BATCH_WRITE_TIMEOUT target:self selector:@selector(persistToDisk) userInfo:nil repeats:NO];
    }
}

- (void)persistImmediately {
    [self.writeTimer invalidate];
    
    [self persistToDisk];
}

- (void)persistToDisk {
    dispatch_async(self.asyncQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        @synchronized(self.queue) {
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            for (BNCServerRequest *req in self.queue) {
                if (req) {
                    @try {
                        NSData *encodedReq = [NSKeyedArchiver archivedDataWithRootObject:req];
                        [arr addObject:encodedReq];
                    }
                    @catch (NSException* exception) {
                    }
                }
            }
            
            [defaults setObject:arr forKey:STORAGE_KEY];
        }
        [defaults synchronize];
    });
}

+ (NSMutableArray *)retrieve {
    NSMutableArray *queue = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id data = [defaults objectForKey:STORAGE_KEY];
    if (!data) {
        return queue;
    }
    
    NSArray *arr = (NSArray *)data;
    for (NSData *encodedRequest in arr) {
        if (encodedRequest) {
            @try {
                BNCServerRequest *request = [NSKeyedUnarchiver unarchiveObjectWithData:encodedRequest];
                if (![request.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
                    [queue addObject:request];
                }
            }
            @catch (NSException* exception) {
            }
        }
    }
    
    return queue;
}

#pragma mark - Singleton method

+ (id)getInstance {
    static BNCServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedQueue = [[BNCServerRequestQueue alloc] init];
        sharedQueue.queue = [BNCServerRequestQueue retrieve];
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Retrieved from Persist: %@", sharedQueue];
    });
    
    return sharedQueue;
}

@end

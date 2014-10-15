//
//  ServerRequestQueue.m
//  Experiment
//
//  Created by Qinwei Gong on 9/6/14.
//
//

#import "ServerRequestQueue.h"
#import "BranchServerInterface.h"
#import "Config.h"

#define STORAGE_KEY     @"BNCServerRequestQueue"


@interface ServerRequestQueue()

@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic) dispatch_queue_t asyncQueue;

- (void)persist;
+ (NSMutableArray *)retrieve;

@end


@implementation ServerRequestQueue

- (id)init {
    if (self = [super init]) {
        self.queue = [NSMutableArray array];
        self.asyncQueue = dispatch_queue_create("brnch_persist_queue", NULL);
    }
    return self;
}

- (void)enqueue:(ServerRequest *)request {
    if (request) {
        [self.queue addObject:request];
        [self persist];
    }
}

- (void)insert:(ServerRequest *)request at:(unsigned int)index {
    if (index > self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return;
    }
    
    if (request) {
        [self.queue insertObject:request atIndex:index];
        [self persist];
    }
}

- (ServerRequest *)dequeue {
    ServerRequest *request = nil;
    
    if (self.queue.count > 0) {
        request = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        [self persist];
    }
    
    return request;
}

- (ServerRequest *)removeAt:(unsigned int)index {
    if (index >= self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return nil;
    }
    
    ServerRequest *request = [self.queue objectAtIndex:index];
    [self.queue removeObjectAtIndex:index];
    [self persist];
    
    return request;
}


- (ServerRequest *)peek {
    return [self peekAt:0];
}

- (ServerRequest *)peekAt:(unsigned int)index {
    if (index >= self.queue.count) {
        Debug(@"Invalid queue operation: index out of bound!");
        return nil;
    }
    
    ServerRequest *request = nil;
    request = [self.queue objectAtIndex:index];
    
    return request;
}

- (unsigned int)size {
    return (unsigned int)self.queue.count;
}

- (NSString *)description {
    return [self.queue description];
}

- (BOOL)containsInstallOrOpen {
    for (int i = 0; i < self.queue.count; i++) {
        ServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            return YES;
        }
    }
    return NO;
}

- (void)moveInstallOrOpenToFront:(NSString *)tag {
    for (int i = 0; i < self.queue.count; i++) {
        ServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [self removeAt:i];
            break;
        }
    }
    
    ServerRequest *req = [[ServerRequest alloc] initWithTag:tag];
    [self insert:req at:0];
}

- (BOOL)containsClose {
    for (int i = 0; i < self.queue.count; i++) {
        ServerRequest *req = [self.queue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Private method

- (void)persist {
    dispatch_async(self.asyncQueue, ^{
        NSArray * copyQueue = [NSArray arrayWithArray:self.queue];
        NSMutableArray *arr = [NSMutableArray array];
        
        for (ServerRequest *req in copyQueue) {
            NSData *encodedReq = [NSKeyedArchiver archivedDataWithRootObject:req];
            [arr addObject:encodedReq];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:arr forKey:STORAGE_KEY];
        [defaults synchronize];
    });
}

+ (NSMutableArray *)retrieve {
    NSMutableArray *queue = [NSMutableArray array];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id data = [defaults objectForKey:STORAGE_KEY];
    if (!data) {
        return queue;
    }
    
    NSArray *arr = (NSArray *)data;
    for (NSData *encodedRequest in arr) {
        ServerRequest *request = [NSKeyedUnarchiver unarchiveObjectWithData:encodedRequest];
        [queue addObject:request];
    }
    
    return queue;
}

#pragma mark - Singleton method

+ (id)getInstance {
    static ServerRequestQueue *sharedQueue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedQueue = [[ServerRequestQueue alloc] init];
        sharedQueue.queue = [ServerRequestQueue retrieve];
        Debug(@"Retrieved from Persist: %@", sharedQueue);
    });
    
    return sharedQueue;
}

@end

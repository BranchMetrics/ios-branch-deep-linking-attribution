//
//  ServerRequestQueue.h
//  Experiment
//
//  Created by Qinwei Gong on 9/6/14.
//
//

#import "ServerRequest.h"

@interface ServerRequestQueue : NSObject

@property (nonatomic, readonly) unsigned int size;

- (void)enqueue:(ServerRequest *)request;
- (ServerRequest *)dequeue;
- (ServerRequest *)peek;
- (ServerRequest *)peekAt:(unsigned int)index;
- (void)insert:(ServerRequest *)request at:(unsigned int)index;
- (ServerRequest *)removeAt:(unsigned int)index;
- (void)persist;

- (BOOL)containsInstallOrOpen;
- (BOOL)containsClose;
- (void)moveInstallOrOpenToFront:(NSString *)tag;

+ (id)getInstance;

@end

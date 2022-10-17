//
//  NSURLSession+Branch.m
//  BranchSearchDemo
//
//  Created by Ernest Cho on 8/19/20.
//  Copyright © 2020 Branch Metrics, Inc. All rights reserved.
//

#import "NSURLSession+Branch.h"
#import <objc/runtime.h>

@implementation NSURLSession (Branch)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSelector:@selector(dataTaskWithRequest:completionHandler:)
                 withSelector:@selector(xxx_dataTaskWithRequest:completionHandler:)];
    });
}

// swaps originalSelector with swizzledSelector
+ (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)logNetworkTrafficRequest:(NSURLRequest *)request data:(NSData *)data response:(NSURLResponse *)response {
    NSLog(@"NSURLSessionDataTask Request: %@", request);
    
    NSData *body = [request HTTPBody];
    if (body) {
        NSLog(@"NSURLSessionDataTask Request Body: %@", [NSString stringWithUTF8String:body.bytes]);
    }
    
    NSLog(@"NSURLSessionDataTask Response: %@", response);

    if (data.bytes) {
        NSLog(@"NSURLSessionDataTask Response Data: %@", [NSString stringWithUTF8String:data.bytes]);
    }
}

// replacement method for dataTaskWithRequest
- (NSURLSessionDataTask *)xxx_dataTaskWithRequest:(NSURLRequest *)request
                                completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    // create a new block that just calls the original block after logging the request
    void (^completionHandlerWithLogging)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            
            [self logNetworkTrafficRequest:request data:data response:response];
            
            completionHandler(data, response, error);
        }
    };
    
    return [self xxx_dataTaskWithRequest:request completionHandler:completionHandlerWithLogging];
}

@end

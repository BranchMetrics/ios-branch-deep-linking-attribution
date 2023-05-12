//
//  NSURLSession+Branch.m
//
//  Created by Ernest Cho on 10/11/18.
//  Copyright © 2018 Branch Metrics, Inc. All rights reserved.
//

#import "NSURLSessionBranch.h"
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
    NSLog(@"BranchSDK API LOG START OF FILE");
    NSLog(@"[LogEntryStart]\n\n");
    NSLog(@"---------------------------------------------------------------------BranchSDK LOG START ---------------------------------------------------------------------" );
    NSLog(@"[LogEntryStart]\n\n");
    NSLog(@"BranchSDK Request log: %@", request);
    
    NSData *body = [request HTTPBody];
    if (body) {
        NSLog(@"[LogEntryStart]\n\n");
        NSLog(@"BranchSDK Request Body: %@", [NSString stringWithUTF8String:body.bytes]);
    }
    
    NSLog(@"[LogEntryStart]\n\n");
    NSLog(@"BranchSDK  Response: %@", response);

    if (data.bytes) {
        NSLog(@"\n\n");
        NSLog(@"BranchSDK Response Data: %@", [NSString stringWithUTF8String:data.bytes]);
    }
    NSLog(@"[LogEntryStart]\n\n");
    NSLog(@"---------------------------------------------------------------------BranchSDK LOG END ---------------------------------------------------------------------" );
    NSLog(@"[LogEntryStart]\n\n");
    NSLog(@"BranchSDK API LOG END OF FILE");
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

- (NSData *)dataFromJSONFileNamed:(NSString *)fileName {
    // If this class is part of the Test target, [self class] returns the Test Bundle
    // NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    NSString *jsonString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)dictionaryFromJSONFileNamed:(NSString *)fileName {
    NSData *jsonData = [self dataFromJSONFileNamed:fileName];
    id dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if ([dict isKindOfClass:NSDictionary.class]) {
        return dict;
    }
    return nil;
}

@end

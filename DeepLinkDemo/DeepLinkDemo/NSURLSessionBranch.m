//
//  NSURLSession+Branch.m
//
//  Created by Ernest Cho on 10/11/18.
//  Copyright © 2018 Branch Metrics, Inc. All rights reserved.
//

#import "NSURLSessionBranch.h"
#import <objc/runtime.h>
#import "BranchLogger.h"

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
    [[BranchLogger shared] logDebug: @"BranchSDK API LOG START OF FILE" error:nil];
   
    [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
     [[BranchLogger shared] logDebug:(@"---------------------------------------------------------------------BranchSDK LOG START ---------------------------------------------------------------------" ) error:nil];
      [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
       [[BranchLogger shared] logDebug:([NSString stringWithFormat: @"BranchSDK Request log: %@", request]) error:nil];
    
    NSData *body = [request HTTPBody];
    if (body) {
        [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"BranchSDK Request Body: %@", [NSString stringWithUTF8String:body.bytes]] error:nil];
    }
    
        [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
    [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"BranchSDK  Response: %@", response] error:nil];

    if (data.bytes) {
        [[BranchLogger shared] logDebug:(@"\n\n") error:nil];
        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"BranchSDK Response Data: %@", [NSString stringWithUTF8String:data.bytes]] error:nil];
    }
          [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
           [[BranchLogger shared] logDebug:(@"---------------------------------------------------------------------BranchSDK LOG END ---------------------------------------------------------------------" ) error:nil];
            [[BranchLogger shared] logDebug:(@"[LogEntryStart]\n\n") error:nil];
             [[BranchLogger shared] logDebug:(@"BranchSDK API LOG END OF FILE") error:nil];
   
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

//
//  BNCUserAgentCollector.m
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCUserAgentCollector.h"
@import WebKit;

@interface BNCUserAgentCollector()
@property (nonatomic, strong, readwrite) WKWebView *webview;
@end

@implementation BNCUserAgentCollector

- (void)collectUserAgentWithCompletion:(void (^)(NSString *useragent))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.webview) {
            self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
        }
        
        [self.webview evaluateJavaScript:@"navigator.userAgent;" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            if (completion) {
                completion(response);
            }
        }];
    });
}

@end

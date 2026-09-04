//
//  BNCUserAgentCollector.m
//  Branch
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#if !TARGET_OS_TV
#import "BNCUserAgentCollector.h"
#import "BNCPreferenceHelper.h"
#import "BNCDeviceSystem.h"
#if __has_feature(modules)
@import WebKit;
#else
#import <WebKit/WebKit.h>
#endif

static const NSInteger BNCUserAgentCollectorMaxRetryCount = 5;
static const NSTimeInterval BNCUserAgentCollectorRetryDelay = 0.5;

@interface BNCUserAgentCollector()
// need to hold onto the webview until the async user agent fetch is done
@property (nonatomic, strong, readwrite) WKWebView *webview;

// use system build as an indicator that the OS has been updated
@property (nonatomic, copy, readwrite) NSString *systemBuildVersion;
@end

@implementation BNCUserAgentCollector

+ (BNCUserAgentCollector *)instance {
    static BNCUserAgentCollector *collector = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        collector = [BNCUserAgentCollector new];
    });
    return collector;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.systemBuildVersion = [BNCDeviceSystem new].systemBuildVersion;
    }
    return self;
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    NSString *savedUserAgent = [self loadUserAgentForSystemBuildVersion:self.systemBuildVersion];
    if (savedUserAgent) {
        self.userAgent = savedUserAgent;
        if (completion) {
            completion(savedUserAgent);
        }
    } else {
        [self collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            self.userAgent = userAgent;
            [self saveUserAgent:userAgent forSystemBuildVersion:self.systemBuildVersion];
            if (completion) {
                completion(userAgent);
            }
        }];
    }
}

// load user agent from preferences
- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion {
    
    NSString *userAgent = nil;
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper sharedInstance];
    NSString *savedUserAgent = [preferences.browserUserAgentString copy];
    NSString *savedSystemBuildVersion = [preferences.lastSystemBuildVersion copy];
    
    if (savedUserAgent && [systemBuildVersion isEqualToString:savedSystemBuildVersion]) {
        userAgent = savedUserAgent;
    }
    
    return userAgent;
}

// save user agent to preferences
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion {
    if (userAgent && systemBuildVersion) {
        BNCPreferenceHelper *preferences = [BNCPreferenceHelper sharedInstance];
        preferences.browserUserAgentString = userAgent;
        preferences.lastSystemBuildVersion = systemBuildVersion;
    }
}

// collect user agent from webkit.  this is expensive.
- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion {
    [self collectUserAgentWithCompletion:completion retryCount:0];
}

// A WKWebView whose web content process never came up does not recover, so each retry
// releases the webview and evaluates against a fresh one. Retries are bounded and spaced;
// retrying the same webview immediately spins the main queue for as long as the caller waits.
- (void)collectUserAgentWithCompletion:(void (^)(NSString *userAgent))completion retryCount:(NSInteger)retryCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.webview) {
            self.webview = [[WKWebView alloc] initWithFrame:CGRectZero];
        }

        [self.webview evaluateJavaScript:@"navigator.userAgent;" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            if (!completion) {
                return;
            }

            // release the webview
            self.webview = nil;

            if (response) {
                completion(response);
                return;
            }

            // retry if we failed to obtain user agent.  This occasionally occurs on simulator.
            if (retryCount >= BNCUserAgentCollectorMaxRetryCount) {
                completion(nil);
                return;
            }

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(BNCUserAgentCollectorRetryDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self collectUserAgentWithCompletion:completion retryCount:retryCount + 1];
            });
        }];
    });
}

@end
#endif

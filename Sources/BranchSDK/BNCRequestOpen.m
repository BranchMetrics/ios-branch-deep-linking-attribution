//
//  BNCRequestOpen.m
//  Branch-SDK
//
//  Created by Brandon Boothe on 4/30/26.
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#import "BranchLogger.h"

@implementation BNCRequestOpen
- (instancetype)init:(Context *)context callback:(id<BranchReferralInitListener>)callback isAutoInitialization:(BOOL)isAutoInitialization {
    self = [super init:context path:DefinesRequestPathRegisterOpen isAutoInitialization:isAutoInitialization];

    if (self) {
        _callback = callback;

        @try {
            NSMutableDictionary *openPost = [[NSMutableDictionary alloc] init];

            NSString *deviceToken = self.prefHelper.randomizedDeviceToken;
            NSString *bundleToken = self.prefHelper.randomizedBundleToken;

            if (deviceToken) {
                openPost[DefinesJsonkeyRandomizedDeviceTokenKey] = deviceToken;
            }
            if (bundleToken) {
                openPost[DefinesJsonKeyRandomizedBundleTokenKey] = bundleToken;
            }

            [self setPost:openPost];
        } @catch (NSException *exception) {
            NSLog(@"[BranchLogger] Caught Exception %@", exception.reason);
            _constructError = YES;
        }
    }

    return self;
}

- (NSString *)getRequestUrl {
    return @"https://api-open.stage.branch.io/v3/events/open";
}

- (void)onRequestSucceeded:(NSDictionary *)response otherValue:(NSString *)otherValue {

}

- (void)handleFailure:(NSInteger)statusCode causeMsg:(NSString *)causeMsg {

}

- (NSString *)getRequestActionName {
    return "ACTION_OPEN";
}

- (BOOL)isGetRequest {
    return NO;
}

- (void)clearCallbacks {
    callback = NULL;
}

- (BOOL)shouldRetryOnFail {
    return NO;
}

- (BOOL)handleErrors:(Context)context {
    return !doesAppHasInternetPermission(context);
}

@end
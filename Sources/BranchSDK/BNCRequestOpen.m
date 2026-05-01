//
//  BNCRequestOpen.m
//  Branch-SDK
//
//  Created by Brandon Boothe on 4/30/26.
//  Copyright © 2026 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BranchLogger.h"

@implementation BNCRequestOpen
- (instancetype)init:(Context *)context callback:(id<BranchReferralInitListener>)callback isAutoInitialization:(BOOL)isAutoInitialization {
    self = [super init:context path:DefinesRequestPathRegisterOpen isAutoInitialization:isAutoInitialization];

    if (self) {
        _callback = callback;

        @try {
            NSMutableDictionary *openPost = [[NSMutableDictionary alloc] init];

            NSString *deviceToken = self.preferenceHelper.randomizedDeviceToken;
            NSString *bundleToken = self.preferenceHelper.randomizedBundleToken;

            if (deviceToken) {
                openPost[DefinesJsonkeyRandomizedDeviceTokenKey] = deviceToken;
            }
            if (bundleToken) {
                openPost[DefinesJsonKeyRandomizedBundleTokenKey] = bundleToken;
            }

            [self setPost:openPost];
        } @catch (NSException *exception) {
            [[BranchLogger shared] logError:@"BNCRequestOpen Caught Exception %@", exception.reason error:nil];
            _constructError = YES;
        }
    }

    return self;
}

- (NSString *)getRequestUrl {
    return @"https://api-open.stage.branch.io/v3/events/open";
}

- (void)onRequestSucceeded:(ServerResponse *)response branch:(Branch *)branch {
    [super onRequestSucceeded:response branch:branch];
    
    [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"BNCRequestOpen Succeeded. Response: %@", response.object]];

    @try {
        NSDictionary *responseJson = (NSDictionary *)response.object;
        
        if (responseJson[DefinesJsonLinkClickIDKey]) {
            self.prefHelper.linkClickID = responseJson[DefinesJsonLinkClickIDKey];
        } else {
            self.prefHelper.linkClickID = self.prefHelper.NO_STRING_VALUE;
        }
        
        NSDictionary *invokeFeaturesJson = responseJson[DefinesJsonInvokeFeaturesKey];
        if (invokeFeaturesJson && [invokeFeaturesJson isKindOfClass:[NSDictionary class]] && invokeFeaturesJson[@"enhanced_web_link_ux"]) {
            
            [[BranchLogger shared] logVerbose:@"Opening browser from open request."];
            [branch openBrowserExperience:invokeFeaturesJson];

        } else {
            
            if (responseJson[DefinesJsonDataKey]) {
                NSString *params = responseJson[DefinesJsonDataKey];
                self.prefHelper.sessionParams = params;
            } else {
                self.prefHelper.sessionParams = self.prefHelper.NO_STRING_VALUE;
            }

            if (self.callback) {
                [self.callback onInitFinished:branch.latestReferringParams error:nil];
            }
        }

        NSString *appVersion = [[DeviceInfo getInstance] appVersion];
        
    } @catch (NSException *exception) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Caught Exception processing RequestOpen response: %@", exception.reason]];
    }

    [self onInitSessionCompleted:response branch:branch];
}

- (void)handleFailure:(NSInteger)statusCode causeMsg:(NSString *)causeMsg {
    
    NSString *serverErrorMessage = [NSString stringWithFormat:@"Request Open failed with HTTP code: %ld. Server says: %@", (long)statusCode, causeMsg];
    
    [[BranchLogger shared] logError:serverErrorMessage error:nil];
    
    if (self.callback != nil) {
        
        NSMutableDictionary *obj = [[NSMutableDictionary alloc] init];
        
        @try {
            obj[@"error_message"] = @"Trouble reaching server. Please try again in a few minutes.";
        } @catch (NSException *exception) {
            [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Caught Exception: %@", exception.reason]];
        }
        
        NSString *branchErrorMessage = [NSString stringWithFormat:@"Trouble initializing Branch. %@ failed. %@", self, causeMsg];
        BranchError *error = [[BranchError alloc] initWithMessage:branchErrorMessage statusCode:statusCode];
        
        [self.callback onInitFinished:obj error:error];
    }
}

- (NSString *)getRequestActionName {
    return @ACTION_OPEN; 
}

- (BOOL)isGetRequest {
    return NO;
}

- (void)clearCallbacks {
    self.callback = nil;
}

- (BOOL)shouldRetryOnFail {
    return NO;
}

- (BOOL)handleErrors:(Context *)context {
    return !doesAppHasInternetPermission(context);
}

@end
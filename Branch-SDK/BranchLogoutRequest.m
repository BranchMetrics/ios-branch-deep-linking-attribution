//
//  BranchLogoutRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//


#import "BranchLogoutRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"

@interface BranchLogoutRequest ()
@property (nonatomic, copy) callbackWithStatus callback;
@end


@implementation BranchLogoutRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if ((self = [super init])) {
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN] = preferenceHelper.randomizedBundleToken;
    params[BRANCH_REQUEST_KEY_RANDOMIZED_DEVICE_TOKEN] = preferenceHelper.randomizedDeviceToken;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_LOGOUT] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionID = response.data[BRANCH_RESPONSE_KEY_SESSION_ID];
    preferenceHelper.randomizedBundleToken = BNCStringFromWireFormat(response.data[BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN]);
    preferenceHelper.userUrl = response.data[BRANCH_RESPONSE_KEY_USER_URL];
    preferenceHelper.userIdentity = nil;
    preferenceHelper.installParams = nil;
    preferenceHelper.sessionParams = nil;
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end

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

@implementation BranchLogoutRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID]
    };

    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_LOGOUT] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        return;
    }

    [BNCPreferenceHelper setSessionID:response.data[BRANCH_RESPONSE_KEY_SESSION_ID]];
    [BNCPreferenceHelper setIdentityID:response.data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]];
    [BNCPreferenceHelper setUserURL:response.data[BRANCH_RESPONSE_KEY_USER_URL]];
    [BNCPreferenceHelper setUserIdentity:nil];
    [BNCPreferenceHelper setInstallParams:nil];
    [BNCPreferenceHelper setSessionParams:nil];
    [BNCPreferenceHelper clearUserCreditsAndCounts];
}

@end

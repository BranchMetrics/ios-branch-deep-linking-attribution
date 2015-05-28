//
//  BranchLogoutRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLogoutRequest.h"
#import "BNCPreferenceHelper.h"

@implementation BranchLogoutRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"device_fingerprint_id": [BNCPreferenceHelper getDeviceFingerprintID],
        @"session_id": [BNCPreferenceHelper getSessionID],
        @"identity_id": [BNCPreferenceHelper getIdentityID]
    };

    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"logout"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        return;
    }

    [BNCPreferenceHelper setSessionID:response.data[@"session_id"]];
    [BNCPreferenceHelper setIdentityID:response.data[@"identity_id"]];
    [BNCPreferenceHelper setUserURL:response.data[@"link"]];
    [BNCPreferenceHelper setUserIdentity:nil];
    [BNCPreferenceHelper setInstallParams:nil];
    [BNCPreferenceHelper setSessionParams:nil];
    [BNCPreferenceHelper clearUserCreditsAndCounts];
}

@end

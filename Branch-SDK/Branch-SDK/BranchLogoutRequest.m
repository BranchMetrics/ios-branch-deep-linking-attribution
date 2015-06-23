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
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        @"device_fingerprint_id": preferenceHelper.deviceFingerprintID,
        @"session_id": preferenceHelper.sessionID,
        @"identity_id": preferenceHelper.identityID
    };

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"logout"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        return;
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.sessionID = response.data[@"session_id"];
    preferenceHelper.identityID = response.data[@"identity_id"];
    preferenceHelper.userUrl = response.data[@"link"];
    preferenceHelper.userIdentity = nil;
    preferenceHelper.installParams = nil;
    preferenceHelper.sessionParams = nil;
    [preferenceHelper clearUserCreditsAndCounts];
}

@end

//
//  BranchDisconnectDebugRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchDisconnectDebugRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCConfig.h"

@implementation BranchDisconnectDebugRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: preferenceHelper.identityID,
        @"sdk": [NSString stringWithFormat:@"ios%@", SDK_VERSION]
    };

    [serverInterface postRequest:params url:[[BNCPreferenceHelper preferenceHelper] getAPIURL:BRANCH_REQUEST_ENDPOINT_DISCONNECT_DEBUG] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    [BNCPreferenceHelper preferenceHelper].isConnectedToRemoteDebug = NO;
}

@end

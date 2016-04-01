//
//  BranchCloseRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchCloseRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

@implementation BranchCloseRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: preferenceHelper.identityID,
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID,
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID
    };
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_CLOSE] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to see here
}

@end

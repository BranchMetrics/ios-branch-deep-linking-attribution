//
//  BranchCloseRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchCloseRequest.h"
#import "BNCPreferenceHelper.h"

@implementation BranchCloseRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        @"identity_id": preferenceHelper.identityID,
        @"session_id": preferenceHelper.sessionID,
        @"device_fingerprint_id": preferenceHelper.deviceFingerprintID
    };
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"close"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to see here
}

@end

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
    NSDictionary *params = @{
        @"identity_id": [BNCPreferenceHelper getIdentityID],
        @"session_id": [BNCPreferenceHelper getSessionID],
        @"device_fingerprint_id": [BNCPreferenceHelper getDeviceFingerprintID]
    };
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"close"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to see here
}

@end

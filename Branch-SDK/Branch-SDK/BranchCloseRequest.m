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
    // TODO remove this hack.
    id identityId = [BNCPreferenceHelper getIdentityID] ?: [NSNull null];
    id sessionId = [BNCPreferenceHelper getSessionID] ?: [NSNull null];
    id fingerprintId = [BNCPreferenceHelper getDeviceFingerprintID] ?: [NSNull null];

    NSDictionary *params = @{
        @"identity_id": identityId,
        @"session_id": sessionId,
        @"device_fingerprint_id": fingerprintId
    };
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"close"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to see here
}

@end

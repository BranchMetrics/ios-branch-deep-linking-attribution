//
//  BranchDisconnectDebugRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchDisconnectDebugRequest.h"
#import "BNCPreferenceHelper.h"

@implementation BranchDisconnectDebugRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"device_fingerprint_id": [BNCPreferenceHelper preferenceHelper].deviceFingerprintID
    };

    [serverInterface postRequest:params url:[[BNCPreferenceHelper preferenceHelper] getAPIURL:@"debug/disconnect"] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    [BNCPreferenceHelper preferenceHelper].isConnectedToRemoteDebug = NO;
}

@end

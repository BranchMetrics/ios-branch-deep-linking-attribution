//
//  BranchConnectDebugRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchConnectDebugRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import "BNCConfig.h"

@interface BranchConnectDebugRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation BranchConnectDebugRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_DEVICE_NAME: [BNCSystemObserver getDeviceName],
        BRANCH_REQUEST_KEY_OS: [BNCSystemObserver getOS],
        BRANCH_REQUEST_KEY_OS_VERSION: [BNCSystemObserver getOSVersion],
        BRANCH_REQUEST_KEY_MODEL: [BNCSystemObserver getModel],
        BRANCH_REQUEST_KEY_IS_SIMULATOR: @([BNCSystemObserver isSimulator]),
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: preferenceHelper.identityID,
        @"sdk": [NSString stringWithFormat:@"ios%@", SDK_VERSION]
    };
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_CONNECT_DEBUG] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to connect to debug: %@", error);
    }
    else {
        [BNCPreferenceHelper preferenceHelper].isConnectedToRemoteDebug = YES;

        if (self.callback) {
            self.callback(YES, nil);
        }
    }
}

@end

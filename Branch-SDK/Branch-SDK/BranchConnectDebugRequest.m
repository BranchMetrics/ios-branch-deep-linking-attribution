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
    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_DEVICE_NAME: [BNCSystemObserver getDeviceName],
        BRANCH_REQUEST_KEY_OS: [BNCSystemObserver getOS],
        BRANCH_REQUEST_KEY_OS_VERSION: [BNCSystemObserver getOSVersion],
        BRANCH_REQUEST_KEY_MODEL: [BNCSystemObserver getModel],
        BRANCH_REQUEST_KEY_IS_SIMULATOR: @([BNCSystemObserver isSimulator])
    };
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to connect to debug: %@", error);
    }
    else {
        [BNCPreferenceHelper setConnectedToRemoteDebug:YES];

        if (self.callback) {
            self.callback(YES, nil);
        }
    }
}

@end

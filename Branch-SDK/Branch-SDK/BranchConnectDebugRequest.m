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
        @"device_fingerprint_id": [BNCPreferenceHelper getDeviceFingerprintID],
        @"device_name": [BNCSystemObserver getDeviceName],
        @"os": [BNCSystemObserver getOS],
        @"os_version": [BNCSystemObserver getOSVersion],
        @"model": [BNCSystemObserver getModel],
        @"is_simulator": @([BNCSystemObserver isSimulator])
    };
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"debug/connect"] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to connect to debug: %@", error);
    }
    else {
        [BNCPreferenceHelper setConnectedToRemoteDebug:YES];

        self.callback(YES, nil);
    }
}

@end

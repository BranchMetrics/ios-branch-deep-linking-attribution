//
//  BranchLogoutRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLogoutRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchLogoutRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation BranchLogoutRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }
    
    return self;
}

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
        if (self.callback) {
            self.callback(NO, error);
        }
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
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

@end

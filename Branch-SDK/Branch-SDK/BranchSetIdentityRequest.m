//
//  BranchSetIdentityRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchSetIdentityRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BranchSetIdentityRequest ()

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) callbackWithParams callback;
@property (assign, nonatomic) BOOL shouldCallCallback;

@end

@implementation BranchSetIdentityRequest

- (id)initWithUserId:(NSString *)userId callback:(callbackWithParams)callback {
    if (self = [super init]) {
        _userId = userId;
        _callback = callback;
        _shouldCallCallback = YES;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"identity": self.userId,
        @"device_fingerprint_id": [BNCPreferenceHelper getDeviceFingerprintID],
        @"session_id": [BNCPreferenceHelper getSessionID],
        @"identity_id": [BNCPreferenceHelper getIdentityID]
    };

    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"profile"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback && self.shouldCallCallback) {
            self.callback(nil, error);
        }
        
        self.shouldCallCallback = NO; // don't call the callback next time around
        return;
    }
    
    [BNCPreferenceHelper setIdentityID:response.data[@"identity_id"]];
    [BNCPreferenceHelper setUserURL:response.data[@"link"]];
    [BNCPreferenceHelper setUserIdentity:self.userId];
    
    if (response.data[@"referring_data"]) {
        [BNCPreferenceHelper setInstallParams:response.data[@"referring_data"]];
    }
    
    if (self.callback && self.shouldCallCallback) {
        NSString *storedParams = [BNCPreferenceHelper getInstallParams];
        NSDictionary *installParams = [BNCEncodingUtils decodeJsonStringToDictionary:storedParams];
        self.callback(installParams, nil);
    }
}

@end

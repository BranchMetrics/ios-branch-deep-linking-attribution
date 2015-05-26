//
//  BranchApplyReferralCodeRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchApplyReferralCodeRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCError.h"

@interface BranchApplyReferralCodeRequest ()

@property (strong, nonatomic) NSString *code;
@property (strong, nonatomic) callbackWithParams callback;

@end

@implementation BranchApplyReferralCodeRequest

- (id)initWithCode:(NSString *)code callback:(callbackWithParams)callback {
    if (self = [super init]) {
        _code = code;
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"referral_code": self.code,
        @"identity_id": [BNCPreferenceHelper getIdentityID],
        @"device_fingerprint_id": [BNCPreferenceHelper getDeviceFingerprintID],
        @"session_id": [BNCPreferenceHelper getSessionID]
    };
    
    NSString *url = [[BNCPreferenceHelper getAPIURL:@"applycode/"] stringByAppendingString:self.code];
    [serverInterface postRequest:params url:url key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    if (!response.data[@"referral_code"]) {
        error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:@{ NSLocalizedDescriptionKey: @"Referral code is invalid - it may have already been used or the code might not exist" }];
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

@end

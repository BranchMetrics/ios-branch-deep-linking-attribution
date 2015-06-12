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
#import "BranchConstants.h"

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
        BRANCH_REQUEST_KEY_REFERRAL_CODE: self.code,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
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
    
    if (!response.data[BRANCH_RESPONSE_KEY_REFERRAL_CODE]) {
        error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:@{ NSLocalizedDescriptionKey: @"Referral code is invalid - it may have already been used or the code might not exist" }];
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _code = [decoder decodeObjectForKey:@"code"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.code forKey:@"code"];
}

@end

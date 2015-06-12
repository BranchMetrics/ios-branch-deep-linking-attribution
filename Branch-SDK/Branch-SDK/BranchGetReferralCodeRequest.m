//
//  BranchGetReferralCodeRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchGetReferralCodeRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCError.h"
#import "BranchConstants.h"

@interface BranchGetReferralCodeRequest ()

@property (assign, nonatomic) BranchReferralCodeCalculation calcType;
@property (assign, nonatomic) BranchReferralCodeLocation location;
@property (assign, nonatomic) NSInteger amount;
@property (strong, nonatomic) NSString *bucket;
@property (strong, nonatomic) NSString *prefix;
@property (strong, nonatomic) NSDate *expiration;
@property (strong, nonatomic) callbackWithParams callback;

@end

@implementation BranchGetReferralCodeRequest

- (id)initWithCalcType:(BranchReferralCodeCalculation)calcType location:(BranchReferralCodeLocation)location amount:(NSInteger)amount bucket:(NSString *)bucket prefix:(NSString *)prefix expiration:(NSDate *)expiration callback:(callbackWithParams)callback {
    if (self = [super init]) {
        _calcType = calcType;
        _location = location;
        _amount = amount;
        _bucket = bucket;
        _prefix = prefix;
        _expiration = expiration;
        _callback = callback;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = [BNCPreferenceHelper getDeviceFingerprintID];
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = [BNCPreferenceHelper getIdentityID];
    params[BRANCH_REQUEST_KEY_SESSION_ID] = [BNCPreferenceHelper getSessionID];
    params[BRANCH_REQUEST_KEY_REFERRAL_CALCULATION_TYPE] = @(self.calcType);
    params[BRANCH_REQUEST_KEY_REFERRAL_REWARD_LOCATION] = @(self.location);
    params[BRANCH_REQUEST_KEY_REFERRAL_TYPE] = @"credit";
    params[BRANCH_REQUEST_KEY_REFERRAL_CREATION_SOURCE] = @2; // iOS SDK = 2
    params[BRANCH_REQUEST_KEY_AMOUNT] = @(self.amount);
    params[BRANCH_REQUEST_KEY_BUCKET] = self.bucket;
    
    if (self.prefix.length) {
        params[BRANCH_REQUEST_KEY_REFERRAL_PREFIX] = self.prefix;
    }
    
    if (self.expiration) {
        params[BRANCH_REQUEST_KEY_REFERRAL_EXPIRATION] = self.expiration;
    }
    
    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"referralcode"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    if (!response.data[BRANCH_RESPONSE_KEY_REFERRAL_CODE]) {
        error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:@{ NSLocalizedDescriptionKey: @"Referral code with specified parameter set is already taken for a different user" }];
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _calcType = [decoder decodeIntegerForKey:@"calcType"];
        _location = [decoder decodeIntegerForKey:@"location"];
        _amount = [decoder decodeIntegerForKey:@"amount"];
        _bucket = [decoder decodeObjectForKey:@"bucket"];
        _prefix = [decoder decodeObjectForKey:@"prefix"];
        _expiration = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:@"expiration"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeInteger:self.calcType forKey:@"calcType"];
    [coder encodeInteger:self.location forKey:@"location"];
    [coder encodeInteger:self.amount forKey:@"amount"];
    [coder encodeObject:self.bucket forKey:@"bucket"];
    [coder encodeObject:self.prefix forKey:@"prefix"];
    [coder encodeDouble:[self.expiration timeIntervalSince1970] forKey:@"expiration"];
}

@end

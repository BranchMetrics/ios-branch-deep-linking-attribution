//
//  BranchGetReferralCodeRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchGetPromoCodeRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCError.h"

@interface BranchGetPromoCodeRequest ()

@property (assign, nonatomic) BranchPromoCodeUsageType usageType;
@property (assign, nonatomic) BranchPromoCodeRewardLocation rewardLocation;
@property (assign, nonatomic) NSInteger amount;
@property (strong, nonatomic) NSString *bucket;
@property (strong, nonatomic) NSString *prefix;
@property (strong, nonatomic) NSDate *expiration;
@property (strong, nonatomic) callbackWithParams callback;

@property (assign, nonatomic) BOOL useOld;

@end

@implementation BranchGetPromoCodeRequest

- (id)initWithUsageType:(BranchPromoCodeUsageType)usageType rewardLocation:(BranchPromoCodeRewardLocation)rewardLocation amount:(NSInteger)amount bucket:(NSString *)bucket prefix:(NSString *)prefix expiration:(NSDate *)expiration useOld:(BOOL)useOld callback:(callbackWithParams)callback {
    if (self = [super init]) {
        _usageType = usageType;
        _rewardLocation = rewardLocation;
        _amount = amount;
        _bucket = bucket;
        _prefix = prefix;
        _expiration = expiration;
        _callback = callback;
        _useOld = useOld;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    params[@"device_fingerprint_id"] = preferenceHelper.deviceFingerprintID;
    params[@"identity_id"] = preferenceHelper.identityID;
    params[@"session_id"] = preferenceHelper.sessionID;
    params[@"calculation_type"] = @(self.usageType);
    params[@"location"] = @(self.rewardLocation);
    params[@"type"] = @"credit";
    params[@"creation_source"] = @2; // SDK = 2
    params[@"amount"] = @(self.amount);
    params[@"bucket"] = self.bucket;
    
    if (self.prefix.length) {
        params[@"prefix"] = self.prefix;
    }
    
    if (self.expiration) {
        params[@"expiration"] = self.expiration;
    }
    
    NSString *endpoint = self.useOld ? @"referralcode" : @"promo-code";
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:endpoint] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(nil, error);
        }
        return;
    }
    
    NSString *responseKey = self.useOld ? @"referral_code" : @"promo_code";
    
    if (!response.data[responseKey]) {
        error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:@{ NSLocalizedDescriptionKey: @"Promo code with specified parameter set is already taken for a different user" }];
    }
    
    if (self.callback) {
        self.callback(response.data, error);
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _usageType = [decoder decodeIntegerForKey:@"usageType"];
        _rewardLocation = [decoder decodeIntegerForKey:@"rewardLocation"];
        _amount = [decoder decodeIntegerForKey:@"amount"];
        _bucket = [decoder decodeObjectForKey:@"bucket"];
        _prefix = [decoder decodeObjectForKey:@"prefix"];
        _expiration = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:@"expiration"]];
        _useOld = [decoder decodeBoolForKey:@"useOld"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeInteger:self.usageType forKey:@"usageType"];
    [coder encodeInteger:self.rewardLocation forKey:@"rewardLocation"];
    [coder encodeInteger:self.amount forKey:@"amount"];
    [coder encodeObject:self.bucket forKey:@"bucket"];
    [coder encodeObject:self.prefix forKey:@"prefix"];
    [coder encodeDouble:[self.expiration timeIntervalSince1970] forKey:@"expiration"];
    [coder encodeBool:self.useOld forKey:@"useOld"];
}

@end

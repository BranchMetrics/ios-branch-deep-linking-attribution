//
//  BranchRedeemRewardsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchRedeemRewardsRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchRedeemRewardsRequest ()

@property (assign, nonatomic) NSInteger amount;
@property (strong, nonatomic) NSString *bucket;
@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation BranchRedeemRewardsRequest

- (id)initWithAmount:(NSInteger)amount bucket:(NSString *)bucket callback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _amount = amount;
        _bucket = bucket;
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSDictionary *params = @{
        @"bucket": self.bucket,
        @"amount": @(self.amount),
        @"device_fingerprint_id": preferenceHelper.deviceFingerprintID,
        @"identity_id": preferenceHelper.identityID,
        @"session_id": preferenceHelper.sessionID
    };

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"redeem"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    
    // Update local balance
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSInteger currentAvailableCredits = [preferenceHelper getCreditCountForBucket:self.bucket];
    NSInteger updatedBalance = currentAvailableCredits - self.amount;
    [preferenceHelper setCreditCount:updatedBalance forBucket:self.bucket];
    
    if (self.callback) {
        self.callback(YES, nil);
    }
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _amount = [decoder decodeIntegerForKey:@"amount"];
        _bucket = [decoder decodeObjectForKey:@"bucket"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeInteger:self.amount forKey:@"amount"];
    [coder encodeObject:self.bucket forKey:@"bucket"];
}

@end

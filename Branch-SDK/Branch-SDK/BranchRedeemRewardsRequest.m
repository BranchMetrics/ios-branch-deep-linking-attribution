//
//  BranchRedeemRewardsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchRedeemRewardsRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

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
    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_BUCKET: self.bucket,
        BRANCH_REQUEST_KEY_AMOUNT: @(self.amount),
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
    };

    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_REDEEM_REWARDS] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    
    // Update local balance
    NSInteger currentAvailableCredits = [BNCPreferenceHelper getCreditCountForBucket:self.bucket];
    NSInteger updatedBalance = currentAvailableCredits - self.amount;
    [BNCPreferenceHelper setCreditCount:updatedBalance forBucket:self.bucket];
    
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

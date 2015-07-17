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
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSDictionary *params = @{
        @"identity": self.userId,
        @"device_fingerprint_id": preferenceHelper.deviceFingerprintID,
        @"session_id": preferenceHelper.sessionID,
        @"identity_id": preferenceHelper.identityID
    };

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:@"profile"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback && self.shouldCallCallback) {
            self.callback(nil, error);
        }
        
        self.shouldCallCallback = NO; // don't call the callback next time around
        return;
    }
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.identityID = response.data[@"identity_id"];
    preferenceHelper.userUrl = response.data[@"link"];
    preferenceHelper.userIdentity = self.userId;
    
    if (response.data[@"referring_data"]) {
        preferenceHelper.installParams = response.data[@"referring_data"];
    }
    
    if (self.callback && self.shouldCallCallback) {
        NSString *storedParams = preferenceHelper.installParams;
        NSDictionary *installParams = [BNCEncodingUtils decodeJsonStringToDictionary:storedParams];
        self.callback(installParams, nil);
    }
}

#pragma mark - NSCoding methods

// No need to do anything with callback, as the callback itself is gone after the end of a run

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _userId = [decoder decodeObjectForKey:@"userId"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.userId forKey:@"userId"];
}

@end

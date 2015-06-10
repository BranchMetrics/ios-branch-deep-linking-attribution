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
#import "BranchConstants.h"

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
        BRANCH_REQUEST_KEY_DEVELOPER_IDENTITY: self.userId,
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID]
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
    
    [BNCPreferenceHelper setIdentityID:response.data[BRANCH_RESPONSE_KEY_BRANCH_IDENTITY]];
    [BNCPreferenceHelper setUserURL:response.data[BRANCH_RESPONSE_KEY_USER_URL]];
    [BNCPreferenceHelper setUserIdentity:self.userId];
    
    if (response.data[BRANCH_RESPONSE_KEY_INSTALL_PARAMS]) {
        [BNCPreferenceHelper setInstallParams:response.data[BRANCH_RESPONSE_KEY_INSTALL_PARAMS]];
    }
    
    if (self.callback && self.shouldCallCallback) {
        NSString *storedParams = [BNCPreferenceHelper getInstallParams];
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

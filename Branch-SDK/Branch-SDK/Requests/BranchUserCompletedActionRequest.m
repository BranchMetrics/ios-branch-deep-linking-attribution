//
//  BranchLoadActionsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchUserCompletedActionRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

@interface BranchUserCompletedActionRequest ()

@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) NSDictionary *state;

@end

@implementation BranchUserCompletedActionRequest

- (id)initWithAction:(NSString *)action state:(NSDictionary *)state {
    if (self = [super init]) {
        _action = action;
        _state = state;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    params[BRANCH_REQUEST_KEY_ACTION] = self.action;
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    
    if (self.state) {
        params[BRANCH_REQUEST_KEY_STATE] = self.state;
    }

    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to do here...
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _action = [decoder decodeObjectForKey:@"action"];
        _state = [decoder decodeObjectForKey:@"state"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.action forKey:@"action"];
    [coder encodeObject:self.state forKey:@"state"];
}

@end

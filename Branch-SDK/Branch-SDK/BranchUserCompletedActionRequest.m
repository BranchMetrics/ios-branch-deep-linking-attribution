//
//  BranchLoadActionsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchUserCompletedActionRequest.h"
#import "BNCPreferenceHelper.h"

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
    
    params[@"event"] = self.action;
    params[@"device_fingerprint_id"] = [BNCPreferenceHelper getDeviceFingerprintID];
    params[@"identity_id"] = [BNCPreferenceHelper getIdentityID];
    params[@"session_id"] = [BNCPreferenceHelper getSessionID];
    
    if (self.state) {
        params[@"metadata"] = self.state;
    }

    [serverInterface postRequest:params url:[BNCPreferenceHelper getAPIURL:@"event"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to do here...
}

@end

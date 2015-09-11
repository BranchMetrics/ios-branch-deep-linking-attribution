//
//  BranchLoadActionsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLoadActionsRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"

@interface BranchLoadActionsRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation BranchLoadActionsRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *endpoint = [BRANCH_REQUEST_ENDPOINT_LOAD_ACTIONS stringByAppendingPathComponent:preferenceHelper.identityID];
    [serverInterface getRequest:nil url:[preferenceHelper getAPIURL:endpoint] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        if (self.callback) {
            self.callback(NO, error);
        }
        return;
    }
    
    BOOL hasUpdated = NO;
    for (NSString *key in response.data) {
        NSDictionary *counts = response.data[key];
        NSInteger total = [counts[BRANCH_RESPONSE_KEY_ACTION_COUNT_TOTAL] integerValue];
        NSInteger unique = [counts[BRANCH_RESPONSE_KEY_ACTION_COUNT_UNIQUE] integerValue];
        
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
        if (total != [preferenceHelper getActionTotalCount:key] || unique != [preferenceHelper getActionUniqueCount:key]) {
            hasUpdated = YES;
        }
        
        [preferenceHelper setActionTotalCount:key withCount:total];
        [preferenceHelper setActionUniqueCount:key withCount:unique];
    }
    
    if (self.callback) {
        self.callback(hasUpdated, nil);
    }
}

@end

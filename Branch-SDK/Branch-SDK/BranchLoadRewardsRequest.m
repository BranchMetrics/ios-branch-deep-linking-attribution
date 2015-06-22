//
//  BranchLoadRewardsRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLoadRewardsRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchLoadRewardsRequest ()

@property (strong, nonatomic) callbackWithStatus callback;

@end

@implementation BranchLoadRewardsRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    if (self = [super init]) {
        _callback = callback;
    }

    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSString *endpoint = [NSString stringWithFormat:@"credits/%@", [BNCPreferenceHelper getIdentityID]];
    [serverInterface getRequest:nil url:[BNCPreferenceHelper getAPIURL:endpoint] key:key callback:callback];
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
        NSInteger credits = [response.data[key] integerValue];
        
        if (credits != [BNCPreferenceHelper getCreditCountForBucket:key]) {
            hasUpdated = YES;
        }
        
        [BNCPreferenceHelper setCreditCount:credits forBucket:key];
    }
    
    if (self.callback) {
        self.callback(hasUpdated, nil);
    }
}

@end

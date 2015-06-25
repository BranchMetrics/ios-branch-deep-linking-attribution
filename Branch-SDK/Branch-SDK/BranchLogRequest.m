//
//  BranchLogRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLogRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchLogRequest ()

@property (strong, nonatomic) NSString *log;

@end

@implementation BranchLogRequest

- (id)initWithLog:(NSString *)log {
    if (self = [super init]) {
        _log = log;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"log": self.log,
        @"device_fingerprint_id": [BNCPreferenceHelper preferenceHelper].deviceFingerprintID
    };
    
    [serverInterface postRequest:params url:[[BNCPreferenceHelper preferenceHelper] getAPIURL:@"debug/log"] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to do here
}

@end

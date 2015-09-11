//
//  BranchLogRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/3/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchLogRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCError.h"

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
    if (!self.log) {
        callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCNilLogError userInfo:@{ NSLocalizedDescriptionKey: @"Cannot log nil to server." }]);
        return;
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSDictionary *params = @{
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_LOG: self.log
    };
    
    [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_LOG] key:key log:NO callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    // Nothing to do here
}

@end

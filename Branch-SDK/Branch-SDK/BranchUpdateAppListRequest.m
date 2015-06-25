//
//  BranchUpdateAppListRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchUpdateAppListRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BNCEncodingUtils.h"

@interface BranchUpdateAppListRequest ()

@property (strong, nonatomic) NSDictionary *appList;

@end

@implementation BranchUpdateAppListRequest

- (id)initWithAppList:(NSDictionary *)appList {
    if (self = [super init]) {
        _appList = appList;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    NSDictionary *params = @{
        @"device_fingerprint_id": [BNCPreferenceHelper preferenceHelper].deviceFingerprintID,
        @"os": [BNCSystemObserver getOS],
        @"apps_data": self.appList
    };

    [serverInterface postRequest:params url:[[BNCPreferenceHelper preferenceHelper] getAPIURL:@"applist"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        return;
    }
    
    [[BNCPreferenceHelper preferenceHelper] setAppListCheckDone];
}

#pragma mark - NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        _appList = [BNCEncodingUtils decodeJsonStringToDictionary:[decoder decodeObjectForKey:@"appList"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:[BNCEncodingUtils encodeDictionaryToJsonString:self.appList] forKey:@"appList"];
}

@end

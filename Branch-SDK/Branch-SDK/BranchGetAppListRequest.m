//
//  BranchGetAppListRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchGetAppListRequest.h"
#import "BNCPreferenceHelper.h"

@interface BranchGetAppListRequest ()

@property (strong, nonatomic) callbackWithList callback;

@end

@implementation BranchGetAppListRequest

- (id)initWithCallback:(callbackWithList)callback {
    if (self = [super init]) {
        _callback = callback;
    }
    
    return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    [serverInterface getRequest:nil url:[BNCPreferenceHelper getAPIURL:@"applist"] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    if (error) {
        self.callback(nil, error);
        return;
    }
    
    [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"returned from app check with %@", response.data];
    
    self.callback(response.data[@"potential_apps"], nil);
}

@end

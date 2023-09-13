//
//  BranchCPIDRequest.m
//  Branch
//
//  Created by Ernest Cho on 9/9/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BranchCPIDRequest.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCRequestFactory.h"

@implementation BranchCPIDRequest

- (NSString *)serverURL {    
    return [[BNCPreferenceHelper sharedInstance] getAPIURL:BRANCH_REQUEST_ENDPOINT_CPID];
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key];
    NSDictionary *json = [factory dataForCPID];
    [serverInterface postRequest:json url:[self serverURL] key:key callback:callback];
}

// unused, callee handles parsing the json response
- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error { }

@end

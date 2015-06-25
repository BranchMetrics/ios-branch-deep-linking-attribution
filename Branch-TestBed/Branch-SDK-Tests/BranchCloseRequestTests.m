//
//  BranchCloseRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import "BranchTest.h"
#import "BranchCloseRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BranchCloseRequestTests : BranchTest

@end

@implementation BranchCloseRequestTests

- (void)testRequestBody {
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
    };
    
    BranchCloseRequest *request = [[BranchCloseRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_CLOSE] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

@end

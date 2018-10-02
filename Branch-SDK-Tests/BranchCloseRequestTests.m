//
//  BranchCloseRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import "BNCTestCase.h"
#import <OCMock/OCMock.h>
#import "BranchCloseRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BranchCloseRequestTests : BNCTestCase
@end

@implementation BranchCloseRequestTests

- (void)testRequestBody {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.identityID = @"foo_identity";
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: preferenceHelper.identityID,
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID
    };
    
    BranchCloseRequest *request = [[BranchCloseRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
        postRequest:expectedParams
        url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_CLOSE]
        key:[OCMArg any]
        callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    [serverInterfaceMock verify];
}

@end

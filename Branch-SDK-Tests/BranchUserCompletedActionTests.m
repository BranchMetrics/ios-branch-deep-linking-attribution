//
//  BranchUserCompletedActionTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/11/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchUserCompletedActionRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchUserCompletedActionTests : BNCTestCase

@end

@implementation BranchUserCompletedActionTests

- (void)testRequestBodyWithoutState {
    NSString * const USER_ACTION_TEST_ACTION = @"foo-action";
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary *expectedParams = NSMutableDictionary.new;
    expectedParams[BRANCH_REQUEST_KEY_ACTION] = USER_ACTION_TEST_ACTION;
    expectedParams[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedParams[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedParams[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

    BranchUserCompletedActionRequest *request = [[BranchUserCompletedActionRequest alloc] initWithAction:USER_ACTION_TEST_ACTION state:nil];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testRequestBodyWithState {
    NSString * const USER_ACTION_TEST_ACTION = @"foo-action";
    NSDictionary * const USER_ACTION_TEST_STATE = @{ @"foo": @"bar" };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSMutableDictionary *expectedParams = NSMutableDictionary.new;
    expectedParams[BRANCH_REQUEST_KEY_ACTION] = USER_ACTION_TEST_ACTION;
    expectedParams[BRANCH_REQUEST_KEY_STATE] = USER_ACTION_TEST_STATE;
    expectedParams[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedParams[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedParams[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;
    
    BranchUserCompletedActionRequest *request = [[BranchUserCompletedActionRequest alloc] initWithAction:USER_ACTION_TEST_ACTION state:USER_ACTION_TEST_STATE];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

@end

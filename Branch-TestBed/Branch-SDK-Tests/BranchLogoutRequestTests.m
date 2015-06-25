//
//  BranchLogoutRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchLogoutRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchLogoutRequestTests : BranchTest

@end

@implementation BranchLogoutRequestTests

- (void)testRequestBody {
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
    };
    
    BranchLogoutRequest *request = [[BranchLogoutRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_LOGOUT] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSString * const PRE_RESPONSE_SESSION_ID = @"foo";
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const PRE_RESPONSE_SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const RESPONSE_SESSION_ID = @"bar";
    NSString * const RESPONSE_IDENTITY = @"bar";
    NSString * const RESPONSE_USER_URL = @"http://bar";
    
    
    [BNCPreferenceHelper setSessionID:PRE_RESPONSE_SESSION_ID];
    [BNCPreferenceHelper setIdentityID:PRE_RESPONSE_IDENTITY];
    [BNCPreferenceHelper setUserURL:PRE_RESPONSE_USER_URL];
    [BNCPreferenceHelper setUserIdentity:PRE_RESPONSE_USER_IDENTITY];
    [BNCPreferenceHelper setInstallParams:PRE_RESPONSE_INSTALL_PARAMS];
    [BNCPreferenceHelper setSessionParams:PRE_RESPONSE_SESSION_PARAMS];
    [BNCPreferenceHelper setCreditCount:5 forBucket:@"foo"];
    
    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_SESSION_ID: RESPONSE_SESSION_ID,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: RESPONSE_IDENTITY
    };
    
    BranchLogoutRequest *request = [[BranchLogoutRequest alloc] init];
    
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], RESPONSE_IDENTITY);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], RESPONSE_USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], RESPONSE_SESSION_ID);
    XCTAssertNil([BNCPreferenceHelper getUserIdentity]);
    XCTAssertNil([BNCPreferenceHelper getInstallParams]);
    XCTAssertNil([BNCPreferenceHelper getSessionParams]);
    XCTAssertEqual([BNCPreferenceHelper getCreditCountForBucket:@"foo"], 0);
}

- (void)testFailureSuccess {
    NSString * const PRE_RESPONSE_SESSION_ID = @"foo";
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const PRE_RESPONSE_SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSError * const requestError = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    
    [BNCPreferenceHelper setSessionID:PRE_RESPONSE_SESSION_ID];
    [BNCPreferenceHelper setIdentityID:PRE_RESPONSE_IDENTITY];
    [BNCPreferenceHelper setUserURL:PRE_RESPONSE_USER_URL];
    [BNCPreferenceHelper setUserIdentity:PRE_RESPONSE_USER_IDENTITY];
    [BNCPreferenceHelper setInstallParams:PRE_RESPONSE_INSTALL_PARAMS];
    [BNCPreferenceHelper setSessionParams:PRE_RESPONSE_SESSION_PARAMS];
    [BNCPreferenceHelper setCreditCount:5 forBucket:@"foo"];
    
    
    BranchLogoutRequest *request = [[BranchLogoutRequest alloc] init];
    
    [request processResponse:nil error:requestError];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], PRE_RESPONSE_IDENTITY);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], PRE_RESPONSE_USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], PRE_RESPONSE_SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], PRE_RESPONSE_USER_IDENTITY);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], PRE_RESPONSE_INSTALL_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionParams], PRE_RESPONSE_SESSION_PARAMS);
    XCTAssertEqual([BNCPreferenceHelper getCreditCountForBucket:@"foo"], 5);
}

@end

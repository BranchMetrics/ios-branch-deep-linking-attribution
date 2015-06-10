//
//  BranchSetIdentityRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchSetIdentityRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

NSString * const IDENTITY_TEST_USER_ID = @"foo_id";

@interface BranchSetIdentityRequestTests : BranchTest

@end

@implementation BranchSetIdentityRequestTests

- (void)testMakeRequestBody {
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_DEVELOPER_IDENTITY: IDENTITY_TEST_USER_ID,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID]
    };

    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const RESPONSE_IDENTITY = @"bar";
    NSString * const RESPONSE_USER_URL = @"http://bar";
    NSString * const RESPONSE_INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSDictionary * const RESPONSE_INSTALL_PARAMS_DICT = @{ @"bar": @"foo" };
    __block NSInteger callbackCount = 0;
    
    [BNCPreferenceHelper setUserIdentity:PRE_RESPONSE_USER_IDENTITY];
    [BNCPreferenceHelper setIdentityID:PRE_RESPONSE_IDENTITY];
    [BNCPreferenceHelper setUserURL:PRE_RESPONSE_USER_URL];
    [BNCPreferenceHelper setInstallParams:PRE_RESPONSE_INSTALL_PARAMS];
    
    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: RESPONSE_IDENTITY,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_RESPONSE_KEY_INSTALL_PARAMS: RESPONSE_INSTALL_PARAMS
    };
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertEqualObjects(params, RESPONSE_INSTALL_PARAMS_DICT);
        XCTAssertNil(error);
    }];
    
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqual(callbackCount, 1);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], IDENTITY_TEST_USER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], RESPONSE_IDENTITY);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], RESPONSE_USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], RESPONSE_INSTALL_PARAMS);
}

- (void)testBasicErrorHandling {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    __block NSInteger callbackCount = 0;
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertNil(params);
        XCTAssertEqual(error, TEST_ERROR);
    }];
    
    [request processResponse:nil error:TEST_ERROR];
    
    XCTAssertEqual(callbackCount, 1);
}

- (void)testMultipleErrors {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    __block NSInteger callbackCount = 0;
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertNil(params);
        XCTAssertEqual(error, TEST_ERROR);
    }];
    
    [request processResponse:nil error:TEST_ERROR];
    [request processResponse:nil error:TEST_ERROR];
    
    XCTAssertEqual(callbackCount, 1);
}

- (void)testErrorFollowedBySuccess {
    NSError * const TEST_ERROR = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const RESPONSE_IDENTITY = @"bar";
    NSString * const RESPONSE_USER_URL = @"http://bar";
    NSString * const RESPONSE_INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    __block NSInteger callbackCount = 0;
    
    [BNCPreferenceHelper setUserIdentity:PRE_RESPONSE_USER_IDENTITY];
    [BNCPreferenceHelper setIdentityID:PRE_RESPONSE_IDENTITY];
    [BNCPreferenceHelper setUserURL:PRE_RESPONSE_USER_URL];
    [BNCPreferenceHelper setInstallParams:PRE_RESPONSE_INSTALL_PARAMS];

    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: RESPONSE_IDENTITY,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_RESPONSE_KEY_INSTALL_PARAMS: RESPONSE_INSTALL_PARAMS
    };
    
    BranchSetIdentityRequest *request = [[BranchSetIdentityRequest alloc] initWithUserId:IDENTITY_TEST_USER_ID callback:^(NSDictionary *params, NSError *error) {
        callbackCount++;
        XCTAssertNil(params);
        XCTAssertEqual(error, TEST_ERROR);
    }];
    
    [request processResponse:nil error:TEST_ERROR];
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqual(callbackCount, 1); // callback should have only been called once, but preferences should be updated
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], IDENTITY_TEST_USER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], RESPONSE_IDENTITY);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], RESPONSE_USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], RESPONSE_INSTALL_PARAMS);
}

@end

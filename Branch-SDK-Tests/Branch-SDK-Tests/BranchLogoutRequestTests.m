//
//  BranchLogoutRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/10/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BranchLogoutRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchLogoutRequestTests : BNCTestCase
@end

@implementation BranchLogoutRequestTests

- (void)testRequestBody {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: preferenceHelper.identityID,
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: preferenceHelper.deviceFingerprintID,
        BRANCH_REQUEST_KEY_SESSION_ID: preferenceHelper.sessionID
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
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.sessionID = PRE_RESPONSE_SESSION_ID;
    preferenceHelper.identityID = PRE_RESPONSE_IDENTITY;
    preferenceHelper.userUrl = PRE_RESPONSE_USER_URL;
    preferenceHelper.userIdentity = PRE_RESPONSE_USER_IDENTITY;
    preferenceHelper.installParams = PRE_RESPONSE_INSTALL_PARAMS;
    preferenceHelper.sessionParams = PRE_RESPONSE_SESSION_PARAMS;
    [preferenceHelper setCreditCount:5 forBucket:@"foo"];
    
    BNCServerResponse * const goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.data = @{
        BRANCH_RESPONSE_KEY_SESSION_ID: RESPONSE_SESSION_ID,
        BRANCH_RESPONSE_KEY_USER_URL: RESPONSE_USER_URL,
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: RESPONSE_IDENTITY
    };
    
    BranchLogoutRequest *request = [[BranchLogoutRequest alloc] init];
    
    [request processResponse:goodResponse error:nil];
    
    XCTAssertEqualObjects(preferenceHelper.identityID, RESPONSE_IDENTITY);
    XCTAssertEqualObjects(preferenceHelper.userUrl, RESPONSE_USER_URL);
    XCTAssertEqualObjects(preferenceHelper.sessionID, RESPONSE_SESSION_ID);
    XCTAssertNil(preferenceHelper.userIdentity);
    XCTAssertNil(preferenceHelper.installParams);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertEqual([preferenceHelper getCreditCountForBucket:@"foo"], 0);
}

- (void)testFailureSuccess {
    NSString * const PRE_RESPONSE_SESSION_ID = @"foo";
    NSString * const PRE_RESPONSE_USER_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_IDENTITY = @"foo";
    NSString * const PRE_RESPONSE_USER_URL = @"http://foo";
    NSString * const PRE_RESPONSE_INSTALL_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const PRE_RESPONSE_SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSError * const requestError = [NSError errorWithDomain:@"foo" code:1 userInfo:nil];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.sessionID = PRE_RESPONSE_SESSION_ID;
    preferenceHelper.identityID = PRE_RESPONSE_IDENTITY;
    preferenceHelper.userUrl = PRE_RESPONSE_USER_URL;
    preferenceHelper.userIdentity = PRE_RESPONSE_USER_IDENTITY;
    preferenceHelper.installParams = PRE_RESPONSE_INSTALL_PARAMS;
    preferenceHelper.sessionParams = PRE_RESPONSE_SESSION_PARAMS;
    [preferenceHelper setCreditCount:5 forBucket:@"foo"];
    
    
    BranchLogoutRequest *request = [[BranchLogoutRequest alloc] init];
    
    [request processResponse:nil error:requestError];
    
    XCTAssertEqualObjects(preferenceHelper.identityID, PRE_RESPONSE_IDENTITY);
    XCTAssertEqualObjects(preferenceHelper.userUrl, PRE_RESPONSE_USER_URL);
    XCTAssertEqualObjects(preferenceHelper.sessionID, PRE_RESPONSE_SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, PRE_RESPONSE_USER_IDENTITY);
    XCTAssertEqualObjects(preferenceHelper.installParams, PRE_RESPONSE_INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, PRE_RESPONSE_SESSION_PARAMS);
    XCTAssertEqual([preferenceHelper getCreditCountForBucket:@"foo"], 5);
}

@end

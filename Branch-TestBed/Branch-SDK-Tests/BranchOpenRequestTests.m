//
//  BranchOpenRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "Branch.h"
#import "BNCLog.h"
#import "BNCApplication+BNCTest.h"
#import "BranchOpenRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BNCSystemObserver.h"

@interface BranchOpenRequestTests : BNCTestCase
@end

@implementation BranchOpenRequestTests

- (void)setUp {
    [super setUp];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = nil;
    preferenceHelper.randomizedBundleToken = nil;
    [preferenceHelper saveContentAnalyticsManifest:nil];
    [preferenceHelper synchronize];
}

- (void)testSuccessWithAllKeysAndIsReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    NSString * const RANDOMIZED_BUNDLE_TOKEN = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: RANDOMIZED_BUNDLE_TOKEN
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:TRUE];

    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, RANDOMIZED_BUNDLE_TOKEN);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithAllKeysAndIsNotReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsNotReferrable {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsNotSet {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsSet {
    NSString * const DEVICE_TOKEN = @"foo-token";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:NO];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
    XCTAssertNil(preferenceHelper.installParams);
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNonNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, OPEN_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    } isInstall:TRUE];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndNoInstallParamsAndNonLinkClickData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":0}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenReferrableAndInstallParams {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const INSTALL_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"bar\":\"foo\"}";
    
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testOpenWhenNotReferrable {
    //  'isReferrable' seems to be an empty concept in iOS.
    //  It is in the code but not used. -- Edward.

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssert([preferenceHelper.installParams isEqualToString:OPEN_PARAMS]);
        [self safelyFulfillExpectation:expectation];
    } isInstall:TRUE];
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

- (void)testEmptyResponseFields {
    NSString *  DEVICE_TOKEN = @"foo-token";
    NSString *  USER_URL = @"http://foo";
    NSString *  DEVELOPER_ID = @"foo";
    NSString *  SESSION_ID = @"foo-session";
    NSString *  IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: DEVICE_TOKEN,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: IDENTITY
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:NO];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.randomizedDeviceToken, DEVICE_TOKEN);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.randomizedBundleToken, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
    XCTAssertNil(preferenceHelper.installParams);
    
    // Now call processResponse with empty fields again.
    response.data = @{};
    [request processResponse:response error:nil];
    
    XCTAssertNotNil(preferenceHelper.randomizedDeviceToken);
    XCTAssertNotNil(preferenceHelper.userUrl);
    XCTAssertNotNil(preferenceHelper.sessionID);
    XCTAssertNotNil(preferenceHelper.randomizedBundleToken);
}

@end

//
//  BranchInstallRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/24/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BranchInstallRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import <OCMock/OCMock.h>

@interface BranchInstallRequestTests : BranchTest

@end

@implementation BranchInstallRequestTests

- (void)testRequestBody {
    NSString * const HARDWARE_ID = @"foo-hardware-id";
    NSNumber * const AD_TRACKING_SAFE = @YES;
    NSNumber * const IS_REFERRABLE = @YES;
    NSNumber * const IS_DEBUG = @YES;
    NSString * const BUNDLE_ID = @"foo-bundle-id";
    NSString * const APP_VERSION = @"foo-app-version";
    NSString * const OS = @"foo-os";
    NSString * const OS_VERSION = @"foo-os-version";
    NSString * const URI_SCHEME = @"foo-uri-scheme";
    NSNumber * const UPDATE_STATE = @1;
    NSString * const LINK_IDENTIFIER = @"foo-link-id";
    NSString * const CARRIER = @"foo-carrier";
    NSString * const BRAND = @"foo-brand";
    NSString * const MODEL = @"foo-model";
    NSNumber * const SCREEN_WIDTH = @1;
    NSNumber * const SCREEN_HEIGHT = @2;
    
    id systemObserverMock = OCMClassMock([BNCSystemObserver class]);
    [[[[systemObserverMock stub] ignoringNonObjectArgs] andReturn:HARDWARE_ID] getUniqueHardwareId:0 andIsDebug:[BNCPreferenceHelper isDebug]];
    [[[systemObserverMock stub] andReturnValue:AD_TRACKING_SAFE] adTrackingSafe];
    [[[systemObserverMock stub] andReturn:BUNDLE_ID] getBundleID];
    [[[systemObserverMock stub] andReturn:APP_VERSION] getAppVersion];
    [[[systemObserverMock stub] andReturn:OS] getOS];
    [[[systemObserverMock stub] andReturn:OS_VERSION] getOSVersion];
    [[[systemObserverMock stub] andReturn:URI_SCHEME] getDefaultUriScheme];
    [[[systemObserverMock stub] andReturn:UPDATE_STATE] getUpdateState];
    [[[systemObserverMock stub] andReturn:CARRIER] getCarrier];
    [[[systemObserverMock stub] andReturn:BRAND] getBrand];
    [[[systemObserverMock stub] andReturn:MODEL] getModel];
    [[[systemObserverMock stub] andReturn:SCREEN_WIDTH] getScreenWidth];
    [[[systemObserverMock stub] andReturn:SCREEN_HEIGHT] getScreenHeight];
    
    id preferenceMock = OCMClassMock([BNCPreferenceHelper class]);
    [[[preferenceMock stub] andReturnValue:IS_REFERRABLE] getIsReferrable];
    [[[preferenceMock stub] andReturnValue:IS_DEBUG] isDebug];
    [[[preferenceMock stub] andReturn:LINK_IDENTIFIER] getLinkClickIdentifier];
    
    NSDictionary * const EXPECTED_PARAMS = @{
        BRANCH_REQUEST_KEY_AD_TRACKING_ENABLED: AD_TRACKING_SAFE,
        BRANCH_REQUEST_KEY_APP_VERSION: APP_VERSION,
        BRANCH_REQUEST_KEY_DEBUG: IS_DEBUG,
        BRANCH_REQUEST_KEY_HARDWARE_ID: HARDWARE_ID,
        BRANCH_REQUEST_KEY_BUNDLE_ID: BUNDLE_ID,
        BRANCH_REQUEST_KEY_IS_HARDWARE_ID_REAL: @NO,
        BRANCH_REQUEST_KEY_IS_REFERRABLE: IS_REFERRABLE,
        BRANCH_REQUEST_KEY_LINK_IDENTIFIER: LINK_IDENTIFIER,
        BRANCH_REQUEST_KEY_OS: OS,
        BRANCH_REQUEST_KEY_OS_VERSION: OS_VERSION,
        BRANCH_REQUEST_KEY_UPDATE: UPDATE_STATE,
        BRANCH_REQUEST_KEY_URI_SCHEME: URI_SCHEME,
        BRANCH_REQUEST_KEY_CARRIER: CARRIER,
        BRANCH_REQUEST_KEY_BRAND: BRAND,
        BRANCH_REQUEST_KEY_MODEL: MODEL,
        BRANCH_REQUEST_KEY_SCREEN_WIDTH: SCREEN_WIDTH,
        BRANCH_REQUEST_KEY_SCREEN_HEIGHT: SCREEN_HEIGHT
    };
    
    BranchInstallRequest *request = [[BranchInstallRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:EXPECTED_PARAMS url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testSuccessWithAllKeysAndIsReferrable {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const IDENTITY = @"branch-id";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };
    
    [BNCPreferenceHelper setIsReferrable];
    [BNCPreferenceHelper setInstallParams:INSTALL_PARAMS];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getDeviceFingerprintID], FINGERPRINT_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], DEVELOPER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionParams], SESSION_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], SESSION_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], IDENTITY);
    XCTAssertNil([BNCPreferenceHelper getLinkClickIdentifier]);
}

- (void)testSuccessWithAllKeysAndIsNotReferrable {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"foo\":\"bar\"}";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_SESSION_DATA: SESSION_PARAMS,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };
    
    [BNCPreferenceHelper clearIsReferrable];
    [BNCPreferenceHelper setInstallParams:INSTALL_PARAMS];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getDeviceFingerprintID], FINGERPRINT_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], DEVELOPER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionParams], SESSION_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], INSTALL_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], IDENTITY);
    XCTAssertNil([BNCPreferenceHelper getLinkClickIdentifier]);
}

- (void)testSuccessWithNoSessionParamsAndIsNotReferrable {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };
    
    [BNCPreferenceHelper clearIsReferrable];
    [BNCPreferenceHelper setInstallParams:INSTALL_PARAMS];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getDeviceFingerprintID], FINGERPRINT_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], DEVELOPER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], INSTALL_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], IDENTITY);
    XCTAssertNil([BNCPreferenceHelper getSessionParams]);
    XCTAssertNil([BNCPreferenceHelper getLinkClickIdentifier]);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsNotSet {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };
    
    [BNCPreferenceHelper setIsReferrable];
    [BNCPreferenceHelper setInstallParams:INSTALL_PARAMS];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getDeviceFingerprintID], FINGERPRINT_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], DEVELOPER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getInstallParams], INSTALL_PARAMS);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], IDENTITY);
    XCTAssertNil([BNCPreferenceHelper getSessionParams]);
    XCTAssertNil([BNCPreferenceHelper getLinkClickIdentifier]);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsSet {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const INSTALL_PARAMS = @"{\"bar\":\"foo\"}";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };
    
    [BNCPreferenceHelper setIsReferrable];
    [BNCPreferenceHelper setInstallParams:INSTALL_PARAMS];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } allowInstallParamsToBeCleared:YES];
    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects([BNCPreferenceHelper getDeviceFingerprintID], FINGERPRINT_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserURL], USER_URL);
    XCTAssertEqualObjects([BNCPreferenceHelper getUserIdentity], DEVELOPER_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getSessionID], SESSION_ID);
    XCTAssertEqualObjects([BNCPreferenceHelper getIdentityID], IDENTITY);
    XCTAssertNil([BNCPreferenceHelper getSessionParams]);
    XCTAssertNil([BNCPreferenceHelper getLinkClickIdentifier]);
    XCTAssertNil([BNCPreferenceHelper getInstallParams]);
}

@end

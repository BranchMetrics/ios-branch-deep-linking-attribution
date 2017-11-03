//
//  BranchInstallRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/24/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "Branch.h"
#import "BranchInstallRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"
#import "BranchConstants.h"
#import <OCMock/OCMock.h>

@interface BranchInstallRequestTests : BNCTestCase
@end

@implementation BranchInstallRequestTests

- (void)setUp {
    [super setUp];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.installParams = nil;
    preferenceHelper.identityID = nil;
    preferenceHelper.checkedAppleSearchAdAttribution = NO;
    [preferenceHelper saveContentAnalyticsManifest:nil];
    [preferenceHelper synchronize];
}

- (void)testRequestBody {
    NSString * const HARDWARE_ID = @"foo-hardware-id";
    NSNumber * const AD_TRACKING_SAFE = @YES;
    NSString * const BUNDLE_ID = @"foo-bundle-id";
    NSString * const APP_VERSION = @"foo-app-version";
    NSString * const OS = @"foo-os";
    NSString * const OS_VERSION = @"foo-os-version";
    NSString * const URI_SCHEME = @"foo-uri-scheme";
    NSNumber * const UPDATE_STATE = @1;
    NSString * const LINK_IDENTIFIER = @"foo-link-id";
    NSString * const BRAND = @"foo-brand";
    NSString * const MODEL = @"foo-model";
    NSNumber * const SCREEN_WIDTH = @1;
    NSNumber * const SCREEN_HEIGHT = @2;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.identityID = nil;
    preferenceHelper.isDebug = YES;
    preferenceHelper.linkClickIdentifier = LINK_IDENTIFIER;
    
    id systemObserverMock = OCMClassMock([BNCSystemObserver class]);
    [[[[systemObserverMock stub]
        ignoringNonObjectArgs]
        andReturn:HARDWARE_ID]
            getUniqueHardwareId:0
            isDebug:YES
            andType:nil];
    [[[systemObserverMock stub] andReturnValue:AD_TRACKING_SAFE] adTrackingSafe];
    [[[systemObserverMock stub] andReturn:BUNDLE_ID] getBundleID];
    [[[systemObserverMock stub] andReturn:APP_VERSION] getAppVersion];
    [[[systemObserverMock stub] andReturn:OS] getOS];
    [[[systemObserverMock stub] andReturn:OS_VERSION] getOSVersion];
    [[[systemObserverMock stub] andReturn:URI_SCHEME] getDefaultUriScheme];
    [[[systemObserverMock stub] andReturn:UPDATE_STATE] getUpdateState];
    [[[systemObserverMock stub] andReturn:BRAND] getBrand];
    [[[systemObserverMock stub] andReturn:MODEL] getModel];
    [[[systemObserverMock stub] andReturn:SCREEN_WIDTH] getScreenWidth];
    [[[systemObserverMock stub] andReturn:SCREEN_HEIGHT] getScreenHeight];

    NSDictionary *expectedParams = @{
        @"app_version":                 @"foo-app-version",
        @"apple_ad_attribution_checked":@0,
        @"debug":                       @1,
        @"facebook_app_link_checked":   @0,
        @"ios_bundle_id":               @"foo-bundle-id",
        @"link_identifier":             @"foo-link-id",
        @"update":                      @1,
        @"uri_scheme":                  @"foo-uri-scheme"
    };

    BranchInstallRequest *request = [[BranchInstallRequest alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
		postRequest:expectedParams
		url:[self stringMatchingPattern:BRANCH_REQUEST_ENDPOINT_INSTALL]
		key:[OCMArg any]
		callback:[OCMArg any]];

    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    [serverInterfaceMock verify];
}

- (void)testSuccessWithAllKeysAndIsReferrable {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const SESSION_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
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

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    [request processResponse:response error:nil];
    [self awaitExpectations];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    XCTAssertEqualObjects(preferenceHelper.deviceFingerprintID, FINGERPRINT_ID);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.identityID, IDENTITY);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
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
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];    
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.deviceFingerprintID, FINGERPRINT_ID);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionParams, SESSION_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.identityID, IDENTITY);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
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
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    [request processResponse:response error:nil];
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.deviceFingerprintID, FINGERPRINT_ID);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.identityID, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
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
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    preferenceHelper.installParams = INSTALL_PARAMS;
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    [request processResponse:response error:nil];
    [self awaitExpectations];
    
    XCTAssertEqualObjects(preferenceHelper.deviceFingerprintID, FINGERPRINT_ID);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
    XCTAssertEqualObjects(preferenceHelper.identityID, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
}

- (void)testSuccessWithNoSessionParamsAndIsReferrableAndAllowToBeClearIsSet {
    NSString * const FINGERPRINT_ID = @"foo-fingerprint";
    NSString * const USER_URL = @"http://foo";
    NSString * const DEVELOPER_ID = @"foo";
    NSString * const SESSION_ID = @"foo-session";
    NSString * const IDENTITY = @"branch-id";
    
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{
        BRANCH_RESPONSE_KEY_DEVICE_FINGERPRINT_ID: FINGERPRINT_ID,
        BRANCH_RESPONSE_KEY_USER_URL: USER_URL,
        BRANCH_RESPONSE_KEY_DEVELOPER_IDENTITY: DEVELOPER_ID,
        BRANCH_RESPONSE_KEY_SESSION_ID: SESSION_ID,
        BRANCH_RESPONSE_KEY_BRANCH_IDENTITY: IDENTITY
    };

    XCTestExpectation *openExpectation = [self expectationWithDescription:@"OpenRequest Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        XCTAssertNil(error);
        XCTAssertTrue(success);
        [self safelyFulfillExpectation:openExpectation];
    } isInstall:YES];

    [Branch setBranchKey:@"key_live_foo"];
    [request processResponse:response error:nil];
    [self awaitExpectations];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    XCTAssertEqualObjects(preferenceHelper.deviceFingerprintID, FINGERPRINT_ID);
    XCTAssertEqualObjects(preferenceHelper.userUrl, USER_URL);
    XCTAssertEqualObjects(preferenceHelper.userIdentity, DEVELOPER_ID);
    XCTAssertEqualObjects(preferenceHelper.sessionID, SESSION_ID);
    XCTAssertEqualObjects(preferenceHelper.identityID, IDENTITY);
    XCTAssertNil(preferenceHelper.sessionParams);
    XCTAssertNil(preferenceHelper.linkClickIdentifier);
    XCTAssertNil(preferenceHelper.installParams);
}

- (void)testInstallWhenReferrableAndNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    XCTestExpectation *expectation = [self expectationWithDescription:@"ReferrableInstall"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        [self safelyFulfillExpectation:expectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{};
    [request processResponse:response error:nil];
    [self awaitExpectations];
}

- (void)testInstallWhenReferrableAndNonNullData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSString * const INSTALL_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.installParams, INSTALL_PARAMS);
        
        [self safelyFulfillExpectation:expectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: INSTALL_PARAMS };
    [request processResponse:response error:nil];
    [self awaitExpectations];
}

- (void)testInstallWhenReferrableAndNoInstallParamsAndNonLinkClickData {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    
    NSString * const OPEN_PARAMS = @"{\"+clicked_branch_link\":0}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchInstallRequest *request = [[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertNil(preferenceHelper.installParams);
        
        [self safelyFulfillExpectation:expectation];
    }];

    [Branch setBranchKey:@"key_live_foo"];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: OPEN_PARAMS };
    [request processResponse:response error:nil];
    [self awaitExpectations];
}

- (void)testInstallWhenNotReferrable {
    //  'isReferrable' seems to be an empty concept in iOS.
    //  It is in the code but not used. -- Edward.

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString * const INSTALL_PARAMS = @"{\"+clicked_branch_link\":1,\"foo\":\"bar\"}";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Expectation"];
    BranchInstallRequest *request =
		[[BranchInstallRequest alloc] initWithCallback:^(BOOL changed, NSError *error) {
        	XCTAssertNil(error);
        	XCTAssert([preferenceHelper.installParams isEqualToString:INSTALL_PARAMS]);
        	[self safelyFulfillExpectation:expectation];
    		}];

    [Branch setBranchKey:@"key_live_foo"];
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.data = @{ BRANCH_RESPONSE_KEY_SESSION_DATA: INSTALL_PARAMS };
    [request processResponse:response error:nil];
    
    [self awaitExpectations];
}

@end

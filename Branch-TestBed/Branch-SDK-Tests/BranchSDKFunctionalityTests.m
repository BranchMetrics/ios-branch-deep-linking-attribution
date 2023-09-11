//
//  Branch_SDK_test.m
//  Branch-SDK test
//
//  Created by Qinwei Gong on 2/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "Branch.h"

NSString * const TEST_RANDOMIZED_DEVICE_TOKEN = @"94938498586381084";
NSString * const TEST_RANDOMIZED_BUNDLE_TOKEN = @"95765863201768032";
NSString * const TEST_SESSION_ID = @"97141055400444225";
NSString * const TEST_IDENTITY_LINK = @"https://bnc.lt/i/3N-xr0E-_M";
NSString * const TEST_NEW_USER_LINK = @"https://bnc.lt/i/2kkbX6k-As";

@interface BranchSDKFunctionalityTests : BNCTestCase
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end

@implementation BranchSDKFunctionalityTests

- (void)test00OpenOrInstall {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    Branch.branchKey = @"key_live_foo";
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];
    
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"randomized_device_token": TEST_RANDOMIZED_DEVICE_TOKEN,
        @"randomized_bundle_token": TEST_RANDOMIZED_BUNDLE_TOKEN,
        @"link": TEST_IDENTITY_LINK,
        @"session_id": TEST_SESSION_ID
    };
    
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];
    
    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback(openInstallResponse, nil);
    };

    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return [url rangeOfString:@"open"].location != NSNotFound || [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect]
        andDo:openOrInstallInvocation]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:openOrInstallCallbackCheckBlock];
    
    XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];
    [branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(preferenceHelper.sessionID, TEST_SESSION_ID);
        [openExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:NULL];
}

- (void)test03GetShortURLSync {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live_foo"];

    XCTestExpectation *getShortURLExpectation = [self expectationWithDescription:@"Test getShortURL Sync"];
    [branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        BNCServerResponse *fbLinkResponse = [[BNCServerResponse alloc] init];
        fbLinkResponse.statusCode = @200;
        fbLinkResponse.data = @{ @"url": @"https://bnc.lt/l/4BGtJj-03N" };
        
        BNCServerResponse *twLinkResponse = [[BNCServerResponse alloc] init];
        twLinkResponse.statusCode = @200;
        twLinkResponse.data = @{ @"url": @"https://bnc.lt/l/-03N4BGtJj" };
        
        // FB should only be called once
        [[[serverInterfaceMock expect] andReturn:fbLinkResponse] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
        [[serverInterfaceMock reject] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"facebook"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
        // TW should be allowed still
        [[[serverInterfaceMock expect] andReturn:twLinkResponse] postRequestSynchronous:[OCMArg checkWithBlock:^BOOL(NSDictionary *params) {
            return [params[@"channel"] isEqualToString:@"twitter"];
        }] url:[preferenceHelper getAPIURL:@"url"] key:[OCMArg any]];
        
        NSString *url1 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertNotNil(url1);
        
        NSString *url2 = [branch getShortURLWithParams:nil andChannel:@"facebook" andFeature:nil];
        XCTAssertEqualObjects(url1, url2);
        
        NSString *url3 = [branch getShortURLWithParams:nil andChannel:@"twitter" andFeature:nil];
        XCTAssertNotNil(url3);
        XCTAssertNotEqualObjects(url1, url3);
        
        [self safelyFulfillExpectation:getShortURLExpectation];
    }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
}

// Test scenario
// * Initialize the session
// * Get a short url.
// * Log out.
// * Get the same url:  should be the same.
- (void)test13GetShortURLAfterLogout {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [self setupDefaultStubsForServerInterfaceMock:serverInterfaceMock];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    Branch *branch =
		[[Branch alloc]
			initWithInterface:serverInterfaceMock
			queue:[[BNCServerRequestQueue alloc] init]
			cache:[[BNCLinkCache alloc] init]
			preferenceHelper:preferenceHelper
			key:@"key_live_foo"];

    // Init session

    XCTestExpectation *initSessionExpectation =
        [self expectationWithDescription:@"Expect Session"];
    
    [branch initSessionWithLaunchOptions:@{}
              andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
                XCTAssert(!error);
                NSLog(@"Fullfilled 1.");
                [self safelyFulfillExpectation:initSessionExpectation];
              }];

    [self awaitExpectations];

    // Get short URL

    NSString * urlTruthString = @"https://bnc.lt/l/4BGtJj-03N";
    BNCServerResponse *urlResp = [[BNCServerResponse alloc] init];
    urlResp.statusCode = @200;
    urlResp.data = @{ @"url": urlTruthString };

    [[[serverInterfaceMock expect]
        andReturn:urlResp]
            postRequestSynchronous:[OCMArg any]
            url:[preferenceHelper getAPIURL:@"url"]
            key:[OCMArg any]];

    NSString *url1 = [branch getShortURLWithParams:nil andChannel:nil andFeature:nil];
    XCTAssertEqual(urlTruthString, url1);

    // Log out

    BNCServerResponse *logoutResp = [[BNCServerResponse alloc] init];
    logoutResp.data = @{ @"session_id": @"foo", @"randomized_bundle_token": @"foo", @"link": @"http://foo" };

    __block BNCServerCallback logoutCallback;
    [[[serverInterfaceMock expect]
        andDo:^(NSInvocation *invocation) {
            logoutCallback(logoutResp, nil);
        }]
            postRequest:[OCMArg any]
            url:[preferenceHelper
            getAPIURL:@"logout"]
            key:[OCMArg any]
            callback:[OCMArg
            checkWithBlock:^BOOL(BNCServerCallback callback) {
                logoutCallback = callback;
                return YES;
            }]];

    XCTestExpectation *logoutExpectation =
        [self expectationWithDescription:@"Logout Session"];

    [branch logoutWithCallback:^(BOOL changed, NSError * _Nullable error) {
        XCTAssertNil(error);
        NSLog(@"Fullfilled 2.");
        [self safelyFulfillExpectation:logoutExpectation];
    }];

    self.hasExceededExpectations = NO;
    [self awaitExpectations];

    // Get short URL

    [[[serverInterfaceMock expect]
        andReturn:urlResp]
            postRequestSynchronous:[OCMArg any]
            url:[preferenceHelper getAPIURL:@"url"]
            key:[OCMArg any]];

    NSString *url2 = [branch getShortURLWithParams:nil andChannel:nil andFeature:nil];
    XCTAssertEqualObjects(url1, url2);
}

#pragma mark - Test Utility

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    [self waitForExpectationsWithTimeout:6.0 handler:^(NSError *error) {
        self.hasExceededExpectations = YES;
    }];
}

- (void)setupDefaultStubsForServerInterfaceMock:(id)serverInterfaceMock {
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"session_id": TEST_SESSION_ID,
        @"randomized_bundle_token": TEST_RANDOMIZED_BUNDLE_TOKEN,
        @"randomized_device_token": TEST_RANDOMIZED_DEVICE_TOKEN,
    };
    
    // Stub open / install
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];
    
    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback(openInstallResponse, nil);
    };
    
    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return [url rangeOfString:@"open"].location != NSNotFound ||
               [url rangeOfString:@"install"].location != NSNotFound;
    }];
    [[[serverInterfaceMock expect]
        andDo:openOrInstallInvocation]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:openOrInstallCallbackCheckBlock];
}

@end

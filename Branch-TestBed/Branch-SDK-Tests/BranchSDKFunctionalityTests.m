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

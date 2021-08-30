//
//  BranchNetworkScenarioTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/20/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//


#import <OCMock/OCMock.h>
#import "BNCTestCase.h"
#import "Branch.h"
#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"
#import "NSError+Branch.h"
#import "BranchOpenRequest.h"


@interface Branch (Testing)
@property (strong, nonatomic) BNCServerInterface *serverInterface;
@property (assign, nonatomic) NSInteger networkCount;
@end


@interface BranchNetworkScenarioTests : BNCTestCase
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end


@implementation BranchNetworkScenarioTests

#pragma mark - Scenario 8
// Somehow, betweeen initSession and the next call, all preference items are cleared.
// Shouldn't crash in this case, but can't do much besides "you need to re-init"
- (void)testScenario8 {
    sleep(1);
    BNCPreferenceHelper *preferenceHelper = [[BNCPreferenceHelper alloc] init];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);

    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:preferenceHelper
            key:@"key_live"];

    XCTestExpectation *expecation = [self expectationWithDescription:@"Scenario8 Expectation"];
    [self initSessionExpectingSuccess:branch serverInterface:serverInterfaceMock callback:^{
        preferenceHelper.sessionID = nil;
        preferenceHelper.randomizedDeviceToken = nil;

        [branch getShortURLWithCallback:^(NSString *url, NSError *error) {
            XCTAssertNotNil(error);
            XCTAssertEqual(error.code, BNCInitError);
            [self safelyFulfillExpectation:expecation];
        }];
    }];

    [self awaitExpectations];
}

#pragma mark - Internals

- (void)initSessionExpectingSuccess:(Branch *)branch
                    serverInterface:(id)serverInterfaceMock
                           callback:(void (^)(void))callback {
    [self mockSuccesfulInit:serverInterfaceMock];
    [branch initSessionWithLaunchOptions:@{}
              andRegisterDeepLinkHandler:[self callbackExpectingSuccess:callback]];
}

- (void)initSessionExpectingFailure:(Branch *)branch
                    serverInterface:(id)serverInterfaceMock
                           callback:(void (^)(void))callback {
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];

    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback(nil, [NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    };

    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return [url rangeOfString:@"open"].location != NSNotFound || [url rangeOfString:@"install"].location != NSNotFound;
    }];

    [[[serverInterfaceMock stub]
		andDo:openOrInstallInvocation]
			postRequest:[OCMArg any]
			url:openOrInstallUrlCheckBlock
			key:[OCMArg any]
			callback:openOrInstallCallbackCheckBlock];

    [branch initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:[self callbackExpectingFailure:callback]];
}


#pragma mark - Callbacks

- (callbackWithParams)callbackExpectingSuccess:(void (^)(void))callback {
    __block BOOL initCalled = NO;
    return ^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        if (!initCalled && callback) {
            initCalled = YES;
            callback();
        }
    };
}

- (callbackWithParams)callbackExpectingFailure:(void (^)(void))callback {
    __block BOOL initCalled = NO;
    return ^(NSDictionary *params, NSError *error) {
        XCTAssertNotNil(error);

        if (!initCalled && callback) {
            initCalled = YES;
            callback();
        }
    };
}

#pragma mark - Init mocking

- (void)mockSuccesfulInit:(id)serverInterfaceMock {
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    openInstallResponse.data = @{
        @"session_id": @"11111",
        @"randomized_bundle_token": @"22222",
        @"randomized_device_token": @"ae5adt6lkj08",
        @"link": @"https://bnc.lt/i/11111"
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
        return 	[url rangeOfString:@"open"].location != NSNotFound ||
				[url rangeOfString:@"install"].location != NSNotFound;
    }];

    [[[serverInterfaceMock stub]
		andDo:openOrInstallInvocation]
			postRequest:[OCMArg any]
			url:openOrInstallUrlCheckBlock
			key:[OCMArg any]
			callback:openOrInstallCallbackCheckBlock];
}

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    NSTimeInterval timeoutInterval = 5.0;
    if ([UIDevice currentDevice].systemVersion.floatValue < 9.0) {
        timeoutInterval = 10.0;
    }
    [self waitForExpectationsWithTimeout:timeoutInterval handler:^(NSError *error) {
        self.hasExceededExpectations = YES;
    }];
}

@end

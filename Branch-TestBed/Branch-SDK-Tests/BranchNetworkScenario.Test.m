//
//  BranchNetworkScenarioTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/20/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "BNCTestCase.h"
#import <OCMock/OCMock.h>
#import "Branch.h"
#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"
#import "BNCError.h"
#import "BranchOpenRequest.h"


@interface Branch (Testing)
@property (strong, nonatomic) BNCServerInterface *bServerInterface;
@property (assign, nonatomic) NSInteger networkCount;
@end


@interface BranchNetworkScenarioTests : BNCTestCase
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end


@implementation BranchNetworkScenarioTests

#pragma mark - Scenario 1
// Connection starts good -- InitSession completes
// Connection drops
// Request is made, should fail and call callback.
// "Re Open" occurs, network is back
// InitSession should occur again
// Subsequent requests should occur as normal
- (void)testScenario1 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_live"];

    XCTestExpectation *scenario1Expectation1 =
        [self expectationWithDescription:@"Scenario1 Expectation1"];

    // Start off with a good connection
    [self initSessionExpectingSuccess:branch serverInterface:serverInterfaceMock callback:^{
        // Simulate connection drop
        // Expect failure
        [self makeFailingNonReplayableRequest:branch
            serverInterface:serverInterfaceMock callback:^{
                [self safelyFulfillExpectation:scenario1Expectation1];
        }];
    }];
    
    [self awaitExpectations];
    [self resetExpectations];

    XCTestExpectation *scenario1Expectation2 =
        [self expectationWithDescription:@"Scenario1 Expectation2"];
    
    // Simulate re-open, expect init to be called again
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationDidBecomeActiveNotification
        object:nil];
    
    // Then make another request, which should play through fine
    [self makeSuccessfulNonReplayableRequest:branch
        serverInterface:serverInterfaceMock
        callback:^{
            [self safelyFulfillExpectation:scenario1Expectation2];
        }];

    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 2
// Connection starts bad -- InitSession fails
// Connection drops
// Request is made, should fail and call callback.
// "Re Open" occurs, network is back
// InitSession should occur again
// Subsequent requests should occur as normal
- (void)testScenario2 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_foo"];

    XCTestExpectation *scenario2Expectation1 =
        [self expectationWithDescription:@"Scenario2 Expectation1"];
    
    // Start off with a bad connection
    [self initSessionExpectingFailure:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario2Expectation1];
    }];

    [self awaitExpectations];
    [serverInterfaceMock verify];    
    [self resetExpectations];

    XCTestExpectation *scenario2Expectation2 =
        [self expectationWithDescription:@"Scenario2 Expectation2"];

    // Request should fail
    [self makeFailingNonReplayableRequest:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario2Expectation2];
    }];

    [self awaitExpectations];
    [self resetExpectations];

    // Init should succeed

    // Re-mock the serverInterface so it succeeds
    serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    branch.bServerInterface = serverInterfaceMock;

    XCTestExpectation *scenario2Expectation3 =
        [self expectationWithDescription:@"Scenario2 Expectation3"];
    [self initSessionExpectingSuccess:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario2Expectation3];
    }];

    [self awaitExpectations];
    [self resetExpectations];

    XCTestExpectation *scenario2Expectation4 =
        [self expectationWithDescription:@"Scenario2 Expectation4"];
    
    // Then make another request, which should play through fine
    [self makeSuccessfulNonReplayableRequest:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario2Expectation4];
    }];

    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 3
// Connection starts good -- InitSession completes
// Connection drops
// Request is made, should fail and call callback.
// Without closing the app (no re-open event to kick off InitSession), connection returns
// Subsequent requests should occur as normal
- (void)testScenario3 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_foo"];

    XCTestExpectation *scenario3Expectation1 =
        [self expectationWithDescription:@"Scenario3 Expectation1"];
    
    // Start off with a good connection
    [self initSessionExpectingSuccess:branch
        serverInterface:serverInterfaceMock callback:^{
            // Simulate connection drop
            // Expect failure
            [self makeFailingNonReplayableRequest:branch
                serverInterface:serverInterfaceMock callback:^{
                    [self safelyFulfillExpectation:scenario3Expectation1];
                }];
        }];

    [self awaitExpectations];
    [self resetExpectations];
    
    XCTestExpectation *scenario3Expectation2 =
        [self expectationWithDescription:@"Scenario3 Expectation2"];
    
    // Simulate network return, shouldn't call init!
    [serverInterfaceMock stopMocking];
    
    // Request should just work
    [self makeSuccessfulNonReplayableRequest:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario3Expectation2];
    }];

    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 4
// Connection starts bad -- InitSession fails
// Connection drops
// Request is made, should fail and call callback.
// Without closing the app (no re-open event to kick off InitSession), connection returns
// Subsequent requests should cause an InitSession, which should succeed
// Request should complete as normal
- (void)testScenario4 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_foo"];
    
    XCTestExpectation *scenario4Expectation1 =
        [self expectationWithDescription:@"Scenario4 Expectation1"];
    
    // Start off with a bad connection
    [self initSessionExpectingFailure:branch
        serverInterface:serverInterfaceMock callback:^{
            [self safelyFulfillExpectation:scenario4Expectation1];
        }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
    [self resetExpectations];
    
    XCTestExpectation *scenario4Expectation2 =
        [self expectationWithDescription:@"Scenario4 Expectation2"];
    
    // Request should fail
    [self makeFailingNonReplayableRequest:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario4Expectation2];
    }];
    
    [self awaitExpectations];
    [self resetExpectations];
    
    XCTestExpectation *scenario4Expectation3 =
        [self expectationWithDescription:@"Scenario4 Expectation3"];
    
    // Simulate network return, shouldn't call init!
    //[serverInterfaceMock stopMocking];
    serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    branch.bServerInterface = serverInterfaceMock;

    // However, making another request when not initialized should make an init
    [self mockSuccesfulInit:serverInterfaceMock];
    [self overrideBranch:branch initHandler:[self callbackExpectingSuccess:NULL]];
    
    [self makeSuccessfulNonReplayableRequest:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario4Expectation3];
    }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 5

// Connection starts good -- InitSession completes
// Branch goes down
// Two requests are enqueued
// First request fails, second request should be cascade failed
- (void)testScenario5 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_live"];
    
    XCTestExpectation *scenario5Expectation1 =
        [self expectationWithDescription:@"Scenario5 Expectation1"];
    
    // Start off with a good connection
    [self initSessionExpectingSuccess:branch serverInterface:serverInterfaceMock callback:^{
        [self safelyFulfillExpectation:scenario5Expectation1];
    }];
    
    [self awaitExpectations];
    [self resetExpectations];
    
    XCTestExpectation *scenario5Expectation2 =
        [self expectationWithDescription:@"Scenario5 Expectation2"];

    [self enqueueTwoNonReplayableRequestsWithFirstFailingBecauseBranchIsDown:branch
        serverInterface:serverInterfaceMock
        callback:^{
            [self safelyFulfillExpectation:scenario5Expectation2];
        }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 6
// Connection starts good -- InitSession completes
// Two requests are enqueued
// First request fails because of a 400 (bad request), second request should not be affected
- (void)testScenario6 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:[[BNCServerRequestQueue alloc] init]
            cache:[[BNCLinkCache alloc] init]
            preferenceHelper:[BNCPreferenceHelper preferenceHelper]
            key:@"key_live"];
    
    XCTestExpectation *scenario6Expectation1 =
        [self expectationWithDescription:@"Scenario6 Expectation1"];
    
    // Start off with a good connection
    [self initSessionExpectingSuccess:branch
        serverInterface:serverInterfaceMock
        callback:^{
            [self safelyFulfillExpectation:scenario6Expectation1];
        }];
    
    [self awaitExpectations];
    [self resetExpectations];
    
    XCTestExpectation *scenario6Expectation2 =
        [self expectationWithDescription:@"Scenario6 Expectation2"];

    [self enqueueTwoNonReplayableRequestsWithFirstFailingBecauseRequestIsBad:branch
        serverInterface:serverInterfaceMock
        callback:^{
            [self safelyFulfillExpectation:scenario6Expectation2];
        }];
    
    [self awaitExpectations];
    [serverInterfaceMock verify];
}

#pragma mark - Scenario 7

#if 0
// This test is no longer valid.  We remove pending opens.  And the test is written wrong.
// --EBS
//
// While an Open / Install request is pending, the app is killed, causing the callback to be lost.
// When InitSession is called again (next launch), the request should still complete.
- (void)testScenario7 {
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    id queueMock = OCMClassMock([BNCServerRequestQueue class]);
    
    // Ugly server interface set up
    __block BNCServerCallback openOrInstallCallback;
    id openOrInstallCallbackCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        openOrInstallCallback = callback;
        return YES;
    }];
    
    id openOrInstallInvocation = ^(NSInvocation *invocation) {
        openOrInstallCallback([[BNCServerResponse alloc] init], nil);
    };
    
    id openOrInstallUrlCheckBlock = [OCMArg checkWithBlock:^BOOL(NSString *url) {
        return
            [url rangeOfString:@"open"].location != NSNotFound ||
            [url rangeOfString:@"install"].location != NSNotFound;
    }];
    
    // Ignore first request, don't call callback (simulate failure)
    [[serverInterfaceMock expect]
        postRequest:[OCMArg any]
        url:openOrInstallUrlCheckBlock
        key:[OCMArg any]
        callback:[OCMArg any]];

    // Second request execute as normal
    [[[serverInterfaceMock expect]
		andDo:openOrInstallInvocation]
			postRequest:[OCMArg any]
			url:openOrInstallUrlCheckBlock
			key:[OCMArg any]
			callback:openOrInstallCallbackCheckBlock];
    
    // Queue mocking. Request should only be inserted once
    id openRequestCheck = [OCMArg checkWithBlock:^BOOL(BNCServerRequest *request) {
        if ([request isKindOfClass:[BranchOpenRequest class]]) {
            BranchOpenRequest *openRequest = (BranchOpenRequest *)request;
            openRequest.callback = nil;
            [[[queueMock stub] andReturn:request] peek];
            [[[queueMock stub] andReturn:openRequest] moveInstallOrOpenToFront:0];
            return YES;
        }
        return NO;
    }];

    [[queueMock expect] insert:openRequestCheck at:0];
    [[queueMock reject] insert:openRequestCheck at:0];
    
    [[[queueMock expect] andReturnValue:@NO] containsInstallOrOpen];
    [[[queueMock expect] andReturnValue:@YES] containsInstallOrOpen];
    [(BNCServerRequestQueue *)[[queueMock stub] andReturnValue:@1] size];
    
    Branch *branch =
        [[Branch alloc]
            initWithInterface:serverInterfaceMock
            queue:queueMock
            cache:nil
            preferenceHelper:nil
            key:@"key_live"];
    
    __block NSInteger initCallbackCount = 0;
    [branch initSessionWithLaunchOptions:@{}
        andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            initCallbackCount++;
        }];

    // Override Branch network requests by setting internals *shudder*
    branch.networkCount = 0;

    XCTestExpectation *initExpectation = [self expectationWithDescription:@"Init expectation"];
    [branch initSessionWithLaunchOptions:@{}
        andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            initCallbackCount++;
            [self safelyFulfillExpectation:initExpectation];
        }];
    
    [self awaitExpectations];
    XCTAssertEqual(initCallbackCount, 1);
}
#endif

#pragma mark - Scenario 8
// Somehow, betweeen initSession and the next call, all preference items are cleared.
// Shouldn't crash in this case, but can't do much besides "you need to re-init"
- (void)testScenario8 {
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
        preferenceHelper.deviceFingerprintID = nil;
        
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

- (void)makeFailingNonReplayableRequest:(Branch *)branch
                        serverInterface:(id)serverInterfaceMock
                               callback:(void (^)(void))callback {

    __block BNCServerCallback badRequestCallback;
    id badRequestCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        badRequestCallback = callback;
        return YES;
    }];
    
    id badRequestInvocation = ^(NSInvocation *invocation) {
        badRequestCallback(nil, [NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *url = [[preferenceHelper getAPIURL:@"credits/"]
        stringByAppendingString:preferenceHelper.identityID];

    [[[serverInterfaceMock expect]
        andDo:badRequestInvocation]
            getRequest:[OCMArg any]
            url:url
            key:[OCMArg any]
            callback:badRequestCheckBlock];

    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        callback();
    }];
}

- (void)enqueueTwoNonReplayableRequestsWithFirstFailingBecauseBranchIsDown:(Branch *)branch
        serverInterface:(id)serverInterfaceMock
        callback:(void (^)(void))callback {

    __block BNCServerCallback badRequestCallback = nil;
    id badRequestCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        @synchronized (self) {
            badRequestCallback = callback;
            return YES;
        }
    }];
    
    // Only one request should make it to the server
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *url =
        [[preferenceHelper getAPIURL:@"credits/"]
            stringByAppendingString:preferenceHelper.identityID];

    [[serverInterfaceMock expect]
        getRequest:[OCMArg any]
        url:url
        key:[OCMArg any]
        callback:badRequestCheckBlock];

    [[serverInterfaceMock reject]
        getRequest:[OCMArg any]
        url:url
        key:[OCMArg any]
        callback:[OCMArg any]];

    XCTestExpectation *enqueueTwoExpectation =
        [self expectationWithDescription:@"EnqueueTwo Expectation"];

    // Throw two requests in the queue, but the first failing w/ a 500 should trigger both to fail

    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        [self safelyFulfillExpectation:enqueueTwoExpectation];
    }];

    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        callback();
    }];

    sleep(1); // Sleep to allow server queue time to process.
    // Bad requests callback should be captured at this point, call it to trigger the failure.

    @synchronized (self) {
        if (badRequestCallback) {
            NSError * error = [NSError errorWithDomain:BNCErrorDomain code:BNCServerProblemError userInfo:nil];
            badRequestCallback(nil, error);
        } else {
            XCTAssert(badRequestCallback);
        }
    }
}

- (void)enqueueTwoNonReplayableRequestsWithFirstFailingBecauseRequestIsBad:(Branch *)branch
		serverInterface:(id)serverInterfaceMock
		callback:(void (^)(void))testCaseCallback {

    __block int callNumber = 0;
    __block BNCServerCallback badRequestCallback = nil;
    __block BNCServerCallback goodRequestCallback = nil;
    id requestCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        @synchronized (self) {
            callNumber++;
            if (callNumber == 1)
                badRequestCallback = callback;
            else if (callNumber == 2)
                goodRequestCallback = callback;
            else
                XCTFail(@"Bad callNumber %d.", callNumber);
            NSLog(@"Call number %d.", callNumber);
            return YES;
        }
    }];
    
    // Only one request should make it to the server
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *url =
        [[preferenceHelper getAPIURL:@"credits/"]
            stringByAppendingString:preferenceHelper.identityID];
    [[serverInterfaceMock expect]
        getRequest:[OCMArg any]
        url:url
        key:[OCMArg any]
        callback:requestCheckBlock];

    // Throw two requests in the queue, but the first failing w/ a 500 should trigger both to fail
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        [[serverInterfaceMock expect]
            getRequest:[OCMArg any]
            url:url
            key:[OCMArg any]
            callback:requestCheckBlock];
    }];
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        testCaseCallback();
    }];

    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    while ([timeoutDate timeIntervalSinceNow] > 0.0) {

        sleep(1); // Sleep so that network queue can processes
        @synchronized (self) {
            if (badRequestCallback) {
                badRequestCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCBadRequestError userInfo:nil]);
                badRequestCallback = nil;
            } else if (goodRequestCallback) {
                goodRequestCallback([[BNCServerResponse alloc] init], nil);
                goodRequestCallback = nil;
                return;
            }
        }
    }
	XCTAssert(badRequestCallback && goodRequestCallback);
}

- (void)makeSuccessfulNonReplayableRequest:(Branch *)branch
                           serverInterface:(id)serverInterfaceMock
                                  callback:(void (^)(void))callback {

    BNCServerResponse *goodResponse = [[BNCServerResponse alloc] init];
    goodResponse.statusCode = @200;
    
    __block BNCServerCallback goodRequestCallback;
    id goodRequestCheckBlock = [OCMArg checkWithBlock:^BOOL(BNCServerCallback callback) {
        goodRequestCallback = callback;
        return YES;
    }];
    
    id goodRequestInvocation = ^(NSInvocation *invocation) {
        goodRequestCallback(goodResponse, nil);
    };
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *url = [[preferenceHelper getAPIURL:@"credits/"]
        stringByAppendingString:preferenceHelper.identityID];

    [[[serverInterfaceMock expect]
        andDo:goodRequestInvocation]
            getRequest:[OCMArg any]
            url:url
            key:[OCMArg any]
            callback:goodRequestCheckBlock];

    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        callback();
    }];
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
        @"identity_id": @"22222",
        @"device_fingerprint_id": @"ae5adt6lkj08",
        @"browser_fingerprint_id": @"ae5adt6lkj08",
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

- (void)overrideBranch:(Branch *)branch initHandler:(callbackWithParams)initHandler {
    // Override Branch init by setting internals *shudder*
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    [branch performSelector:@selector(setSessionInitWithParamsCallback:) withObject:initHandler];
    #pragma clang diagnostic pop
}

- (NSData *)openResponseData {
    NSDictionary *openResponseDict = @{
        @"session_id": @"112263020234678596",
        @"identity_id": @"98687515069776101",
        @"device_fingerprint_id": @"94938498586381084",
        @"browser_fingerprint_id": [NSNull null],
        @"link": @"https://bnc.lt/i/3SawKbU-1Z",
        @"new_identity_id": @"98687515069776101",
        @"identity": @"test_user_10"
    };
    
    return [NSJSONSerialization dataWithJSONObject:openResponseDict options:kNilOptions error:nil];
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

//
//  BranchNetworkScenarioTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/20/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Nocilla/Nocilla.h>
#import "Branch.h"
#import "BNCServerRequestQueue.h"
#import "BNCPreferenceHelper.h"

@interface BranchNetworkScenarioTests : XCTestCase

@end

@implementation BranchNetworkScenarioTests

+ (void)setUp {
    [super setUp];
    
    [[BNCServerRequestQueue getInstance] clearQueue];
    [[LSNocilla sharedInstance] start];
}

+ (void)tearDown {
    [[LSNocilla sharedInstance] stop];

    [super tearDown];
}

- (void)setUp {
    [super setUp];

    stubRequest(@"POST", @"v1/applist".regex).andReturn(200);
    stubRequest(@"GET", @"v1/applist".regex).andReturn(200);

    [BNCPreferenceHelper clearDebug];
}

- (void)tearDown {
    // Fake re-init by setting internals *shudder*
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    BOOL isInitialized = NO;
    NSMethodSignature *signature = [[Branch class] instanceMethodSignatureForSelector:@selector(setIsInitialized:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:branch];
    [invocation setSelector:@selector(setIsInitialized:)];
    [invocation setArgument:&isInitialized atIndex:2];
    [invocation invoke];
#pragma clang diagnostic pop

    [[LSNocilla sharedInstance] clearStubs];

    [super tearDown];
}


#pragma mark - Scenario 1

// Connection starts good -- InitSession completes
// Connection drops
// Request is made, should fail and call callback.
// "Re Open" occurs, network is back
// InitSession should occur again
// Subsequent requests should occur as normal
- (void)testScenario1 {
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    
    XCTestExpectation *scenario1Expectation = [self expectationWithDescription:@"Scenario1 Expectation"];

    // Start off with a good connection
    [self initSessionExpectingSuccess:branch callback:^{
        // Simulate connection drop
        [[LSNocilla sharedInstance] clearStubs];

        // Expect failure
        [self makeFailingNonReplayableRequest:branch callback:^{

            // Simulate re-open, expect init to be called again
            [[LSNocilla sharedInstance] clearStubs];
            stubRequest(@"POST", @"v1/open".regex).andReturn(200).withBody([self openResponseData]);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
            
            // Then make another request, which should play through fine
            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario1Expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
}


#pragma mark - Scenario 2

// Connection starts bad -- InitSession fails
// Connection drops
// Request is made, should fail and call callback.
// "Re Open" occurs, network is back
// InitSession should occur again
// Subsequent requests should occur as normal
- (void)testScenario2 {
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    
    XCTestExpectation *scenario2Expectation = [self expectationWithDescription:@"Scenario2 Expectation"];
    
    // Start off with a bad connection
    [self initSessionExpectingFailure:branch callback:^{

        // Request should fail
        [self makeFailingNonReplayableRequest:branch callback:^{

            // Simulate re-open, expect init to be called again
            [[LSNocilla sharedInstance] clearStubs];
            stubRequest(@"POST", @"v1/open".regex).andReturn(200).withBody([self openResponseData]);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
            [self overrideBranchInitHandler:[self callbackExpectingSuccess:NULL]];

            // Then make another request, which should play through fine
            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario2Expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
}


#pragma mark - Scenario 3

// Connection starts good -- InitSession completes
// Connection drops
// Request is made, should fail and call callback.
// Without closing the app (no re-open event to kick off InitSession), connection returns
// Subsequent requests should occur as normal
- (void)testScenario3 {
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    
    XCTestExpectation *scenario3Expectation = [self expectationWithDescription:@"Scenario3 Expectation"];
    
    // Start off with a good connection
    [self initSessionExpectingSuccess:branch callback:^{
        // Simulate connection drop
        [[LSNocilla sharedInstance] clearStubs];
        
        // Expect failure
        [self makeFailingNonReplayableRequest:branch callback:^{
            
            // Simulate network return, shouldn't call init!
            [[LSNocilla sharedInstance] clearStubs];
            
            // Request should just work
            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario3Expectation fulfill];
            }];
        }];
    }];

    [self waitForExpectationsWithTimeout:3 handler:NULL];
}


#pragma mark - Scenario 4

// Connection starts bad -- InitSession fails
// Connection drops
// Request is made, should fail and call callback.
// Without closing the app (no re-open event to kick off InitSession), connection returns
// Subsequent requests should cause an InitSession, which should succeed
// Request should complete as normal
- (void)testScenario4 {
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    
    XCTestExpectation *scenario4Expectation = [self expectationWithDescription:@"Scenario4 Expectation"];
    
    // Start off with a bad connection
    [self initSessionExpectingFailure:branch callback:^{
        
        // Request should fail
        [self makeFailingNonReplayableRequest:branch callback:^{
            
            // Simulate network return, shouldn't call init!
            [[LSNocilla sharedInstance] clearStubs];
            
            // However, making another request when not initialized should make an init
            stubRequest(@"POST", @"v1/open".regex).andReturn(200).withBody([self openResponseData]);
            [self overrideBranchInitHandler:[self callbackExpectingSuccess:NULL]];
            
            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario4Expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:NULL];
}


#pragma mark - Internals


- (void)initSessionExpectingSuccess:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"POST", @"v1/(open|install)".regex).andReturn(200).withBody([self openResponseData]);
    
    [branch initSessionAndRegisterDeepLinkHandler:[self callbackExpectingSuccess:callback]];
}

- (void)initSessionExpectingFailure:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"POST", @"v1/(open|install)".regex).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    
    [branch initSessionAndRegisterDeepLinkHandler:[self callbackExpectingFailure:callback]];
}

- (void)makeFailingNonReplayableRequest:(Branch *)branch callback:(void (^)(void))callback {
    stubRequest(@"GET", @"v1/referrals".regex).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    
    [branch loadActionCountsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        callback();
    }];
}

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

- (void)makeSuccessfulNonReplayableRequest:(Branch *)branch callback:(void (^)(void))callback {
    stubRequest(@"GET", @"v1/referrals".regex).andReturn(200);
    
    // Make a request, should succeed
    [branch loadActionCountsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        callback();
    }];
}

- (void)overrideBranchInitHandler:(callbackWithParams)initHandler {
    // Override Branch init by setting internals *shudder*
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
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

@end

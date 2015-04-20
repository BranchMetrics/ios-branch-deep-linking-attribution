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
    stubRequest(@"POST", @"v1/applist".regex).andReturn(200);
    stubRequest(@"GET", @"v1/applist".regex).andReturn(200);
    stubRequest(@"POST", @"v1/close".regex).andReturn(200);

    [BNCPreferenceHelper clearDebug];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false); // Wait for close to complete

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
    NSLog(@"starting scenario 1");
    Branch *branch = [Branch getInstance:@"key_live_jbgnjxvlhSb6PGH23BhO4hiflcp3y8kx"];
    
    XCTestExpectation *scenario1Expectation = [self expectationWithDescription:@"Scenario1 Expectation"];

    // Start off with a good connection
    [self initSessionExpectingSuccess:branch callback:^{
        // Connection drops
        [self makeFailingNonReplayableRequest:branch callback:^{
            // Simulate re-open, expect init to be called again
            [[LSNocilla sharedInstance] clearStubs];
            stubRequest(@"POST", @"v1/open".regex).andReturn(200).withBody([self openResponseData]);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];

            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario1Expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:NULL];
}


#pragma mark - Scenario 2

// Connection starts bad -- InitSession fails
// Connection drops
// Request is made, should fail and call callback.
// "Re Open" occurs, network is back
// InitSession should occur again
// Subsequent requests should occur as normal
- (void)testScenario2 {
    NSLog(@"starting scenario 2");
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
            
            [self makeSuccessfulNonReplayableRequest:branch callback:^{
                [scenario2Expectation fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:NULL];
}


#pragma mark - Internals


- (void)initSessionExpectingSuccess:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"POST", @"v1/(open|install)".regex).andReturn(200).withBody([self openResponseData]);
    
    __block BOOL initCalled = NO;
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNil(error);
        
        if (!initCalled) {
            initCalled = YES;
            callback();
        }
    }];
}

- (void)initSessionExpectingFailure:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"POST", @"v1/(open|install)".regex).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    
    __block BOOL initCalled = NO;
    [branch initSessionAndRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
        XCTAssertNotNil(error);
        
        if (!initCalled) {
            initCalled = YES;
            callback();
        }
    }];
}

- (void)makeFailingNonReplayableRequest:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"GET", @"v1/referrals".regex).andFailWithError([NSError errorWithDomain:NSURLErrorDomain code:-1004 userInfo:nil]);
    
    [branch loadActionCountsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNotNil(error);
        callback();
    }];
}

- (void)makeSuccessfulNonReplayableRequest:(Branch *)branch callback:(void (^)(void))callback {
    [[LSNocilla sharedInstance] clearStubs];
    stubRequest(@"GET", @"v1/referrals".regex).andReturn(200);
    
    // Make a request, should succeed
    [branch loadActionCountsWithCallback:^(BOOL changed, NSError *error) {
        XCTAssertNil(error);
        callback();
    }];
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

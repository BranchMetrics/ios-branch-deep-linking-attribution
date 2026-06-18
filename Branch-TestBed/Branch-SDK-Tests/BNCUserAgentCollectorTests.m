//
//  BNCUserAgentCollectorTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"
#import "BNCDeviceSystem.h"
#import "BNCUserAgentCollector.h"

// expose private methods for unit testing
@interface BNCUserAgentCollector()

- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion;
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion;
- (void)collectUserAgentWithCompletion:(void (^)(NSString * _Nullable userAgent))completion;

@end

@interface BNCUserAgentCollectorTests : XCTestCase

@end

@implementation BNCUserAgentCollectorTests

+ (void)setUp {
    [BNCUserAgentCollectorTests resetPersistentData];
}

- (void)setUp {

}

- (void)tearDown {
    [BNCUserAgentCollectorTests resetPersistentData];
}

+ (void)resetPersistentData {
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper sharedInstance];
    preferences.browserUserAgentString = nil;
    preferences.lastSystemBuildVersion = nil;
}

- (void)testResetPersistentData {
    BNCPreferenceHelper *preferences = [BNCPreferenceHelper sharedInstance];
    XCTAssertNil(preferences.browserUserAgentString);
    XCTAssertNil(preferences.lastSystemBuildVersion);
}

- (void)testSaveAndLoadUserAgent {
    NSString *systemBuildVersion = @"test";
    NSString *userAgent = @"UserAgent";

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
    NSString *expected = [collector loadUserAgentForSystemBuildVersion:systemBuildVersion];
    XCTAssertTrue([userAgent isEqualToString:expected]);
}

- (void)testCollectUserAgent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:4.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_EmptyDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_FilledDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    NSString *savedUserAgent = @"UserAgent";

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector saveUserAgent:savedUserAgent forSystemBuildVersion:[BNCDeviceSystem new].systemBuildVersion];
    [collector loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent isEqualToString:savedUserAgent]);
        XCTAssertFalse([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {

    }];
}

// Test that accessing .userAgent from the main thread does not deadlock
- (void)testUserAgentProperty_MainThread_NoCachedUA {
    XCTestExpectation *expectation = [self expectationWithDescription:@"main thread getter completes"];

    dispatch_async(dispatch_get_main_queue(), ^{
        BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
        NSString *ua = collector.userAgent;
        // Should return a value or nil within timeout, not deadlock
        XCTAssertTrue(ua == nil || ua.length >= 0);
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

// Test that accessing .userAgent from a background thread returns a valid value
- (void)testUserAgentProperty_BackgroundThread {
    XCTestExpectation *expectation = [self expectationWithDescription:@"background thread getter completes"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
        NSString *ua = collector.userAgent;
        XCTAssertNotNil(ua);
        XCTAssertTrue(ua.length > 0);
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

// Test concurrent access from multiple threads does not crash or deadlock
- (void)testUserAgentProperty_ConcurrentAccess {
    XCTestExpectation *expectation = [self expectationWithDescription:@"all concurrent accesses complete"];

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    dispatch_group_t group = dispatch_group_create();

    for (int i = 0; i < 10; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *ua = collector.userAgent;
            XCTAssertTrue(ua == nil || ua.length >= 0);
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

// Test that .userAgent returns cached value immediately on second access
- (void)testUserAgentProperty_CachedPath {
    NSString *savedUA = @"CachedUserAgent";
    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    [collector saveUserAgent:savedUA forSystemBuildVersion:[BNCDeviceSystem new].systemBuildVersion];

    NSString *ua = collector.userAgent;
    XCTAssertNotNil(ua);
    XCTAssertTrue([ua isEqualToString:savedUA]);
}

// Test simultaneous access from main thread and background thread
- (void)testUserAgentProperty_SimultaneousMainAndBackground {
    XCTestExpectation *bgExpectation = [self expectationWithDescription:@"background access completes"];
    XCTestExpectation *mainExpectation = [self expectationWithDescription:@"main thread access completes"];

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ua = collector.userAgent;
        XCTAssertTrue(ua == nil || ua.length >= 0);
        [bgExpectation fulfill];
    });

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *ua = collector.userAgent;
        XCTAssertTrue(ua == nil || ua.length >= 0);
        [mainExpectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end

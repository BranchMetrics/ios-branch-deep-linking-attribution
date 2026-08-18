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

// Async Population Test:
// Verifies the userAgent property is eventually populated after the fire-and-forget
// background warmup (as kicked off by Branch init) completes. The property starts nil
// and must hold a real WebKit user agent once the async collection finishes.
- (void)testUserAgentProperty_PopulatedAfterAsyncWarmup {
    XCTestExpectation *expectation = [self expectationWithDescription:@"warmup populates userAgent"];

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];
    XCTAssertNil(collector.userAgent, @"userAgent should be empty before the warmup runs");

    // Mirror Branch's fire-and-forget warmup: load on a background queue, no caller blocks.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [collector loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
            // Once the async warmup completes, the property must be populated.
            XCTAssertNotNil(collector.userAgent);
            XCTAssertTrue([collector.userAgent containsString:@"AppleWebKit"]);
            [expectation fulfill];
        }];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {

    }];
}

// Thread Safety Test:
// Concurrent reads of the userAgent property while the background warmup is writing it
// must not crash. The property is atomic, so reads racing the write are safe.
- (void)testUserAgentProperty_ConcurrentAccessDuringUpdate {
    XCTestExpectation *expectation = [self expectationWithDescription:@"concurrent access completes without crash"];

    BNCUserAgentCollector *collector = [BNCUserAgentCollector new];

    // Kick off the background update that writes the userAgent property.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [collector loadUserAgentWithCompletion:nil];
    });

    // Hammer the property with many concurrent reads while the update is in flight.
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < 1000; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *ua = collector.userAgent;
            // Touch the value to surface any use-after-free from a torn read.
            (void)ua.length;
            dispatch_group_leave(group);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {

    }];
}

@end

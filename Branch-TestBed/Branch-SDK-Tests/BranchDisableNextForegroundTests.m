//
//  BranchDisableNextForegroundTests.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 02/09/26.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "Branch.h"

@interface Branch (DisableNextForegroundTest)
+ (BOOL)automaticOpenTrackingDisabled;
@end

@interface BranchDisableNextForegroundTests : XCTestCase
@end

@implementation BranchDisableNextForegroundTests

- (void)tearDown {
    [Branch resumeSession];
    [super tearDown];
}

- (void)testDisableNextForeground_SetsFlag {
    [Branch disableNextForeground];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"disableNextForeground should set flag to YES");
}

- (void)testDisableNextForegroundForTimeInterval_SetsFlag {
    [Branch disableNextForegroundForTimeInterval:33.0];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"disableNextForegroundForTimeInterval should set flag to YES");
}

- (void)testResumeSession_ClearsFlag {
    [Branch disableNextForegroundForTimeInterval:60.0];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled]);

    [Branch resumeSession];
    XCTAssertFalse([Branch automaticOpenTrackingDisabled], @"resumeSession should set flag to NO");
}

- (void)testResumeSession_WhenNotDisabled_IsSafe {
    [Branch resumeSession];
    XCTAssertFalse([Branch automaticOpenTrackingDisabled], @"resumeSession when not disabled should leave flag NO");
}

- (void)testZeroTimeout_SetsFlag_NoTimer {
    [Branch disableNextForegroundForTimeInterval:0];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"Zero timeout should set flag to YES");

    XCTestExpectation *wait = [self expectationWithDescription:@"Wait"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(33.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"Flag should remain YES without manual resumeSession");
        [wait fulfill];
    });
    [self waitForExpectationsWithTimeout:34.0 handler:nil];
}

- (void)testTimerAutoResumes_ClearsFlag {
    [Branch disableNextForegroundForTimeInterval:3.0];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"Flag should be YES immediately");

    XCTestExpectation *wait = [self expectationWithDescription:@"Timer fires"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertFalse([Branch automaticOpenTrackingDisabled], @"Timer should auto-resume and clear flag");
        [wait fulfill];
    });
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
}

- (void)testSecondCall_CancelsFirstTimer {
    [Branch disableNextForegroundForTimeInterval:0.5];
    [Branch disableNextForegroundForTimeInterval:10.0];

    XCTestExpectation *wait = [self expectationWithDescription:@"First timer cancelled"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertTrue([Branch automaticOpenTrackingDisabled], @"Second call should have cancelled first timer, flag still YES");
        [wait fulfill];
    });
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}

- (void)testDisableNextForeground_ResumeRestores {
    [Branch disableNextForeground];
    XCTAssertTrue([Branch automaticOpenTrackingDisabled]);

    [Branch resumeSession];
    XCTAssertFalse([Branch automaticOpenTrackingDisabled]);
}

@end

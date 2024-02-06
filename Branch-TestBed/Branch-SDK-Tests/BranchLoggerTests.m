//
//  BranchLoggerTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 2/5/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchLogger.h"
#import "Branch.h"

@interface BranchLoggerTests : XCTestCase
@end

@implementation BranchLoggerTests

- (void)setUp {
    [super setUp];
    [BranchLogger shared].loggingEnabled = NO;
    [BranchLogger shared].logCallback = nil;
}

- (void)tearDown {
    [BranchLogger shared].loggingEnabled = NO;
    [BranchLogger shared].logCallback = nil;
    [super tearDown];
}

- (void)testEnableLoggingSetsCorrectDefaultLevel {
    [[Branch getInstance] enableLogging];
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelDebug, "Default log level should be Debug.");
}

- (void)testLogLevelThresholdBlocksLowerLevels {
    [[Branch getInstance] enableLoggingAtLevel:BranchLogLevelDebug];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Log callback expectation for message that should pass the threshold"];

    [BranchLogger shared].logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        if ([message isEqualToString:@"[BranchSDK][Debug] This message should trigger the log callback."] && logLevel >= BranchLogLevelDebug) {
            [expectation fulfill];
        }
    };
    
    [[BranchLogger shared] logVerbose:@"This verbose message should not trigger the log callback."];
    [[BranchLogger shared] logDebug:@"This message should trigger the log callback."];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testLogCallbackExecutesWithCorrectParameters {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Log callback expectation"];
    NSString *expectedMessage = @"[BranchSDK][Info] Test message";
    BranchLogLevel expectedLevel = BranchLogLevelInfo;

    [BranchLogger shared].logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        XCTAssertEqualObjects(message, expectedMessage, "Logged message does not match expected message.");
        XCTAssertEqual(logLevel, expectedLevel, "Logged level does not match expected level.");
        XCTAssertNil(error, "Error should be nil.");
        [expectation fulfill];
    };

    [[Branch getInstance] enableLoggingAtLevel:BranchLogLevelInfo];
    [[BranchLogger shared] logInfo:@"Test message"];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testLogLevelSpecificityFiltersLowerLevels {
    [[Branch getInstance] enableLoggingAtLevel:BranchLogLevelWarning];
    
    XCTestExpectation *verboseExpectation = [self expectationWithDescription:@"Verbose log callback"];
    verboseExpectation.inverted = YES;
    XCTestExpectation *errorExpectation = [self expectationWithDescription:@"Error log callback"];
    
    __block NSUInteger callbackCount = 0;
    [BranchLogger shared].logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        if (logLevel == BranchLogLevelVerbose) {
            [verboseExpectation fulfill];
        } else if (logLevel == BranchLogLevelError) {
            [errorExpectation fulfill];
        }
        callbackCount++;
    };
    
    [[BranchLogger shared] logVerbose:@"This should not be logged due to log level threshold."];
    [[BranchLogger shared] logError:@"This should be logged" error:nil];
    
    [self waitForExpectations:@[verboseExpectation, errorExpectation] timeout:2];
    XCTAssertEqual(callbackCount, 1, "Only one log callback should have been invoked.");
}

- (void)testErrorLoggingIncludesErrorDetails {
    [[Branch getInstance] enableLogging];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Error log includes error details"];
    
    NSError *testError = [NSError errorWithDomain:@"TestDomain" code:42 userInfo:@{NSLocalizedDescriptionKey: @"Test error description"}];
    [BranchLogger shared].logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        if ([message containsString:@"Test error description"] && error == testError) {
            [expectation fulfill];
        }
    };
    
    [[BranchLogger shared] logError:@"Testing error logging" error:testError];

    [self waitForExpectationsWithTimeout:1 handler:nil];
}


@end

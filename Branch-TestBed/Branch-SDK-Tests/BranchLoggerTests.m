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

// public API test
- (void)testEnableLoggingSetsCorrectDefaultLevel {
    [[Branch getInstance] enableLogging];
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelDebug, "Default log level should be Debug.");
}

- (void)testLoggingEnabled_NOByDefault {
    BranchLogger *logger = [BranchLogger new];
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count++;
    };
    [logger logError:@"msg" error:nil];
    
    XCTAssertTrue(count == 0);
}

- (void)testLoggingEnabled_Yes {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count++;
    };
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 2);
}

- (void)testLoggingIgnoresNil {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count++;
    };
    
    [logger logError:nil error:nil];
    XCTAssertTrue(count == 0);
}

- (void)testLoggingIgnoresEmptyString {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count++;
    };
    
    [logger logError:@"" error:nil];
    XCTAssertTrue(count == 0);
}

- (void)testLoggingEnabled_YesThenNo {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count = count + 1;
    };
    
    // one call
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    
    // disable, second call is ignored
    logger.loggingEnabled = NO;
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
}

- (void)testLogLevel_DebugByDefault {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count = count + 1;
    };
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    [logger logWarning:@"msg" error:nil];
    XCTAssertTrue(count == 2);
    [logger logDebug:@"msg" error:nil];
    XCTAssertTrue(count == 3);
    
    // this should be ignored
    [logger logVerbose:@"msg" error:nil];
    XCTAssertTrue(count == 3);
}

- (void)testLogLevel_Error {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = BranchLogLevelError;
    
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count = count + 1;
    };
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    
    // this should be ignored
    [logger logWarning:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    [logger logDebug:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    [logger logVerbose:@"msg" error:nil];
    XCTAssertTrue(count == 1);
}

- (void)testLogLevel_Warning {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = BranchLogLevelWarning;
    
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count = count + 1;
    };
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    [logger logWarning:@"msg" error:nil];
    XCTAssertTrue(count == 2);
    
    // this should be ignored
    [logger logDebug:@"msg" error:nil];
    XCTAssertTrue(count == 2);
    [logger logVerbose:@"msg" error:nil];
    XCTAssertTrue(count == 2);
}

- (void)testLogLevel_Verbose {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = BranchLogLevelVerbose;
    
    
    __block int count = 0;
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        count = count + 1;
    };
    
    [logger logError:@"msg" error:nil];
    XCTAssertTrue(count == 1);
    [logger logWarning:@"msg" error:nil];
    XCTAssertTrue(count == 2);
    [logger logDebug:@"msg" error:nil];
    XCTAssertTrue(count == 3);
    [logger logVerbose:@"msg" error:nil];
    XCTAssertTrue(count == 4);
}

- (void)testLogFormat_Default {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        NSString *expectedMessage = @"[BranchLoggerTests testLogFormat_Default] msg";
        
        XCTAssertTrue([expectedMessage isEqualToString:message]);
        XCTAssertTrue(logLevel == BranchLogLevelError);
        XCTAssertNil(error);
    };
    
    [logger logError:@"msg" error:nil];
}

- (void)testLogFormat_NSError {
    __block NSError *originalError = [NSError errorWithDomain:@"com.domain.test" code:200 userInfo:@{@"Error Message": @"Test Error"}];
    
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        NSString *expectedMessage = @"[BranchLoggerTests testLogFormat_NSError] msg";
        
        XCTAssertTrue([expectedMessage isEqualToString:message]);
        XCTAssertTrue(logLevel == BranchLogLevelError);
        XCTAssertTrue(originalError == error);
    };
    
    [logger logError:@"msg" error:originalError];
}

- (void)testLogFormat_includeCallerDetailsNO {
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    logger.includeCallerDetails = NO;
    
    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        NSString *expectedMessage = @"msg";
        
        XCTAssertTrue([expectedMessage isEqualToString:message]);
        XCTAssertTrue(logLevel == BranchLogLevelError);
        XCTAssertNil(error);
    };
    
    [logger logError:@"msg" error:nil];
}

- (void)testLogFormat_includeCallerDetailsNO_NSError {
    __block NSError *originalError = [NSError errorWithDomain:@"com.domain.test" code:200 userInfo:@{@"Error Message": @"Test Error"}];
    
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;
    logger.includeCallerDetails = NO;

    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        NSString *expectedMessage = @"msg";
        
        XCTAssertTrue([expectedMessage isEqualToString:message]);
        XCTAssertTrue(logLevel == BranchLogLevelError);
        XCTAssertTrue(originalError == error);
    };
    
    [logger logError:@"msg" error:originalError];
}

- (void)testDefaultBranchLogFormat {
    __block NSError *originalError = [NSError errorWithDomain:@"com.domain.test" code:200 userInfo:@{@"Error Message": @"Test Error"}];
    
    BranchLogger *logger = [BranchLogger new];
    logger.loggingEnabled = YES;

    logger.logCallback = ^(NSString * _Nonnull message, BranchLogLevel logLevel, NSError * _Nullable error) {
        NSString *expectedMessage = @"[BranchSDK][Error][BranchLoggerTests testDefaultBranchLogFormat] msg NSError: The operation couldn’t be completed. (com.domain.test error 200.)";
        NSString *formattedMessage = [BranchLogger formatMessage:message logLevel:logLevel error:error];
        
        XCTAssertTrue([expectedMessage isEqualToString:formattedMessage]);
    };
    
    [logger logError:@"msg" error:originalError];
}

@end

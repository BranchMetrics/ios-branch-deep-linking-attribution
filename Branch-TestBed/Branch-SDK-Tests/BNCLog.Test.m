/**
 @file          BNCLog.Test.m
 @package       BranchTests
 @brief         Tests for BNCLog.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "BNCLog.h"
#import "BNCTestCase.h"

@interface BNCLogTest : BNCTestCase
@end

@implementation BNCLogTest

- (void) testLogLevelString {
    XCTAssertEqual(BNCLogLevelAll,      BNCLogLevelFromString(@"BNCLogLevelAll"));
    XCTAssertEqual(BNCLogLevelDebugSDK, BNCLogLevelFromString(@"BNCLogLevelDebugSDK"));
    XCTAssertEqual(BNCLogLevelWarning,  BNCLogLevelFromString(@"BNCLogLevelWarning"));
    XCTAssertEqual(BNCLogLevelNone,     BNCLogLevelFromString(@"BNCLogLevelNone"));
    XCTAssertEqual(BNCLogLevelMax,      BNCLogLevelFromString(@"BNCLogLevelMax"));
}

- (void) testLogLevelEnum {
    XCTAssertEqualObjects(@"BNCLogLevelAll",        BNCLogStringFromLogLevel(BNCLogLevelAll));
    XCTAssertEqualObjects(@"BNCLogLevelAll",        BNCLogStringFromLogLevel(BNCLogLevelDebugSDK));
    XCTAssertEqualObjects(@"BNCLogLevelWarning",    BNCLogStringFromLogLevel(BNCLogLevelWarning));
    XCTAssertEqualObjects(@"BNCLogLevelNone",       BNCLogStringFromLogLevel(BNCLogLevelNone));
    XCTAssertEqualObjects(@"BNCLogLevelMax",        BNCLogStringFromLogLevel(BNCLogLevelMax));
}

@end

/**
 @file          BNCTestCase.Test.m
 @package       Branch-SDK
 @brief         Test cases for the underlying Branch test class.

 @author        Edward Smith
 @date          April 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"

@interface BNCTestCaseTest : BNCTestCase
@end

@implementation BNCTestCaseTest

- (void) testFailure {
    // Un-comment the next line to test a failure case:
    // XCTAssert(NO, @"Testing a test failure!");
    XCTAssertTrue(YES, @"Test passes!");
    NSString * bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSLog(@"The test bundleID is '%@'.", bundleID);
}

- (void) testLoadString {
    NSString *string = [self stringFromBundleWithKey:@"BNCTestCaseString"];
    XCTAssertEqualObjects(string, @"Test success!");
}

@end

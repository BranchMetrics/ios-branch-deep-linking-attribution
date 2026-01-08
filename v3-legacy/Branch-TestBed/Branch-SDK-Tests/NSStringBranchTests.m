/**
 @file          NSString+Branch.Test.m
 @package       Branch-SDK
 @brief         Tests for NSString+Branch.

 @author        Edward Smith
 @date          February 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import "NSString+Branch.h"

#define _countof(array)  (sizeof(array)/sizeof(array[0]))

@interface NSStringBranchTests : XCTestCase
@end

@implementation NSStringBranchTests

- (void)testMaskEqual {
    XCTAssertTrue([@"0123" bnc_isEqualToMaskedString:@"0123"]);
    XCTAssertFalse([@"0123" bnc_isEqualToMaskedString:@"012"]);
    XCTAssertFalse([@"0123" bnc_isEqualToMaskedString:@"01234"]);
    XCTAssertTrue([@"0123" bnc_isEqualToMaskedString:@"01*3"]);
    XCTAssertFalse([@"0123" bnc_isEqualToMaskedString:@"01*4"]);
    XCTAssertTrue([@"0123" bnc_isEqualToMaskedString:@"*123"]);
    XCTAssertTrue([@"0123" bnc_isEqualToMaskedString:@"012*"]);
    XCTAssertTrue([@"日本語123日本語" bnc_isEqualToMaskedString:@"日本語123日本語"]);
    XCTAssertFalse([@"日本語123日本語" bnc_isEqualToMaskedString:@"日本語1234本語"]);
    XCTAssertTrue([@"日本語123日本語" bnc_isEqualToMaskedString:@"日本語***日本語"]);
    XCTAssertTrue([@"日本語123日本語" bnc_isEqualToMaskedString:@"***123日本語"]);
}

@end

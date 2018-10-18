/**
 @file          BNCTestCase.h
 @package       Branch-SDK-Tests
 @brief         The Branch testing framework super class.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NSString+Branch.h"
#import "BNCThreads.h"

#define BNCTAssertEqualMaskedString(string, mask) { \
    if ((id)string != nil && (id)mask != nil && [string bnc_isEqualToMaskedString:mask]) { \
    } else { \
        XCTAssertEqualObjects(string, mask); \
    } \
}

extern BOOL BNCTestStringMatchesRegex(NSString *string, NSString *regex);

#define XCTAssertStringMatchesRegex(string, regex) \
    XCTAssertTrue(BNCTestStringMatchesRegex(string, regex))

@interface BNCTestCase : XCTestCase

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation;
- (void)awaitExpectations;
- (void)resetExpectations;
- (id)stringMatchingPattern:(NSString *)pattern;
- (double) systemVersion;

// Load Resources from the test bundle:

- (NSString*)stringFromBundleWithKey:(NSString*)key;
- (NSMutableDictionary*) mutableDictionaryFromBundleJSONWithKey:(NSString*)key;

+ (BOOL) breakpointsAreEnabledInTests;
+ (void) clearAllBranchSettings;
+ (BOOL) isApplication;
@end

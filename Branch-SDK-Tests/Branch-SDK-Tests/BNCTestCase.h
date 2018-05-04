//
//  BNCTestCase.h
//  Branch-TestBed
//
//  Created by Edward Smith on 4/27/17.
//  Copyright (c) 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "NSString+Branch.h"
#import "BNCUtilities.h"

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

// Load Resources from the test bundle:

- (NSString*)stringFromBundleWithKey:(NSString*)key;
- (NSMutableDictionary*) mutableDictionaryFromBundleJSONWithKey:(NSString*)key;

+ (BOOL) breakpointsAreEnabledInTests;

@end

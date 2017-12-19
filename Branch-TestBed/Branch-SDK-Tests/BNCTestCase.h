//
//  BNCTestCase.h
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Branch.h"
#import "NSString+Branch.h"

static inline dispatch_time_t BNCDispatchTimeFromSeconds(NSTimeInterval seconds)	{
	return dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
}

static inline void BNCAfterSecondsPerformBlock(NSTimeInterval seconds, dispatch_block_t block) {
	dispatch_after(BNCDispatchTimeFromSeconds(seconds), dispatch_get_main_queue(), block);
}

static inline void BNCSleepForTimeInterval(NSTimeInterval seconds) {
    double secPart = trunc(seconds);
    double nanoPart = trunc((seconds - secPart) * ((double)NSEC_PER_SEC));
    struct timespec sleepTime;
    sleepTime.tv_sec = (__typeof(sleepTime.tv_sec)) secPart;
    sleepTime.tv_nsec = (__typeof(sleepTime.tv_nsec)) nanoPart;
    nanosleep(&sleepTime, NULL);
}

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

+ (BOOL) testBreakpoints;
@end

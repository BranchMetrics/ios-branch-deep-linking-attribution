//
//  BNCPreferenceHelperTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/2/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BNCPreferenceHelperTests : XCTestCase

@end

@implementation BNCPreferenceHelperTests

#pragma mark - Default storage tests
- (void)testPreferenceDefaults {
    BNCPreferenceHelper *prefHelper = [[BNCPreferenceHelper alloc] init];
    
    // Defaults
    XCTAssertEqual(prefHelper.timeout, 5);
    XCTAssertEqual(prefHelper.retryInterval, 0);
    XCTAssertEqual(prefHelper.retryCount, 1);
}

- (void)testPreferenceSets {
    // Save original values
    NSInteger retryCount = [BNCPreferenceHelper getRetryCount];
    NSInteger retryInterval = [BNCPreferenceHelper getRetryInterval];
    NSInteger timeout = [BNCPreferenceHelper getTimeout];
    
    [BNCPreferenceHelper setRetryCount:NSIntegerMax];
    [BNCPreferenceHelper setRetryInterval:NSIntegerMax];
    [BNCPreferenceHelper setTimeout:NSIntegerMax];
    
    XCTAssertEqual([BNCPreferenceHelper getRetryCount], NSIntegerMax);
    XCTAssertEqual([BNCPreferenceHelper getRetryInterval], NSIntegerMax);
    XCTAssertEqual([BNCPreferenceHelper getTimeout], NSIntegerMax);
    
    // Restore
    [BNCPreferenceHelper setRetryCount:retryCount];
    [BNCPreferenceHelper setRetryInterval:retryInterval];
    [BNCPreferenceHelper setTimeout:timeout];
}

@end

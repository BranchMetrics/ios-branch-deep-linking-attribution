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
#import "BNCTestCase.h"

@interface BNCPreferenceHelperTests : BNCTestCase
@end

@implementation BNCPreferenceHelperTests

#pragma mark - Default storage tests
- (void)testPreferenceDefaults {
    BNCPreferenceHelper *prefHelper = [[BNCPreferenceHelper alloc] init];
    
    // Defaults
    XCTAssertEqual(prefHelper.timeout, 5.5);
    XCTAssertEqual(prefHelper.retryInterval, 0);
    XCTAssertEqual(prefHelper.retryCount, 3);
}

- (void)testPreferenceSets {
    BNCPreferenceHelper *prefHelper = [[BNCPreferenceHelper alloc] init];
    
    prefHelper.retryCount = NSIntegerMax;
    prefHelper.retryInterval = NSIntegerMax;
    prefHelper.timeout = NSIntegerMax;
    
    XCTAssertEqual(prefHelper.retryCount, NSIntegerMax);
    XCTAssertEqual(prefHelper.retryInterval, NSIntegerMax);
    XCTAssertEqual(prefHelper.timeout, NSIntegerMax);
}

@end

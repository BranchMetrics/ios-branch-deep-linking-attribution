//
//  BNCPreferenceHelperTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/2/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"

@interface BNCPreferenceHelperTests : XCTestCase

@end

@implementation BNCPreferenceHelperTests

- (void)testPreferenceDefaults {
    BNCPreferenceHelper *prefHelper = [[BNCPreferenceHelper alloc] init];
    
    // Retry items all have a default value, non-zero
    XCTAssertGreaterThan(prefHelper.timeout, 0);
    XCTAssertGreaterThan(prefHelper.retryInterval, 0);
    XCTAssertGreaterThan(prefHelper.retryCount, 0);
    
    // URI Scheme defaults to nil
    XCTAssertNil(prefHelper.uriScheme);
}

- (void)testPreferenceSets {
    // Save original values
    NSInteger retryCount = [BNCPreferenceHelper getRetryCount];
    NSInteger retryInterval = [BNCPreferenceHelper getRetryInterval];
    NSInteger timeout = [BNCPreferenceHelper getTimeout];
    NSString *uriScheme = [BNCPreferenceHelper getUriScheme];
    
    [BNCPreferenceHelper setRetryCount:NSIntegerMax];
    [BNCPreferenceHelper setRetryInterval:NSIntegerMax];
    [BNCPreferenceHelper setTimeout:NSIntegerMax];
    [BNCPreferenceHelper setUriScheme:@"foo://"];
    
    XCTAssertEqual([BNCPreferenceHelper getRetryCount], NSIntegerMax);
    XCTAssertEqual([BNCPreferenceHelper getRetryInterval], NSIntegerMax);
    XCTAssertEqual([BNCPreferenceHelper getTimeout], NSIntegerMax);
    XCTAssertEqualObjects([BNCPreferenceHelper getUriScheme], @"foo://");
    
    // Restore
    [BNCPreferenceHelper setRetryCount:retryCount];
    [BNCPreferenceHelper setRetryInterval:retryInterval];
    [BNCPreferenceHelper setTimeout:timeout];
    [BNCPreferenceHelper setUriScheme:uriScheme];
}

@end

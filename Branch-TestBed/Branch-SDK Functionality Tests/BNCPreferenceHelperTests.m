//
//  BNCPreferenceHelperTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/2/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Nocilla/Nocilla.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"

@interface BNCPreferenceHelperTests : XCTestCase

@end

@implementation BNCPreferenceHelperTests

+ (void)setUp {
    [super setUp];

    [[LSNocilla sharedInstance] start];
    [BNCPreferenceHelper setBranchKey:@"foo"];
    [BNCPreferenceHelper setDeviceFingerprintID:@"foo"];
}

+ (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    
    [BNCPreferenceHelper clearDebug];

    [super tearDown];
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];

    [super tearDown];
}

#pragma mark - Debugger tests
- (void)testDebuggerSuccessfulConnect {
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"debug/connect"])
    .andReturn(200);

    [BNCPreferenceHelper connectRemoteDebug];
    
    // Allow request to complete;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    
    XCTAssertTrue([BNCPreferenceHelper isRemoteDebug]);
}

- (void)testDebuggerConnectFailure {
    NSDictionary *responseDict = @{@"error": @{@"code": @465, @"message": @"Server not listening"}};
    NSData *responseData = [BNCEncodingUtils encodeDictionaryToJsonData:responseDict];
    
    stubRequest(@"POST", [BNCPreferenceHelper getAPIURL:@"debug/connect"])
    .andReturn(400)
    .withHeaders(@{@"Content-Type": @"application/json"})
    .withBody(responseData);

    [BNCPreferenceHelper connectRemoteDebug];

    [NSThread sleepForTimeInterval:1]; // Allow request to complete
    
    XCTAssertFalse([BNCPreferenceHelper isRemoteDebug]);
}

#pragma mark - Default storage tests
- (void)testPreferenceDefaults {
    BNCPreferenceHelper *prefHelper = [[BNCPreferenceHelper alloc] init];
    
    // Retry items all have a default value, non-zero
    XCTAssertGreaterThan(prefHelper.timeout, 0);
    XCTAssertGreaterThan(prefHelper.retryInterval, 0);
    XCTAssertGreaterThan(prefHelper.retryCount, 0);
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

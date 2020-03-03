//
//  BNCDisableAdNetworkCalloutsTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 3/2/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"
#import "BNCDeviceInfo.h"
#import "BNCServerInterface.h"

@interface BNCServerInterface()
- (void)updateDeviceInfoToMutableDictionary:(NSMutableDictionary *)dict;
@end

@interface BNCDisableAdNetworkCalloutsTests : XCTestCase

@end

// These tests are not parallelizable and therefore disabled by default
// This is due to the tight coupling between BNCPreferenceHelper and BNCDeviceInfo
@implementation BNCDisableAdNetworkCalloutsTests

- (void)setUp {
    [BNCPreferenceHelper preferenceHelper].disableAdNetworkCallouts = YES;
}

- (void)tearDown {
    [BNCPreferenceHelper preferenceHelper].disableAdNetworkCallouts = NO;
}

// check on the V2 dictionary
- (void)testV2Dictionary {
    NSDictionary *dict = [[BNCDeviceInfo getInstance] v2dictionary];
    XCTAssertNotNil(dict);
    XCTAssertNotNil(dict[@"brand"]);
    XCTAssertNotNil(dict[@"os"]);
    XCTAssertNotNil(dict[@"sdk"]);
    XCTAssertNotNil(dict[@"sdk_version"]);
    
    XCTAssertTrue(dict[@"disable_ad_network_callouts"]);
}

// check on V1 payload
- (void)testV1Payload {
    BNCServerInterface *interface = [BNCServerInterface new];
    interface.preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    
    NSMutableDictionary *tmp = [NSMutableDictionary new];
    [interface updateDeviceInfoToMutableDictionary:tmp];
    
    XCTAssertNotNil(tmp);
    XCTAssertTrue(tmp[@"disable_ad_network_callouts"]);
}

@end

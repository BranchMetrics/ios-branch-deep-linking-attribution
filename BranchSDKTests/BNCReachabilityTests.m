//
//  BNCReachabilityTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/18/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCReachability.h"

@interface BNCReachabilityTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCReachability *reachability;
@end

@implementation BNCReachabilityTests

- (void)setUp {
    self.reachability = [BNCReachability new];
}

- (void)tearDown {

}

- (void)testSimulator_WIFI {
    NSString *status = [self.reachability reachabilityStatus];
    XCTAssertNotNil(status);
    XCTAssert([@"wifi" isEqualToString:status]);
}

// Only works on a device with cell
//- (void)testDevice_Cell {
//    NSString *status = [self.reachability reachabilityStatus];
//    XCTAssertNotNil(status);
//    XCTAssert([@"mobile" isEqualToString:status]);
//}

// Only works on a device in Airplane mode
//- (void)testDevice_AirplaneMode {
//    NSString *status = [self.reachability reachabilityStatus];
//    XCTAssertNil(status);
//}

@end

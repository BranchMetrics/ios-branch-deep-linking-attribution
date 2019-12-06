//
//  BNCDeviceSystemTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/14/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCDeviceSystem.h"

@interface BNCDeviceSystemTests : XCTestCase

@property (nonatomic, strong, readwrite) BNCDeviceSystem *deviceSystem;

@end

@implementation BNCDeviceSystemTests

- (void)setUp {
    self.deviceSystem = [BNCDeviceSystem new];
}

- (void)tearDown {

}

- (void)testSystemBuildVersion {
    XCTAssertNotNil(self.deviceSystem.systemBuildVersion);
    XCTAssert(self.deviceSystem.systemBuildVersion.length > 0);
}

- (void)testMachine_Simulator {
    XCTAssert([@"x86_64" isEqualToString:self.deviceSystem.machine]);
}

- (void)testCPUType_Simulator {
    XCTAssert([@(7) isEqualToNumber:self.deviceSystem.cpuType]);
    XCTAssert([@(8) isEqualToNumber:self.deviceSystem.cpuSubType]);
}

@end

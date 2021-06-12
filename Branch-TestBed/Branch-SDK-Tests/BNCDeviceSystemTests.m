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
    // intel processor
    bool x86_64 = [@"x86_64" isEqualToString:self.deviceSystem.machine];
    
    // apple processor
    bool arm64 = [@"arm64" isEqualToString:self.deviceSystem.machine];
    
    XCTAssert(x86_64 || arm64);
}

/* Commenting out until this can be made more robust/portable/updated/whatever.
- (void)testCPUType_Simulator {
    // intel processor
    bool x86 = [@(7) isEqualToNumber:self.deviceSystem.cpuType];
    bool x86_sub = [@(8) isEqualToNumber:self.deviceSystem.cpuSubType];
    
    // apple processor
    bool arm = [@(16777228) isEqualToNumber:self.deviceSystem.cpuType];
    bool arm_sub = [@(2) isEqualToNumber:self.deviceSystem.cpuSubType];
    
    XCTAssert(x86 || arm);
    if (x86) {
        XCTAssert(x86_sub);
    } else {
        XCTAssert(arm_sub);
    }
}
// */

@end

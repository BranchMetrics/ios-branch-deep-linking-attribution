//
//  BNCDeviceInfoTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/21/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCDeviceInfo.h"

@interface BNCDeviceInfoTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@end

@implementation BNCDeviceInfoTests

- (void)setUp {
    self.deviceInfo = [BNCDeviceInfo new];
}

- (void)tearDown {

}

- (void)testAppVersion {
    // checks test app version
    XCTAssert([@"1.1" isEqualToString:self.deviceInfo.applicationVersion]);
}

- (void)testBrandName {
    XCTAssert([@"Apple" isEqualToString:self.deviceInfo.brandName]);
}

- (void)testModelName_Simulator {
    // intel processor
    bool x86_64 = [@"x86_64" isEqualToString:self.deviceInfo.modelName];
    
    // apple processor
    bool arm64 = [@"arm64" isEqualToString:self.deviceInfo.modelName];
    
    XCTAssert(x86_64 || arm64);
}

//- (void)testModelName_iPhone7 {
//    XCTAssert([@"iPhone9,3" isEqualToString:self.deviceInfo.modelName]);
//}

- (void)testOSName {
    XCTAssertNotNil(self.deviceInfo.osName);
    XCTAssert([self.deviceInfo.osName isEqualToString:[UIDevice currentDevice].systemName]);
}

- (void)testOSVersion {
    XCTAssertNotNil(self.deviceInfo.osVersion);
    XCTAssert([self.deviceInfo.osVersion isEqualToString:[UIDevice currentDevice].systemVersion]);
}

- (void)testOSBuildVersion {
    XCTAssertNotNil(self.deviceInfo.osBuildVersion);
}

- (void)testEnvironment {
    XCTAssert([@"FULL_APP" isEqualToString:self.deviceInfo.environment]);
}

- (void)testCpuType_Simulator {
    // intel processors
    bool x86 = [@"7" isEqualToString:self.deviceInfo.cpuType];
    
    // apple processors
    bool arm = [@"16777228" isEqualToString:self.deviceInfo.cpuType];
    
    XCTAssert(x86 || arm);
}

- (void)testScreenWidth {
    XCTAssert(self.deviceInfo.screenWidth.intValue > 320);
}

- (void)testScreenHeight {
    XCTAssert(self.deviceInfo.screenHeight.intValue > 320);
}

- (void)testScreenScale {
    XCTAssert(self.deviceInfo.screenScale.intValue > 0);
}

- (void)testCarrierName_Simulator {
    XCTAssertNil(self.deviceInfo.carrierName);
}

//- (void)testCarrierName_Att {
//    XCTAssert([@"AT&T" isEqualToString:self.deviceInfo.carrierName]);
//}

- (void)testLocale {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale isEqualToString:self.deviceInfo.locale]);
}

- (void)testCountry {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:self.deviceInfo.country]);
}

- (void)testLanguage {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:self.deviceInfo.language]);
}

- (void)testUserAgentString {
    // Currently this method is a trivial pass through to the BNCUserAgentCollector singleton
    // Eventually remove the singleton to enable easier testing
}

- (void)testPlugin {
    XCTAssertNil(self.deviceInfo.pluginName);
    XCTAssertNil(self.deviceInfo.pluginVersion);

    NSString *expectedName = @"react native";
    NSString *expectedVersion = @"1.0.0";
    
    [self.deviceInfo registerPluginName:expectedName version:expectedVersion];
    
    XCTAssert([expectedName isEqualToString:self.deviceInfo.pluginName]);
    XCTAssert([expectedVersion isEqualToString:self.deviceInfo.pluginVersion]);
}

- (void)testLocalIPAddress {
    NSString *address = [self.deviceInfo localIPAddress];
    XCTAssertNotNil(address);
    
    // shortest ipv4 is 7
    XCTAssert(address.length >= 7);
}

// just a sanity check on the V2 dictionary
- (void)testV2Dictionary {
    NSDictionary *dict = [self.deviceInfo v2dictionary];
    XCTAssertNotNil(dict);
    XCTAssertNotNil(dict[@"brand"]);
    XCTAssertNotNil(dict[@"os"]);
    XCTAssertNotNil(dict[@"sdk"]);
    XCTAssertNotNil(dict[@"sdk_version"]);
    
    XCTAssertNil(dict[@"disable_ad_network_callouts"]);
}

@end

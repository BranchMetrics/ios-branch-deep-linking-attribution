//
//  BNCDeviceInfoTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/21/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCDeviceInfo.h"
#import <arpa/inet.h>

@interface BNCDeviceInfoTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@end

// Category using inet_pton to validate
@implementation NSString (Test)

- (BOOL)isValidIPAddress {
    const char *utf8 = [self UTF8String];
    int success;

    struct in_addr dst;
    success = inet_pton(AF_INET, utf8, &dst);
    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, utf8, &dst6);
    }

    return success == 1;
}

@end

@implementation BNCDeviceInfoTests

- (void)setUp {
    self.deviceInfo = [BNCDeviceInfo new];
}

- (void)tearDown {

}

// verify tooling method works
- (void)testIPValidationCategory {
    XCTAssert(![@"" isValidIPAddress]);
    
    // ipv4
    XCTAssert([@"0.0.0.0" isValidIPAddress]);
    XCTAssert([@"127.0.0.1" isValidIPAddress]);
    XCTAssert([@"10.1.2.3" isValidIPAddress]);
    XCTAssert([@"172.0.0.0" isValidIPAddress]);
    XCTAssert([@"192.0.0.0" isValidIPAddress]);
    XCTAssert([@"255.255.255.255" isValidIPAddress]);
    
    // invalid ipv4
    XCTAssert(![@"-1.0.0.0" isValidIPAddress]);
    XCTAssert(![@"256.0.0.0" isValidIPAddress]);
    
    // ipv6
    XCTAssert([@"2001:0db8:0000:0000:0000:8a2e:0370:7334" isValidIPAddress]);
    XCTAssert([@"2001:db8::8a2e:370:7334" isValidIPAddress]);
    
    // invalid ipv6
    XCTAssert(![@"2001:0db8:0000:0000:0000:8a2e:0370:733g" isValidIPAddress]);
    XCTAssert(![@"2001:0db8:0000:0000:0000:8a2e:0370:7330:1234" isValidIPAddress]);
}

- (void)testHardwareId {
    XCTAssertNotNil(self.deviceInfo.hardwareId);
    
    // verify hardwareId is a valid UUID
    NSUUID *hardwareId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.hardwareId];
    XCTAssertNotNil(hardwareId);
}

- (void)testHardwareIdType {
    // on simulator it's IDFV, Branch servers expect vendor_id
    XCTAssert([self.deviceInfo.hardwareIdType isEqualToString:@"vendor_id"]);
}

- (void)testIsRealHardwareId {
    // on simulator it's IDFV
    XCTAssert(self.deviceInfo.isRealHardwareId);
}

- (void)testAdvertiserId {
    // the testbed does not show the ATT prompt.
    XCTAssertNil(self.deviceInfo.advertiserId);
}

- (void)testVendorId {
    XCTAssertNotNil(self.deviceInfo.vendorId);
    
    // verify vendorId is a valid UUID
    NSUUID *vendorId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.vendorId];
    XCTAssertNotNil(vendorId);
}

- (void)testOptedInStatus {
    // the testbed does not show the ATT prompt.
    XCTAssert([self.deviceInfo.optedInStatus isEqualToString:@"not_determined"]);
}

- (void)testIsFirstOptIn {
    // the testbed does not show the ATT prompt.
    XCTAssert(self.deviceInfo.isFirstOptIn == NO);
}

- (void)testIsAdTrackingEnabled {
    // on iOS 14+, this is always NO
    XCTAssert(self.deviceInfo.isAdTrackingEnabled == NO);
}

- (void)testLocalIPAddress {
    NSString *address = [self.deviceInfo localIPAddress];
    XCTAssertNotNil(address);
    XCTAssert([address isValidIPAddress]);
}

- (void)testConnectionType {
    // simulator is on wifi
    XCTAssert([[self.deviceInfo connectionType] isEqualToString:@"wifi"]);
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
    
    // This is not the system name, but rather the name Branch server expects
    // XCTAssert([self.deviceInfo.osName isEqualToString:[UIDevice currentDevice].systemName]);
    XCTAssert([@"iOS" isEqualToString:self.deviceInfo.osName] || [@"tv_OS" isEqualToString:self.deviceInfo.osName]);
}

- (void)testOSVersion {
    XCTAssertNotNil(self.deviceInfo.osVersion);
    XCTAssert([self.deviceInfo.osVersion isEqualToString:[UIDevice currentDevice].systemVersion]);
}

- (void)testOSBuildVersion {
    XCTAssertNotNil(self.deviceInfo.osBuildVersion);
}

- (void)testEnvironment {
    // currently not running unit tests on extensions
    XCTAssert([@"FULL_APP" isEqualToString:self.deviceInfo.environment]);
}

- (void)testCpuType_Simulator {
    // intel processors
    bool x86 = [@"7" isEqualToString:self.deviceInfo.cpuType];
    
    // apple processors
    bool arm = [@"16777228" isEqualToString:self.deviceInfo.cpuType];
    
    XCTAssert(x86 || arm);
}

/*
 * Sample device screens
 * original iPhone 320x480 1
 * iPad Pro (6th gen 12.9") 2048x2732 2
 * iPhone 14 Pro max 1290x2796 3
 */

- (void)testScreenWidth {
    XCTAssert(self.deviceInfo.screenWidth.intValue >= 320 && self.deviceInfo.screenWidth.intValue <= 2796);
}

- (void)testScreenHeight {
    XCTAssert(self.deviceInfo.screenHeight.intValue >= 320 && self.deviceInfo.screenWidth.intValue <= 2796);
}

- (void)testScreenScale {
    XCTAssert(self.deviceInfo.screenScale.intValue >= 1 && self.deviceInfo.screenScale.intValue <= 3);
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
    XCTAssert([self.deviceInfo.userAgentString containsString:@"AppleWebKit"]);
}

- (void)testApplicationVersion {
    // checks test app version
    XCTAssert([@"1.1" isEqualToString:self.deviceInfo.applicationVersion]);
}

- (void)testRegisterPluginNameVersion {
    XCTAssertNil(self.deviceInfo.pluginName);
    XCTAssertNil(self.deviceInfo.pluginVersion);

    NSString *expectedName = @"react native";
    NSString *expectedVersion = @"1.0.0";
    
    [self.deviceInfo registerPluginName:expectedName version:expectedVersion];
    
    XCTAssert([expectedName isEqualToString:self.deviceInfo.pluginName]);
    XCTAssert([expectedVersion isEqualToString:self.deviceInfo.pluginVersion]);
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

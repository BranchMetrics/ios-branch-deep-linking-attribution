//
//  BNCDeviceInfoTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/21/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCDeviceInfo.h"
#import "BNCUserAgentCollector.h"

@interface BNCDeviceInfoTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@end

@implementation BNCDeviceInfoTests

- (void)setUp {
    [self workaroundUserAgentLazyLoad];
    self.deviceInfo = [BNCDeviceInfo new];
}

// user agent needs to be loaded
- (void)workaroundUserAgentLazyLoad {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"setup"];
    [[BNCUserAgentCollector instance] loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) { }];
}

- (void)tearDown {

}

- (void)testHardwareId {
    XCTAssertNotNil(self.deviceInfo.hardwareId);
    
    // verify hardwareId is a valid UUID
    NSUUID *hardwareId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.hardwareId];
    XCTAssertNotNil(hardwareId);
}

- (void)testHardwareIdType {
    // without ATT, this is the IDFV. Branch servers expect it as vendor_id
    XCTAssert([self.deviceInfo.hardwareIdType isEqualToString:@"vendor_id"]);
}

- (void)testIsRealHardwareId {
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

- (void)testAnonId {
    XCTAssertNotNil(self.deviceInfo.anonId);
    
    // verify anonId is a valid UUID
    NSUUID *anonId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.anonId];
    XCTAssertNotNil(anonId);
}

- (void)testOptedInStatus {
    // the testbed does not show the ATT prompt.
    XCTAssert([self.deviceInfo.optedInStatus isEqualToString:@"not_determined"]);
}

- (void)testIsFirstOptIn {
    // the testbed does not show the ATT prompt.
    XCTAssert(self.deviceInfo.isFirstOptIn == NO);
}

- (void)testLocalIPAddress {
    NSString *address = [self.deviceInfo localIPAddress];
    XCTAssertNotNil(address);
    XCTAssert(address.length > 7);
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

- (void)testOSName {
    XCTAssertNotNil(self.deviceInfo.osName);
    XCTAssert([@"iOS" isEqualToString:self.deviceInfo.osName]);
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

- (void)testScreenWidth {
    XCTAssert(self.deviceInfo.screenWidth.intValue >= 320);
}

- (void)testScreenHeight {
    XCTAssert(self.deviceInfo.screenHeight.intValue >= 320);
}

- (void)testScreenScale {
    XCTAssert(self.deviceInfo.screenScale.intValue >= 1);
}

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

- (void)testApplicationVersion_TestBed {
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

@end

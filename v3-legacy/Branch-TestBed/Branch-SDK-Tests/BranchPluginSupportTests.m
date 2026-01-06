//
//  BranchPluginSupportTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 1/25/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchPluginSupport.h"

@interface BranchPluginSupportTests : XCTestCase
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, NSString *> *deviceDescription;
@end

@implementation BranchPluginSupportTests

- (void)setUp {
    self.deviceDescription = [[BranchPluginSupport new] deviceDescription];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAppVersion {
    // checks test app version
    XCTAssert([@"1.1" isEqualToString:_deviceDescription[@"app_version"]]);
}

- (void)testBrandName {
    XCTAssert([@"Apple" isEqualToString:_deviceDescription[@"brand"]]);
}

- (void)testModelName_Simulator {
    // intel processor
    bool x86_64 = [@"x86_64" isEqualToString:_deviceDescription[@"model"]];
    
    // apple processor
    bool arm64 = [@"arm64" isEqualToString:_deviceDescription[@"model"]];
    
    XCTAssert(x86_64 || arm64);
}

- (void)testOSName {
    XCTAssertNotNil(_deviceDescription[@"os"]);
    XCTAssert([_deviceDescription[@"os"] isEqualToString:[UIDevice currentDevice].systemName]);
}

- (void)testOSVersion {
    XCTAssertNotNil(_deviceDescription[@"os_version"]);
    XCTAssert([_deviceDescription[@"os_version"] isEqualToString:[UIDevice currentDevice].systemVersion]);
}

- (void)testEnvironment {
    XCTAssert([@"FULL_APP" isEqualToString:_deviceDescription[@"environment"]]);
}

- (void)testScreenWidth {
    XCTAssert(_deviceDescription[@"screen_width"].intValue > 320);
}

- (void)testScreenHeight {
    XCTAssert(_deviceDescription[@"screen_height"].intValue > 320);
}

- (void)testScreenScale {
    XCTAssert(_deviceDescription[@"screen_dpi"].intValue > 0);
}

- (void)testCountry {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:_deviceDescription[@"country"]]);
}

- (void)testLanguage {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:_deviceDescription[@"language"]]);
}

- (void)testLocalIPAddress {
    NSString *address = _deviceDescription[@"local_ip"];
    XCTAssertNotNil(address);
    
    // shortest ipv4 is 7
    XCTAssert(address.length >= 7);
}

@end

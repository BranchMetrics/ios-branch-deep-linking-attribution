//
//  BNCSystemObserverTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCSystemObserver.h"

@interface BNCSystemObserverTests : XCTestCase

@end

@implementation BNCSystemObserverTests

- (void)testDefaultURIScheme_TestBed {
    XCTAssert([[BNCSystemObserver defaultURIScheme] isEqualToString:@"branchtest"]);
}

- (void)testAppVersion_TestBed {
    XCTAssert([[BNCSystemObserver applicationVersion] isEqualToString:@"1.1"]);
}

- (void)testBundleIdentifier_TestBed {
    XCTAssert([[BNCSystemObserver bundleIdentifier] isEqualToString:@"io.branch.sdk.Branch-TestBed"]);
}

- (void)testBrand {
    XCTAssert([[BNCSystemObserver brand] isEqualToString:@"Apple"]);
}

- (void)testModel_Simulator {
    // simulator models
    NSString *tmp = [BNCSystemObserver model];
    XCTAssert([tmp containsString:@"arm64"] || [tmp containsString:@"x86_64"]);
}

//- (void)testModelName_iPhone7 {
//    XCTAssert([@"iPhone9,3" isEqualToString:[BNCSystemObserver model]]);
//}

- (void)testOSName {
    XCTAssertNotNil([BNCSystemObserver osName]);
    
    // This is not the system name, but rather the name Branch server expects
    // XCTAssert([self.deviceInfo.osName isEqualToString:[UIDevice currentDevice].systemName]);
    XCTAssert([@"iOS" isEqualToString:[BNCSystemObserver osName]] || [@"tv_OS" isEqualToString:[BNCSystemObserver osName]]);
}

- (void)testOSVersion {
    XCTAssertNotNil([BNCSystemObserver osVersion]);
    XCTAssert([[BNCSystemObserver osVersion] isEqualToString:[UIDevice currentDevice].systemVersion]);
}

/*
 * Sample device screens
 * original iPhone 320x480 1
 * iPad Pro (6th gen 12.9") 2048x2732 2
 * iPhone 14 Pro max 1290x2796 3
 */

- (void)testScreenWidth {
    XCTAssert([BNCSystemObserver screenWidth].intValue >= 320 && [BNCSystemObserver screenWidth].intValue <= 2796);
}

- (void)testScreenHeight {
    XCTAssert([BNCSystemObserver screenHeight].intValue >= 320 && [BNCSystemObserver screenWidth].intValue <= 2796);
}

- (void)testScreenScale {
    XCTAssert([BNCSystemObserver screenScale].intValue >= 1 && [BNCSystemObserver screenScale].intValue <= 3);
}

- (void)testIsSimulator_Simulator {
    XCTAssert([BNCSystemObserver isSimulator]);
}

- (void)testAdvertiserIdentifier_NoATTPrompt {
    XCTAssertNil([BNCSystemObserver advertiserIdentifier]);
}

- (void)testOptedInStatus_NoATTPrompt {
    XCTAssert([[BNCSystemObserver attOptedInStatus] isEqualToString:@"not_determined"]);
}

- (void)testAppleAttributionToken_Simulator {
    NSString *token = [BNCSystemObserver appleAttributionToken];
    XCTAssertNil(token);
}

- (void)testEnvironment {
    // currently not running unit tests on extensions
    XCTAssert([@"FULL_APP" isEqualToString:[BNCSystemObserver environment]]);
}

- (void)testIsAppClip {
    // currently not running unit tests on extensions
    XCTAssert(![BNCSystemObserver isAppClip]);
}

@end

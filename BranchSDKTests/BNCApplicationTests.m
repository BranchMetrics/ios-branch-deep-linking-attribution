//
//  BNCApplication.Test.m
//  Branch-SDK-Tests
//
//  Created by Edward on 1/10/18.
//  Copyright © 2018 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCApplication.h"
#import "BNCKeyChain.h"

@interface BNCApplicationTests : XCTestCase
@end

@implementation BNCApplicationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testApplication {
    // Test general info:

    if ([UIApplication sharedApplication] == nil) {
        NSLog(@"No host application for BNCApplication testing!");
        return;
    }

    BNCApplication *application = [BNCApplication currentApplication];
    XCTAssertEqualObjects(application.bundleID,                     @"branch.BranchSDKTestsHostApp");
    XCTAssertEqualObjects(application.displayName,                  @"BranchSDKTestsHostApp");
    XCTAssertEqualObjects(application.shortDisplayName,             @"BranchSDKTestsHostApp");
    XCTAssertEqualObjects(application.displayVersionString,         @"1.0");
    XCTAssertEqualObjects(application.versionString,                @"1");
}

- (void) testAppDates {
    // App dates. Not a great test but tests basic function:

    if ([UIApplication sharedApplication] == nil) {
        NSLog(@"No host application for BNCApplication testing!");
        return;
    }

    NSTimeInterval const kOneYearAgo = -365.0 * 24.0 * 60.0 * 60.0;

    BNCApplication *application = [BNCApplication currentApplication];
    XCTAssertTrue(application.firstInstallDate && [application.firstInstallDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.firstInstallBuildDate && [application.firstInstallBuildDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.currentInstallDate && [application.currentInstallDate timeIntervalSinceNow] > kOneYearAgo);
    XCTAssertTrue(application.currentBuildDate && [application.currentBuildDate timeIntervalSinceNow] > kOneYearAgo);

    NSString*const kBranchKeychainService          = @"BranchKeychainService";
    NSString*const kBranchKeychainFirstBuildKey    = @"BranchKeychainFirstBuild";
    NSString*const kBranchKeychainFirstInstalldKey = @"BranchKeychainFirstInstall";

    NSDate * firstBuildDate =
        [BNCKeyChain retrieveDateForService:kBranchKeychainService
            key:kBranchKeychainFirstBuildKey
            error:nil];
    XCTAssertEqualObjects(application.firstInstallBuildDate, firstBuildDate);

    NSDate * firstInstallDate =
        [BNCKeyChain retrieveDateForService:kBranchKeychainService
            key:kBranchKeychainFirstInstalldKey
            error:nil];
    XCTAssertEqualObjects(application.firstInstallDate, firstInstallDate);
}

@end

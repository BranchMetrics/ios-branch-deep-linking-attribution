//
//  BNCSystemObserverTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//


#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BNCTestCase.h"
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"


@interface BNCSystemObserver (Testing)

+ (BNCUpdateState) updateStateWithBuildDate:(NSDate*)buildDate
                             appInstallDate:(NSDate*)appInstallDate
                           storedAppVersion:(NSString*)storedAppVersion
                          currentAppVersion:(NSString*)currentAppVersion;
+ (NSDate*) appInstallDate;
+ (NSDate*) appBuildDate;
@end

#pragma mark - BNCSystemObserverTests

@interface BNCSystemObserverTests : BNCTestCase
@end


@implementation BNCSystemObserverTests

#pragma mark - Test Update State with No Stored version

- (void)testGetUpdateStateWithNoStoredVersionAndDatesAreEqual {

    NSDate *now = [NSDate date];
    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:now
            appInstallDate:now
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesUnder60SecondsApart {

    NSDate *now = [NSDate date];
    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:now
            appInstallDate:[now dateByAddingTimeInterval:59.0]
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesMoreThan60SecondsApart {

    NSDate *now = [NSDate date];
    NSDate *moreThan24HoursFromNow = [now dateByAddingTimeInterval:(60.0*60.0*24.5)];

    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:moreThan24HoursFromNow
            appInstallDate:now
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 2);
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilCreationDate {
    //  CreateDate is app install date.

    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:nil
            appInstallDate:[NSDate date]
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilUpdateDate {
    //  Update date is build date.

    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:[NSDate date]
            appInstallDate:nil
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndBuildDateGreaterInstallDate {

    NSDate *now = [NSDate date];
    BNCUpdateState updateState =
        [BNCSystemObserver
            updateStateWithBuildDate:[now dateByAddingTimeInterval:60.0*60.0*24.0*5.0]
            appInstallDate:now
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateState == 2);
}

- (void)testGetUpdateStateWithEqualStoredAndCurrentVersion {
    NSString *version = @"1";
    [BNCPreferenceHelper preferenceHelper].appVersion = version;
    
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:bundleMock] mainBundle];
    [[[bundleMock stub] andReturn:@{ @"CFBundleShortVersionString": version }] infoDictionary];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    XCTAssertEqualObjects(updateState, @1);

    [bundleMock stopMocking];
}

- (void)testGetUpdateStateWithNonEqualStoredAndCurrentVersion {
    NSString *currentVersion = @"2";
    NSString *storedVersion = @"1";
    [BNCPreferenceHelper preferenceHelper].appVersion = storedVersion;
    
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:bundleMock] mainBundle];
    [[[bundleMock stub] andReturn:@{ @"CFBundleShortVersionString": currentVersion }] infoDictionary];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    XCTAssertEqualObjects(updateState, @2);
    
    [bundleMock stopMocking];
}

- (void) testAppBuildDate {
    NSDate *appBuildDate = [BNCSystemObserver appBuildDate];
    XCTAssert(appBuildDate && [appBuildDate timeIntervalSince1970] > 0.0);
}

- (void) testAppInstallDate {
    NSDate *installDate = [BNCSystemObserver appInstallDate];
    XCTAssert(installDate && [installDate timeIntervalSince1970] > 0.0);
}

- (void) testIsSimulator {
    BOOL isSim = [BNCSystemObserver isSimulator];

    #if (TARGET_OS_SIMULATOR)
    XCTAssertTrue(isSim);
    #else
    XCTAssertFalse(isSim);
    #endif
}

#pragma mark - URI Scheme Tests

- (void)testGetDefaultUriSchemeWithSingleCharacterScheme {
    NSString * const SINGLE_CHARACTER_SCEHEME = @"a";
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock expect]
        andReturn:bundleMock]
            mainBundle];
    [[[bundleMock expect]
        andReturn:@[ @{ @"CFBundleURLSchemes": @[ SINGLE_CHARACTER_SCEHEME ] } ]]
            objectForInfoDictionaryKey:[OCMArg any]];

    NSString *uriScheme = [BNCSystemObserver getDefaultUriScheme];
    
    XCTAssertEqualObjects(SINGLE_CHARACTER_SCEHEME, uriScheme);
    
    [bundleMock verify];
    [bundleMock stopMocking];
}

@end

//
//  BNCSystemObserverTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BNCSystemObserver.h"
#import "BNCPreferenceHelper.h"

@interface BNCSystemObserverTests : XCTestCase

@end

@implementation BNCSystemObserverTests


#pragma mark - Test Update State with No Stored version

- (void)testGetUpdateStateWithNoStoredVersionAndDatesAreEqual {
    NSDate *now = [NSDate date];
    [self stubCreationDate:now modificationDate:now];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesUnder60SecondsApart {
    NSDate *now = [NSDate date];
    NSDate *lessThan60SecondsFromNow = [now dateByAddingTimeInterval:59];
    [self stubCreationDate:now modificationDate:lessThan60SecondsFromNow];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesMoreThan60SecondsApart {
    NSDate *now = [NSDate date];
    NSDate *moreThan60SecondsFromNow = [now dateByAddingTimeInterval:61];
    [self stubCreationDate:now modificationDate:moreThan60SecondsFromNow];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @2);
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilCreationDate {
    NSDate *now = [NSDate date];
    [self stubCreationDate:nil modificationDate:now];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilUpdateDate {
    NSDate *now = [NSDate date];
    [self stubCreationDate:now modificationDate:nil];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);
}

- (void)testGetUpdateStateWithEqualStoredAndCurrentVersion {
    NSString *version = @"1";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:version] getAppVersion];
    
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:bundleMock] mainBundle];
    [[[bundleMock stub] andReturn:@{ @"CFBundleShortVersionString": version }] infoDictionary];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @1);
}

- (void)testGetUpdateStateWithNonEqualStoredAndCurrentVersion {
    NSString *currentVersion = @"2";
    NSString *storedVersion = @"1";
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:storedVersion] getAppVersion];
    
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:bundleMock] mainBundle];
    [[[bundleMock stub] andReturn:@{ @"CFBundleShortVersionString": currentVersion }] infoDictionary];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @2);
}


#pragma mark - Internals

- (void)stubCreationDate:(NSDate *)creationDate modificationDate:(NSDate *)modificationDate {
    id fileManagerMock = OCMClassMock([NSFileManager class]);
    id docDirAttributesMock = OCMClassMock([NSDictionary class]);
    id bundleAttributesMock = OCMClassMock([NSDictionary class]);
    [[[fileManagerMock stub] andReturn:fileManagerMock] defaultManager];
    [[[fileManagerMock expect] andReturn:docDirAttributesMock] attributesOfItemAtPath:[OCMArg any] error:(NSError __autoreleasing **)[OCMArg anyPointer]];
    [[[fileManagerMock expect] andReturn:bundleAttributesMock] attributesOfItemAtPath:[OCMArg any] error:(NSError __autoreleasing **)[OCMArg anyPointer]];
    [[[docDirAttributesMock stub] andReturn:creationDate] fileCreationDate];
    [[[bundleAttributesMock stub] andReturn:modificationDate] fileModificationDate];
}

- (void)stubNilValuesForStoredAndCurrentVersions {
    id preferenceHelperMock = [OCMockObject mockForClass:[BNCPreferenceHelper class]];
    [[[preferenceHelperMock stub] andReturn:nil] getAppVersion];

    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:nil] mainBundle];
}

@end

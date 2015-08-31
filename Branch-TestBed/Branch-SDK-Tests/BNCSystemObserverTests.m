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

@property (strong, nonatomic) id fileManagerMock;
@property (strong, nonatomic) id docDirAttributesMock;
@property (strong, nonatomic) id bundleAttributesMock;

@end

@implementation BNCSystemObserverTests


#pragma mark - Test Update State with No Stored version

- (void)testGetUpdateStateWithNoStoredVersionAndDatesAreEqual {
    NSDate *now = [NSDate date];
    [self stubCreationDate:now modificationDate:now];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesUnder60SecondsApart {
    NSDate *now = [NSDate date];
    NSDate *lessThan24HoursFromNow = [now dateByAddingTimeInterval:59];
    [self stubCreationDate:now modificationDate:lessThan24HoursFromNow];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesMoreThan60SecondsApart {
    NSDate *now = [NSDate date];
    NSDate *moreThan24HoursFromNow = [now dateByAddingTimeInterval:86401];
    [self stubCreationDate:now modificationDate:moreThan24HoursFromNow];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @2);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilCreationDate {
    NSDate *now = [NSDate date];
    [self stubCreationDate:nil modificationDate:now];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilUpdateDate {
    NSDate *now = [NSDate date];
    [self stubCreationDate:now modificationDate:nil];
    [self stubNilValuesForStoredAndCurrentVersions];
    
    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithEqualStoredAndCurrentVersion {
    NSString *version = @"1";
    [BNCPreferenceHelper preferenceHelper].appVersion = version;
    
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:bundleMock] mainBundle];
    [[[bundleMock stub] andReturn:@{ @"CFBundleShortVersionString": version }] infoDictionary];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    
    XCTAssertEqualObjects(updateState, @1);

    [self clearMocks];
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
    
    [self clearMocks];
}


#pragma mark - URI Scheme tests

- (void)testGetDefaultUriSchemeWithSingleCharacterScheme {
    NSString * const SINGLE_CHARACTER_SCEHEME = @"a";
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock expect] andReturn:bundleMock] mainBundle];
    [[[bundleMock expect] andReturn:@[ @{ @"CFBundleURLSchemes": @[ SINGLE_CHARACTER_SCEHEME ] } ]] objectForInfoDictionaryKey:[OCMArg any]];

    NSString *uriScheme = [BNCSystemObserver getDefaultUriScheme];
    
    XCTAssertEqualObjects(SINGLE_CHARACTER_SCEHEME, uriScheme);
    
    [bundleMock verify];
    [bundleMock stopMocking];
}


#pragma mark - Internals

- (void)stubCreationDate:(NSDate *)creationDate modificationDate:(NSDate *)modificationDate {
    self.fileManagerMock = OCMClassMock([NSFileManager class]);
    self.docDirAttributesMock = OCMClassMock([NSDictionary class]);
    self.bundleAttributesMock = OCMClassMock([NSDictionary class]);
    [[[self.fileManagerMock stub] andReturn:self.fileManagerMock] defaultManager];
    [[[self.fileManagerMock expect] andReturn:self.docDirAttributesMock] attributesOfItemAtPath:[OCMArg any] error:(NSError __autoreleasing **)[OCMArg anyPointer]];
    [[[self.fileManagerMock expect] andReturn:self.bundleAttributesMock] attributesOfItemAtPath:[OCMArg any] error:(NSError __autoreleasing **)[OCMArg anyPointer]];
    [[[self.docDirAttributesMock stub] andReturn:creationDate] fileCreationDate];
    [[[self.bundleAttributesMock stub] andReturn:modificationDate] fileModificationDate];
}

- (void)clearMocks {
    [self.fileManagerMock stopMocking];
    [self.docDirAttributesMock stopMocking];
    [self.bundleAttributesMock stopMocking];
}

- (void)stubNilValuesForStoredAndCurrentVersions {
    [BNCPreferenceHelper preferenceHelper].appVersion = nil;

    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:nil] mainBundle];
}

@end

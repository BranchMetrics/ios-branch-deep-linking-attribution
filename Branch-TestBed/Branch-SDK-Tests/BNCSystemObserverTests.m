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


@interface BNCSystemObserver (Testing)

+ (BNCUpdateStatus) updateStatusWithBuildDate:(NSDate*)buildDate
                               appInstallDate:(NSDate*)appInstallDate
                             storedAppVersion:(NSString*)storedAppVersion
                            currentAppVersion:(NSString*)currentAppVersion;

@end

#pragma mark - BNCSystemObserverTests

@interface BNCSystemObserverTests : XCTestCase

@property (strong, nonatomic) id fileManagerMock;
@property (strong, nonatomic) id docDirAttributesMock;
@property (strong, nonatomic) id bundleAttributesMock;
@property (strong, nonatomic) id URLMock;
@property (strong, nonatomic) NSArray *retainArray;

@end


@implementation BNCSystemObserverTests

#pragma mark - Test Update State with No Stored version

- (void)testGetUpdateStateWithNoStoredVersionAndDatesAreEqual {

    NSDate *now = [NSDate date];
    BNCUpdateStatus updateStatus =
        [BNCSystemObserver
            updateStatusWithBuildDate:now
            appInstallDate:now
            storedAppVersion:nil
            currentAppVersion:@"1.2.1"];

    XCTAssertTrue(updateStatus == BNCUpdateStatusInstall);
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesUnder60SecondsApart {
    [self stubNilValuesForStoredAndCurrentVersions];
    NSDate *now = [NSDate date];
    NSDate *lessThan24HoursFromNow = [now dateByAddingTimeInterval:59.0];
    [self stubAppInstallDate:now buildDate:lessThan24HoursFromNow];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndDatesMoreThan60SecondsApart {
    NSDate *now = [NSDate date];
    NSDate *moreThan24HoursFromNow = [now dateByAddingTimeInterval:(60.0*60.0*24.5)];
    [self stubNilValuesForStoredAndCurrentVersions];
    [self stubAppInstallDate:now buildDate:moreThan24HoursFromNow];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    XCTAssertEqualObjects(updateState, @2);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilCreationDate {
    [self stubNilValuesForStoredAndCurrentVersions];
    NSDate *now = [NSDate date];
    [self stubAppInstallDate:nil buildDate:now];

    NSNumber *updateState = [BNCSystemObserver getUpdateState];
    XCTAssertEqualObjects(updateState, @0);

    [self clearMocks];
}

- (void)testGetUpdateStateWithNoStoredVersionAndNilUpdateDate {
    [self stubNilValuesForStoredAndCurrentVersions];
    NSDate *now = [NSDate date];
    [self stubAppInstallDate:now buildDate:nil];

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

#pragma mark - Internals

- (void)stubAppInstallDate:(NSDate *)installDate buildDate:(NSDate *)buildDate {
    [[BNCPreferenceHelper preferenceHelper] synchronize];
    
    self.fileManagerMock = OCMClassMock([NSFileManager class]);

    self.bundleAttributesMock = OCMClassMock([NSDictionary class]);
    [[[self.bundleAttributesMock stub] andReturn:installDate] fileCreationDate];
    [[[self.fileManagerMock stub]
        andReturn:self.bundleAttributesMock]
            attributesOfItemAtPath:[OCMArg any]
            error:(NSError __autoreleasing **)[OCMArg anyPointer]];

    //  OCMock result arrays need to be retained (sometimes?):
    self.retainArray = @[ [NSURL URLWithString:@"file://MyApp/_CodeSignature"] ];

    //self.docDirAttributesMock = OCMClassMock([NSDictionary class]);
    [[[self.fileManagerMock stub]
        andReturn:self.retainArray]
            contentsOfDirectoryAtURL:[OCMArg any]
            includingPropertiesForKeys:[OCMArg any]
            options:0
            error:(NSError __autoreleasing **)[OCMArg anyPointer]];

    self.URLMock = OCMClassMock([NSURL class]);
    OCMStub([self.URLMock getResourceValue:(NSDate __autoreleasing **)[OCMArg anyPointer]
        forKey:[OCMArg any]
        error:(NSError __autoreleasing **)[OCMArg anyPointer]];
    ).andDo(^(NSInvocation *invocation) {
        NSDate __autoreleasing **buildDatePtr;
        [invocation getArgument:&buildDatePtr atIndex:0];
        *buildDatePtr = buildDate;
        invocation.returnValue = (void*) YES;
    });
}

- (void)clearMocks {
    [self.fileManagerMock stopMocking];
    [self.docDirAttributesMock stopMocking];
    [self.bundleAttributesMock stopMocking];
    [self.URLMock stopMocking];
}

- (void)stubNilValuesForStoredAndCurrentVersions {
    [BNCPreferenceHelper preferenceHelper].appVersion = nil;
    [[BNCPreferenceHelper preferenceHelper] synchronize];
    id bundleMock = OCMClassMock([NSBundle class]);
    [[[bundleMock stub] andReturn:nil] mainBundle];
}

@end

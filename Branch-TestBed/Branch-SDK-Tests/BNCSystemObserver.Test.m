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

@interface BNCSystemObserverTests : BNCTestCase
@end

@implementation BNCSystemObserverTests

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

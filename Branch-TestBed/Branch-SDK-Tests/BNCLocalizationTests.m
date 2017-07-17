//
//  BNCLocalizationTests.m
//  Branch-TestBed
//
//  Created by Parth Kalavadia on 7/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCLocalization.h"

@interface BNCLocalizationTests : XCTestCase

@end

@implementation BNCLocalizationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmptyString {
    NSString* emptyStringLocalisation = BNCLocalizedString(@"");
    XCTAssertEqual(emptyStringLocalisation, @"");
}

- (void)testNilString {
    NSString* nilStringLocalization = BNCLocalizedString(nil);
    XCTAssertEqual(nilStringLocalization, nil);
}

- (void)testForNotAvailableLanguages {
    
}

- (void)testForAvailableLanguages {
    
}

- (void)testForAvailLanguageButStringNotAvail {
    
}

- (void)testForCorrectLocalisation {
    
}

@end

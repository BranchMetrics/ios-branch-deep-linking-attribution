//
//  BNCLocalizationTests.m
//  Branch-SDK
//
//  Created by Parth Kalavadia on 7/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCLocalization.h"

@interface BNCLocalization (Test)
+(NSDictionary*) getSupportedLanguages;
+(NSDictionary*) en_localised;
+(NSDictionary*) ru_localised;
@end

@interface BNCLocalizationTests : XCTestCase

@end

@implementation BNCLocalizationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testEmptyString {
    NSString* testString = @"";
    NSString* emptyStringLocalisation = BNCLocalizedString(testString);
    XCTAssertEqual(emptyStringLocalisation, testString);
}

- (void)testNilString {
    NSString* testString = nil;
    NSString* nilStringLocalization = BNCLocalizedString(testString);
    XCTAssertEqual(nilStringLocalization, nil);
}

- (void)testForNotAvailableLanguages {
    
    NSString* testString = @"Yes";
    NSString* preferredLang = @"hi";
    NSDictionary* localizedLanguage = [BNCLocalization getSupportedLanguages][preferredLang];
    localizedLanguage == nil?[BNCLocalization en_localised]:localizedLanguage;
    NSString* localizedString = localizedLanguage[testString];
    localizedString = localizedString == nil?testString:localizedString;
    XCTAssertEqual(localizedString, testString);
    
}

- (void)testForAvailableLanguages {
    NSString* testString = @"YES";
    [self measureBlock:^{
        NSString* localizedString = BNCLocalizedString(testString);
        NSString* expectedResult = @"Yes";
        XCTAssertEqual(localizedString, expectedResult);
    }];
}

- (void)testForAvailLanguageButStringNotAvail {
    NSString* testString = @"Star Wars";
    NSString* localizedString = BNCLocalizedString(testString);
    XCTAssertEqual(localizedString, testString);
}

- (void)testSymbolsAsString {
    NSString* testString = @"@%$$";
    NSString* localizedString = BNCLocalizedString(testString);
    XCTAssertEqual(localizedString, testString);
}

@end

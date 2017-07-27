

//--------------------------------------------------------------------------------------------------
//
//                                                                            BNCLocalization.Test.m
//                                                                                       BranchTests
//
//                                                                                Localization Tests
//                                                                           Edward Smith, July 2017
//
//                                             -©- Copyright © 2017 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import <XCTest/XCTest.h>
#import "BNCTestCase.h"
#import "BNCLocalization.h"


@interface BNCLocalizationTest : BNCTestCase
@end


@implementation BNCLocalizationTest

- (void) testLocalizationBasic {

    NSString *truth = nil;
    NSString *string = nil;
    BNCLocalizationSetLanguage(@"en");

    truth = @"Could not generate a URL.";
    string = BNCLocalizedString(truth);
    XCTAssertEqual(string, truth);

    truth = @"String not found: Should print a warning and return same string.";
    string = BNCLocalizedString(truth);
    XCTAssertEqual(string, truth);

    truth = @"";
    string = BNCLocalizedString(nil); // nil input should return empty string output.
    XCTAssertEqual(string, truth);
}

- (void) testLocalizationSpanish {

    NSString *truth = nil;
    NSString *string = nil;
    BNCLocalizationSetLanguage(@"es");

    string = @"Could not generate a URL.";
    truth = @"No se pudo generar una URL.";
    string = BNCLocalizedString(string);
    XCTAssertEqual(string, truth);
}

@end

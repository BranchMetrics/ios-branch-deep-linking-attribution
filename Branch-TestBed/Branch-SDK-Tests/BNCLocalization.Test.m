/**
 @file          BNCLocalization.Test.m
 @package       Branch-SDK
 @brief         Branch string localization tests.

 @author        Edward Smith
 @date          July 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCLocalization.h"

@interface BNCLocalizationTest : BNCTestCase
@end

@implementation BNCLocalizationTest

- (void) testLocalizationBasic {

    NSString *truth = nil;
    NSString *string = nil;
    [BNCLocalization shared].currentLanguage = @"en";

    truth = @"Could not generate a URL.";
    string = BNCLocalizedString(truth);
    XCTAssertEqualObjects(string, truth);

    truth = @"This string is not in table: Should print a warning and return same string.";
    string = BNCLocalizedString(truth);
    XCTAssertEqualObjects(string, truth);

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wall"
    // Nil input should return empty string output.
    truth = @"";
    string = BNCLocalizedString(nil);
    XCTAssertEqualObjects(string, truth);
    #pragma clang diagnostic pop

    // Test formatted language strings.
    truth = @"Test formatted language strings.";
    string = BNCLocalizedFormattedString(@"Test formatted %@ strings.", @"language");
    XCTAssertEqualObjects(string, truth);

    // Test formatted language strings with format checking:
    truth = @"Test formatted language strings float 1.00.";
    string = BNCLocalizedFormattedString(@"Test formatted %@ strings float %1.2f.", @"language", 1.0);
    XCTAssertEqualObjects(string, truth);

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wall"
    truth = @"";
    string = BNCLocalizedFormattedString(nil, 1.0);
    XCTAssertEqualObjects(string, truth);
    #pragma clang diagnostic pop
}

- (void) testLocalizationRussian {

    NSString *truth = nil;
    NSString *string = nil;
    [BNCLocalization shared].currentLanguage = @"ru";

    string = @"Could not generate a URL.";
    truth = @"Не получилось сгенерировать URL.";
    string = BNCLocalizedString(string);
    XCTAssertEqualObjects(string, truth);
}

- (void) testApplicationLanguage {
    // TODO: Write test for checking application language for different language bundles.
    XCTAssertEqualObjects([BNCLocalization applicationLanguage], @"en");
}

- (void) testSetWeirdLanguage {
    // App doesn't speak that.  Default to english.
    [BNCLocalization shared].currentLanguage = @"UFOAlienSpeak";
    XCTAssertEqualObjects([BNCLocalization shared].currentLanguage, @"en");
}

@end

//
//  BNCLocaleTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/19/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCLocale.h"

@interface BNCLocale()

- (nullable NSString *)country;
- (nullable NSString *)countryOS10;
- (nullable NSString *)countryOS9;
- (nullable NSString *)countryOS8;

- (nullable NSString *)language;
- (nullable NSString *)languageOS10;
- (nullable NSString *)languageOS9;
- (nullable NSString *)languageOS8;

@end

@interface BNCLocaleTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCLocale *locale;
@end

@implementation BNCLocaleTests

- (void)setUp {
    self.locale = [BNCLocale new];
}

- (void)tearDown {
    
}

// on iOS 10+ these all return the same value
- (void)testCounty {
    if (@available(iOS 10, *)) {
        NSString *expected = [NSLocale currentLocale].countryCode;
        NSString *actual = [self.locale country];
        XCTAssert([expected isEqualToString:actual]);
        
        actual = [self.locale countryOS10];
        XCTAssert([expected isEqualToString:actual]);
        
        actual = [self.locale countryOS8];
        XCTAssert([expected isEqualToString:actual]);
    }
}

// on iOS 10+ these all return the same value
- (void)testLanguage {
    if (@available(iOS 10, *)) {
        NSString *expected = [NSLocale currentLocale].languageCode;
        NSString *actual = [self.locale language];
        XCTAssert([expected isEqualToString:actual]);
        
        actual = [self.locale languageOS10];
        XCTAssert([expected isEqualToString:actual]);
        
        actual = [self.locale languageOS9];
        XCTAssert([expected isEqualToString:actual]);
        
        actual = [self.locale languageOS8];
        XCTAssert([expected isEqualToString:actual]);
    }
}

@end

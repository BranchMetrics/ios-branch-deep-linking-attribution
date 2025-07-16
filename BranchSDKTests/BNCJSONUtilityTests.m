//
//  BNCJSONUtilityTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 9/17/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCJSONUtility.h"
#import "BNCJsonLoader.h"

@interface BNCJSONUtilityTests : XCTestCase
@property (nonatomic, strong, readwrite) NSDictionary *json;
@end

@implementation BNCJSONUtilityTests

- (void)setUp {
    self.json = [BNCJsonLoader dictionaryFromJSONFileNamed:@"example"];
    XCTAssertNotNil(self.json);
}

- (void)tearDown {

}

- (void)testIsNumber {
    NSNumber *number = [NSNumber numberWithInt:314];
    XCTAssertTrue([BNCJSONUtility isNumber:number]);
}

- (void)testIsNumber_Boxed {
    XCTAssertTrue([BNCJSONUtility isNumber:@(1.0)]);
}

- (void)testIsNumber_Nil {
    XCTAssertFalse([BNCJSONUtility isNumber:nil]);
}

- (void)testIsNumber_String {
    XCTAssertFalse([BNCJSONUtility isNumber:@"1.0"]);
}

- (void)testIsString {
    XCTAssertTrue([BNCJSONUtility isString:@"1.0"]);
}

- (void)testIsString_MutableString {
    NSMutableString *string = [NSMutableString new];
    XCTAssertTrue([BNCJSONUtility isString:string]);
}

- (void)testIsString_EmptyString {
    XCTAssertTrue([BNCJSONUtility isString:@""]);
}

- (void)testIsString_Nil {
    XCTAssertFalse([BNCJSONUtility isString:nil]);
}

- (void)testIsString_Number {
    XCTAssertFalse([BNCJSONUtility isString:@(1.0)]);
}

- (void)testIsArray {
    NSArray *tmp = @[@1, @2];
    XCTAssertTrue([BNCJSONUtility isArray:tmp]);
}

- (void)testIsArray_MutableArray {
    NSMutableArray *tmp = [NSMutableArray new];
    XCTAssertTrue([BNCJSONUtility isArray:tmp]);
}

- (void)testIsArray_EmptyArray {
    XCTAssertTrue([BNCJSONUtility isArray:@[]]);
}

- (void)testIsArray_Nil {
    XCTAssertFalse([BNCJSONUtility isArray:nil]);
}

- (void)testIsArray_Dictionary {
    XCTAssertFalse([BNCJSONUtility isArray:[NSDictionary new]]);
}

// successful call on untyped dictionary
- (void)testUntypedDictionary_CorrectType {
    NSString *string = self.json[@"user_string"];
    XCTAssertNotNil(string);
    XCTAssertTrue(([string isKindOfClass:[NSString class]] || [string isKindOfClass:[NSMutableString class]]));
}

// demonstrates that an untyped dictionary can lead to type mismatches cause it always returns id
- (void)testUntypedDictionary_IncorrectType {
    NSString *string = self.json[@"user_number"];
    XCTAssertNotNil(string);
    XCTAssertTrue(([string isKindOfClass:[NSNumber class]]));
}

- (void)testStringForKey_InvalidKey {
    id key = @(1);
    NSString *string = [BNCJSONUtility stringForKey:key json:self.json];
    XCTAssertNil(string);
}

- (void)testStringForKey {
    NSString *string = [BNCJSONUtility stringForKey:@"user_string" json:self.json];
    XCTAssertNotNil(string);
    XCTAssertTrue(([string isKindOfClass:[NSString class]] || [string isKindOfClass:[NSMutableString class]]));
}

- (void)testStringForKey_IncorrectType {
    NSString *string = [BNCJSONUtility stringForKey:@"user_number" json:self.json];
    XCTAssertNil(string);
}

- (void)testNumberForKey {
    NSNumber *number = [BNCJSONUtility numberForKey:@"user_number" json:self.json];
    XCTAssertNotNil(number);
    XCTAssertTrue([number isKindOfClass:[NSNumber class]]);
}

- (void)testNumberForKey_IncorrectType {
    NSNumber *number = [BNCJSONUtility numberForKey:@"user_string" json:self.json];
    XCTAssertNil(number);
}

- (void)testDictionaryForKey {
    NSDictionary *dict = [BNCJSONUtility dictionaryForKey:@"user_dict" json:self.json];
    XCTAssertNotNil(dict);
    XCTAssertTrue(([dict isKindOfClass:NSDictionary.class] || [dict isKindOfClass:NSMutableDictionary.class]));
}

- (void)testDictionaryForKey_IncorrectType {
    NSDictionary *dict = [BNCJSONUtility dictionaryForKey:@"user_array" json:self.json];
    XCTAssertNil(dict);
}

- (void)testArrayForKey {
    NSArray *array = [BNCJSONUtility arrayForKey:@"user_array" json:self.json];
    XCTAssertNotNil(array);
    XCTAssertTrue(([array isKindOfClass:[NSArray class]] || [array isKindOfClass:[NSMutableArray class]]));
}

- (void)testArrayForKey_IncorrectType {
    NSArray *array = [BNCJSONUtility arrayForKey:@"user_dict" json:self.json];
    XCTAssertNil(array);
}

- (void)testStringArrayForKey {
    NSArray<NSString *> *array = [BNCJSONUtility stringArrayForKey:@"user_array" json:self.json];
    XCTAssertNotNil(array);
    XCTAssertTrue(array.count > 0);
}

- (void)testStringArrayForKey_MixedTypes {
    NSArray<NSString *> *array = [BNCJSONUtility stringArrayForKey:@"user_array_mixed" json:self.json];
    XCTAssertNotNil(array);
    XCTAssertTrue(array.count > 0);
}

- (void)testStringArrayForKey_Numbers {
    NSArray<NSString *> *array = [BNCJSONUtility stringArrayForKey:@"user_array_numbers" json:self.json];
    XCTAssertNotNil(array);
    XCTAssertTrue(array.count == 0);
}

- (void)testStringDictionaryForKey {
    NSDictionary<NSString *, NSString *> *dict = [BNCJSONUtility stringDictionaryForKey:@"user_dict" json:self.json];
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.count > 0);
}

- (void)testStringDictionaryForKey_MixedTypes {
    NSDictionary<NSString *, NSString *> *dict = [BNCJSONUtility stringDictionaryForKey:@"user_dict_mixed" json:self.json];
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.count > 0);
}

- (void)testStringDictionaryForKey_Numbers {
    NSDictionary<NSString *, NSString *> *dict = [BNCJSONUtility stringDictionaryForKey:@"user_dict_numbers" json:self.json];
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.count == 0);
}

@end

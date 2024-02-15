//
//  NSMutableDictionaryBranchTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 2/9/24.
//  Copyright © 2024 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableDictionary+Branch.h"

@interface NSMutableDictionaryBranchTests : XCTestCase

@end

@implementation NSMutableDictionaryBranchTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSafeSetObject_StringString {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_safeSetObject:@"foo" forKey:@"bar"];
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue([@"foo" isEqualToString:dict[@"bar"]]);
}

- (void)testSafeSetObject_NilString {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_safeSetObject:nil forKey:@"bar"];
    XCTAssertTrue(dict.count == 0);
}

- (void)testSafeSetObject_StringNil {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_safeSetObject:@"foo" forKey:nil];
    XCTAssertTrue(dict.count == 0);
}

- (void)testSafeAddEntriesFromDictionary {
    
    // NSStrings are never copied, so use NSMutableStrings
    NSMutableDictionary *other = [NSMutableDictionary new];
    other[@"foo"] = [[NSMutableString alloc] initWithString:@"bar"];
    other[@"hello"] = [[NSMutableString alloc] initWithString:@"world"];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_safeAddEntriesFromDictionary:other];
    
    NSArray *keyset = [other allKeys];
    for (id key in keyset) {
        id original = other[key];
        id copy = dict[key];
        
        // same object value
        XCTAssertTrue([original isEqual:copy]);
        
        // different object instance
        XCTAssertTrue(original != copy);
    }
}

- (void)testSafeAddEntriesFromDictionary_NestedArray {
    
    // NSStrings are never copied, so use NSMutableStrings
    NSMutableDictionary *other = [NSMutableDictionary new];
    other[@"foo"] = [[NSMutableString alloc] initWithString:@"bar"];
    other[@"hello"] = [[NSMutableString alloc] initWithString:@"world"];
    
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:[[NSMutableString alloc] initWithString:@"dog"]];
    [array addObject:[[NSMutableString alloc] initWithString:@"cat"]];
    [array addObject:[[NSMutableString alloc] initWithString:@"child"]];
    
    other[@"good"] = array;
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_safeAddEntriesFromDictionary:other];
    
    NSArray *keyset = [other allKeys];
    for (id key in keyset) {
        id original = other[key];
        id copy = dict[key];
        
        // same object value
        XCTAssertTrue([original isEqual:copy]);
        
        // different object instance
        XCTAssertTrue(original != copy);
    }
    
    // confirm that copyItems is a one layer deep copy
    NSArray *arrayCopy = dict[@"good"];
    XCTAssertTrue(array.count == arrayCopy.count);
    XCTAssertTrue(array != arrayCopy);
    
    for (int i=0; i<array.count; i++) {
        // contents are the same, unlike top level strings
        XCTAssertTrue(array[i] == arrayCopy[i]);
    }
}

- (void)testAddString_String {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addString:@"foo" forKey:@"bar"];
    
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue([@"foo" isEqualToString:dict[@"bar"]]);
}

// the only difference from bnc_safeSetObject is that empty strings are omitted as well
- (void)testAddString_StringEmpty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addString:@"" forKey:@"bar"];
    
    XCTAssertTrue(dict.count == 0);
}

- (void)testAddDate_Date {
    NSDate *date = [NSDate date];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addDate:date forKey:@"date"];
    
    // Dates are saved as NSNumber
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue([dict[@"date"] isKindOfClass:[NSNumber class]]);
    
    // check the number value
    NSTimeInterval t = date.timeIntervalSince1970;
    NSNumber *tmp = [NSNumber numberWithLongLong:(long long)(t*1000.0)];
    XCTAssertTrue([tmp isEqual:dict[@"date"]]);
}

- (void)testAddDouble_10 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addDouble:10.0 forKey:@"double"];
    
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue([dict[@"double"] isKindOfClass:[NSNumber class]]);
    
    NSNumber *tmp = dict[@"double"];
    XCTAssertTrue(tmp.doubleValue == 10.0);
}

- (void)testAddDouble_neg10 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addDouble:-10.0 forKey:@"double"];
    
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue([dict[@"double"] isKindOfClass:[NSNumber class]]);
    
    NSNumber *tmp = dict[@"double"];
    XCTAssertTrue(tmp.doubleValue == -10.0);
}

// 0 is ignored
- (void)testAddDouble_0 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addDouble:0.0 forKey:@"double"];
    
    XCTAssertTrue(dict.count == 0);
}

- (void)testAddBoolean_YES {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addBoolean:YES forKey:@"bool"];
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue(dict[@"bool"]);
}

// omits NO...
- (void)testAddBoolean_NO {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict bnc_addBoolean:NO forKey:@"bool"];
    XCTAssertTrue(dict.count == 0);
}

// there is no difference between this and bnc_safeSetObject
- (void)testAddDecimal_10 {
    NSDecimalNumber *num = [NSDecimalNumber decimalNumberWithString:@"1.1"];
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_addDecimal:num forKey:@"decimal"];
    XCTAssertTrue(dict.count == 1);
    
    // this is using NSNumber check that the NSDecimalNumber is 1.1
    XCTAssertTrue([@(1.1) isEqual:dict[@"decimal"]]);
}

// there is no difference between this and bnc_safeSetObject
- (void)testAddDecimal_Nil {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_addDecimal:nil forKey:@"decimal"];
    XCTAssertTrue(dict.count == 0);
}

- (void)testAddInteger_10 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_addInteger:10 forKey:@"int"];
    XCTAssertTrue(dict.count == 1);
    
    XCTAssertTrue([@(10) isEqual:dict[@"int"]]);
}

- (void)testAddInteger_neg10 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_addInteger:-10 forKey:@"int"];
    XCTAssertTrue(dict.count == 1);
    
    XCTAssertTrue([@(-10) isEqual:dict[@"int"]]);
}

// 0 is omitted
- (void)testAddInteger_0 {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict bnc_addInteger:0 forKey:@"int"];
    XCTAssertTrue(dict.count == 0);
}

- (void)testAddDictionary_NonEmpty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSDictionary *subDict = @{
        @"foo" : @"bar"
    };
    
    [dict bnc_addDictionary:subDict forKey:@"subDict"];
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue(subDict == dict[@"subDict"]);
}

// empty dictionaries are omitted
- (void)testAddDictionary_Empty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSDictionary *subDict = @{ };
    
    [dict bnc_addDictionary:subDict forKey:@"subDict"];
    XCTAssertTrue(dict.count == 0);
}

- (void)testAddArray_NonEmpty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSArray *subArray = @[ @"hello world" ];
    
    [dict bnc_addStringArray:subArray forKey:@"subArray"];
    XCTAssertTrue(dict.count == 1);
    XCTAssertTrue(subArray == dict[@"subArray"]);
}

// empty arrays are omitted
- (void)testAddArray_Empty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSArray *subArray = @[ ];
    
    [dict bnc_addStringArray:subArray forKey:@"subArray"];
    XCTAssertTrue(dict.count == 0);
}

- (void)testGetIntForKey {
    NSDictionary *tmp = @{
        @"int1" : @(1),
        @"int2" : @"2",
        @"int3" : @[ ], // invalid int, returns 0
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue(1 == [dict bnc_getIntForKey:@"int1"]);
    XCTAssertTrue(2 == [dict bnc_getIntForKey:@"int2"]);
    XCTAssertTrue(0 == [dict bnc_getIntForKey:@"int3"]);
}

- (void)testGetDoubleForKey {
    NSDictionary *tmp = @{
        @"double1" : @(1.1),
        @"double2" : @"2.2",
        @"double3" : @[ ], // invalid double, returns 0
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue(1.1 == [dict bnc_getDoubleForKey:@"double1"]);
    XCTAssertTrue(2.2 == [dict bnc_getDoubleForKey:@"double2"]);
    XCTAssertTrue(0 == [dict bnc_getDoubleForKey:@"double3"]);
}

- (void)testGetStringForKey {
    NSDictionary *tmp = @{
        @"string1" : @"hello world",
        @"string2" : [NSMutableString stringWithString:@"goodbye world"],
        @"string3" : @[ ], // invalid string
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue([@"hello world" isEqualToString:[dict bnc_getStringForKey:@"string1"]]);
    XCTAssertTrue([@"goodbye world" isEqualToString:[dict bnc_getStringForKey:@"string2"]]);
    XCTAssertNil([dict bnc_getStringForKey:@"string3"]);
}

- (void)testGetDateForKey {
    NSDictionary *tmp = @{
        @"date1" : @(1707528943914),
        @"date2" : @"1707528943914",
        @"date3" : @(0), // invalid date
        @"date4" : [NSDate date], // invalid date. Server does not accept or return NSDate in JSONs
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue([[dict bnc_getDateForKey:@"date1"] isKindOfClass:[NSDate class]]);
    XCTAssertTrue([[dict bnc_getDateForKey:@"date2"] isKindOfClass:[NSDate class]]);
    XCTAssertNil([dict bnc_getDateForKey:@"date3"]);
    XCTAssertNil([dict bnc_getDateForKey:@"date4"]);
}

- (void)testGetDecimalForKey {
    NSDictionary *tmp = @{
        @"decimal1" : @(1.1),
        @"decimal2" : @"2.2",
        @"decimal3" : [NSDecimalNumber decimalNumberWithString:@"3.3"],
        @"decimal4" : @"abc", // invalid decimal, returns NSDecimalNumber.notANumber
        @"decimal5" : @[ ] // invalid decimal, return nil
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue([@(1.1) isEqual:[dict bnc_getDecimalForKey:@"decimal1"]]);
    XCTAssertTrue([@(2.2) isEqual:[dict bnc_getDecimalForKey:@"decimal2"]]);
    XCTAssertTrue([@(3.3) isEqual:[dict bnc_getDecimalForKey:@"decimal3"]]);
    XCTAssertTrue(NSDecimalNumber.notANumber == [dict bnc_getDecimalForKey:@"decimal4"]);
    XCTAssertNil([dict bnc_getDecimalForKey:@"decimal5"]);
}

- (void)testGetArrayForKey {
    NSDictionary *tmp = @{
        @"array1" : @[ @"foo", @"bar" ],
        @"array2" : @"hello world", // valid array, is converted to an array with the string in it
        @"array3" : @(1), // invalid array, returns an empty array
    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue([[dict bnc_getArrayForKey:@"array1"] isKindOfClass:[NSArray class]]);
    XCTAssertTrue(((NSArray *)[dict bnc_getArrayForKey:@"array1"]).count == 2);

    XCTAssertTrue([[dict bnc_getArrayForKey:@"array2"] isKindOfClass:[NSArray class]]);
    XCTAssertTrue(((NSArray *)[dict bnc_getArrayForKey:@"array2"]).count == 1);
    
    XCTAssertTrue([[dict bnc_getArrayForKey:@"array3"] isKindOfClass:[NSArray class]]);
    XCTAssertTrue(((NSArray *)[dict bnc_getArrayForKey:@"array3"]).count == 0);
}

- (void)testGetBooleanForKey {
    NSDictionary *tmp = @{
        @"bool1" : @(1),
        @"bool2" : @(0),
        @"bool3" : @"1", // valid bool
        @"bool4" : @"0", // valid bool
        @"bool5" : @"YES", // invalid bool, server expects a number. treated as false
        @"bool6" : @"NO", // invalid bool, server expects a number. treated as false
        @"bool7" : @(-1), // all non-zero numbers are true
        @"bool8" : @(1234), // all non-zero numbers are true
        @"bool9" : @[ ] // invalid bool, treated as false

    };
    NSMutableDictionary *dict = [tmp mutableCopy];
    
    XCTAssertTrue([dict bnc_getBooleanForKey:@"bool1"]);
    XCTAssertFalse([dict bnc_getBooleanForKey:@"bool2"]);
    XCTAssertTrue([dict bnc_getBooleanForKey:@"bool3"]);
    XCTAssertFalse([dict bnc_getBooleanForKey:@"bool4"]);
    XCTAssertFalse([dict bnc_getBooleanForKey:@"bool5"]);
    XCTAssertFalse([dict bnc_getBooleanForKey:@"bool6"]);
    XCTAssertTrue([dict bnc_getBooleanForKey:@"bool7"]);
    XCTAssertTrue([dict bnc_getBooleanForKey:@"bool8"]);
    XCTAssertFalse([dict bnc_getBooleanForKey:@"bool9"]);
}

@end

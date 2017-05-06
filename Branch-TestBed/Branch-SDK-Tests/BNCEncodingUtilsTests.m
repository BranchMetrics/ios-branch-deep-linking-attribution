//
//  BNCEncodingUtils.m
//  Branch
//
//  Created by Graham Mueller on 4/1/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCEncodingUtils.h"
#import "BNCTestCase.h"

@interface BNCEncodingUtilsTests : BNCTestCase
@end

@implementation BNCEncodingUtilsTests

#pragma mark - EncodeDictionaryToJsonString tests

- (void)testEncodeDictionaryToJsonStringWithExpectedParams {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate *date = [dateFormatter dateFromString:@"2015-04-01T00:00:00-05:00"];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    NSURL *someUrl = [NSURL URLWithString:@"https://branch.io"];
    NSDictionary *dataDict = @{ @"foo": @"bar", @"num": @1, @"array": @[ @"array", @"items" ], @"dict": @{ @"sub": @1 }, @"url": someUrl, @"date": date };
    NSString *expectedEncodedString = [NSString stringWithFormat:@"{\"foo\":\"bar\",\"num\":1,\"array\":[\"array\",\"items\"],\"dict\":{\"sub\":1},\"url\":\"https://branch.io\",\"date\":\"%@\"}", formattedDateString];
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringWithUnexpectedParams {
    NSObject *arbitraryObj = [[NSObject alloc] init];
    NSDictionary *dataDict = @{ @"foo": @"bar", @"random": arbitraryObj };
    NSString *expectedEncodedString = @"{\"foo\":\"bar\"}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringStringWithNull {
    NSDictionary *dataDict = @{ @"foo": [NSNull null] };
    NSString *expectedEncodedString = @"{\"foo\":null}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodingNilDictionaryToJsonString {
    NSDictionary *dataDict = nil;
    NSString *expectedEncodedString = @"{}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringWithNoKeys {
    NSDictionary *emptyDict = @{ };
    NSString *expectedEncodedString = @"{}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:emptyDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringWithQuotes {
    NSDictionary *dictionaryWithQuotes = @{ @"my\"cool\"key": @"my\"cool\"value" };
    NSString *expectedEncodedString = @"{\"my\\\"cool\\\"key\":\"my\\\"cool\\\"value\"}";
 
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dictionaryWithQuotes];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testSimpleEncodeDictionaryToJsonData {
    NSDictionary *dataDict = @{ @"foo": @"bar" };
    NSData *expectedEncodedData = [@"{\"foo\":\"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonData:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedData, encodedValue);
}

- (void)testEncodeDictionaryToQueryString {
    NSDictionary *dataDict = @{ @"foo": @"bar", @"something": @"something & something" };
    NSString *expectedEncodedString = @"?foo=bar&something=something%20%26%20something";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToQueryString:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}


#pragma mark - EncodeArrayToJsonString

- (void)testEncodeArrayToJsonStringWithExpectedParams {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate *date = [dateFormatter dateFromString:@"2015-04-01T00:00:00Z"];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    NSURL *someUrl = [NSURL URLWithString:@"https://branch.io"];
    NSArray *dataArray = @[ @"bar", @1, @[ @"array", @"items" ], @{ @"sub": @1 }, someUrl, date ];
    NSString *expectedEncodedString = [NSString stringWithFormat:@"[\"bar\",1,[\"array\",\"items\"],{\"sub\":1},\"https://branch.io\",\"%@\"]", formattedDateString];
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:dataArray];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeArrayToJsonStringWithUnexpectedParams {
    NSObject *arbitraryObj = [[NSObject alloc] init];
    NSArray *dataArray = @[ @"bar", arbitraryObj ];
    NSString *expectedEncodedString = @"[\"bar\"]";
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:dataArray];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeArrayToJsonStringStringWithNull {
    NSArray *dataArray = @[ [NSNull null] ];
    NSString *expectedEncodedString = @"[null]";
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:dataArray];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeArrayToJsonStringWithNoValues {
    NSArray *emptyArray = @[ ];
    NSString *expectedEncodedString = @"[]";
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:emptyArray];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodingEmptyArrayToJsonString {
    NSArray *emptyArray = nil;
    NSString *expectedEncodedString = @"[]";
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:emptyArray];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeArrayToJsonStringWithQuotes {
    NSArray *arrayWithQuotes = @[ @"my\"cool\"value1", @"my\"cool\"value2" ];
    NSString *expectedEncodedString = @"[\"my\\\"cool\\\"value1\",\"my\\\"cool\\\"value2\"]";
    
    NSString *encodedValue = [BNCEncodingUtils encodeArrayToJsonString:arrayWithQuotes];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}


#pragma mark - Character Length tests

- (void)testChineseCharactersWithLengthGreaterThanOne {
    NSString *multiCharacterString = @"𥑮";
    NSDictionary *jsonDict = @{ @"foo": multiCharacterString };
    NSString *expectedEncoding = @"{\"foo\":\"𥑮\"}";
    NSInteger expectedLength = [expectedEncoding lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonData:jsonDict];
    
    XCTAssertEqual(expectedLength, [encodedValue length]);
}


#pragma mark - DecodeToDictionary tests

- (void)testDecodeJsonDataToDictionary {
    NSData *encodedData = [@"{\"foo\":\"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expectedDataDict = @{ @"foo": @"bar" };

    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonDataToDictionary:encodedData];

    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeJsonStringToDictionary {
    NSString *encodedString = @"{\"foo\":\"bar\"}";
    NSDictionary *expectedDataDict = @{ @"foo": @"bar" };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeJsonStringToDictionaryWithNilDecodedString {
    char badCStr[5] = { '{', 'f', ':', 'o', '}' }; // not nil terminated
    NSString *encodedString = [NSString stringWithUTF8String:badCStr];
    NSDictionary *expectedDataDict = @{ };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeBase64EncodedJsonStringToDictionary {
    NSString *encodedString = [BNCEncodingUtils base64EncodeStringToString:@"{\"foo\":\"bar\"}"];
    NSDictionary *expectedDataDict = @{ @"foo": @"bar" };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeNonASCIIString {
    // Should fail, but not crash.
    NSString* result = [BNCEncodingUtils base64DecodeStringToString:@"𝄞"];
    XCTAssertNil(result);
}

- (void)testDecodeBase64JsonStringToDictionaryWithNilDecodedString {
    char badCStr[5] = { '{', 'f', ':', 'o', '}' }; // not nil terminated
    NSString *encodedString = [NSString stringWithUTF8String:badCStr];
    NSString *base64EncodedString = [BNCEncodingUtils base64EncodeStringToString:encodedString];
    NSDictionary *expectedDataDict = @{ };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:base64EncodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeQueryStringToDictionary {
    NSString *encodedString = @"foo=bar&baz=1&quux=&quo=Hi%20there";
    NSDictionary *expectedDataDict = @{ @"foo": @"bar", @"baz": @"1", @"quo": @"Hi there" }; // always goes to string
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeQueryStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

#pragma mark - Test Util methods

- (NSString *)stringForDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]; // POSIX to avoid weird issues
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    });
    
    return [dateFormatter stringFromDate:date];
}

#pragma mark - Hex String Tests

- (void) testHexStringFromData {

    NSString *s = nil;

    s = [BNCEncodingUtils hexStringFromData:[NSData data]];
    XCTAssertEqualObjects(s, @"");

    unsigned char bytes1[] = { 0x01 };
    s = [BNCEncodingUtils hexStringFromData:[NSData dataWithBytes:bytes1 length:1]];
    XCTAssertEqualObjects(s, @"01");

    unsigned char bytes2[] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef
    };
    NSString *truth =
        @"000102030405060708090A0B0C0D0E0F"
         "E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF";

    s = [BNCEncodingUtils hexStringFromData:[NSData dataWithBytes:bytes2 length:32]];
    XCTAssertEqualObjects(s, truth);
}

@end

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

#if 0

// From Ed: See note below
- (void)testDecodeJsonStringToDictionaryWithNilDecodedString {
    char badCStr[5] = { '{', 'f', ':', 'o', '}' }; // not nil terminated
    NSString *encodedString = [NSString stringWithUTF8String:badCStr];
    NSDictionary *expectedDataDict = @{ };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

#else 

- (void)testDecodeJsonStringToDictionaryWithNilDecodedString {
    NSString *encodedString = nil;
    NSDictionary *expectedDataDict = @{ };
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

#endif

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

#if 0

// From Ed: I don't get the point of this test.
// It reads memory from the stack as a C string and decodes it as an NSString?
// The test itself won't run consistently and may fault sometimes.
- (void)testDecodeBase64JsonStringToDictionaryWithNilDecodedString {
    char badCStr[5] = { '{', 'f', ':', 'o', '}' }; // not nil terminated
    NSString *encodedString = [NSString stringWithUTF8String:badCStr];
    NSString *base64EncodedString = [BNCEncodingUtils base64EncodeStringToString:encodedString];
    NSDictionary *expectedDataDict = @{ };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:base64EncodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

#else 

// This should do the same thing without faulting during the test.
- (void)testDecodeBase64JsonStringToDictionaryWithNilDecodedString {
    NSString *base64EncodedString = nil;
    NSDictionary *expectedDataDict = @{ };
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:base64EncodedString];
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

#endif

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

#pragma mark - Base64EncodeData Tests

#define _countof(array)  (sizeof(array)/sizeof(array[0]))

- (void)testBase64EncodeData {
    NSData   *data = nil;
    NSString *truth = nil;
    NSString *string = nil;

    string = [BNCEncodingUtils base64EncodeData:nil];
    XCTAssertEqualObjects(string, @"");

    string = [BNCEncodingUtils base64EncodeData:[NSData new]];
    XCTAssertEqualObjects(string, @"");

    uint8_t b1[] = {0, 1, 2, 3, 4, 5};
    data = [[NSData alloc] initWithBytes:b1 length:_countof(b1)];
    truth = @"AAECAwQF";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    // Test that 1, 2, 3, 4, 5 length data encode correctly.

    data = [[NSData alloc] initWithBytes:b1 length:1];
    truth = @"AA==";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    data = [[NSData alloc] initWithBytes:b1 length:2];
    truth = @"AAE=";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    data = [[NSData alloc] initWithBytes:b1 length:3];
    truth = @"AAEC";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    data = [[NSData alloc] initWithBytes:b1 length:4];
    truth = @"AAECAw==";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    data = [[NSData alloc] initWithBytes:b1 length:5];
    truth = @"AAECAwQ=";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);

    uint8_t b2[] = {
        0x00, 0x10, 0x83, 0x10, 0x51, 0x87, 0x20, 0x92, 0x8B, 0x30, 0xD3, 0x8F, 0x41, 0x14, 0x93, 0x51,
        0x55, 0x97, 0x61, 0x96, 0x9B, 0x71, 0xD7, 0x9F, 0x82, 0x18, 0xA3, 0x92, 0x59, 0xA7, 0xA2, 0x9A,
        0xAB, 0xB2, 0xDB, 0xAF, 0xC3, 0x1C, 0xB3, 0xD3, 0x5D, 0xB7, 0xE3, 0x9E, 0xBB, 0xF3, 0xDF, 0xBF,
    };
    data = [[NSData alloc] initWithBytes:b2 length:_countof(b2)];
    truth = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string = [BNCEncodingUtils base64EncodeData:data];
    XCTAssertEqualObjects(string, truth);
}

- (void)testBase64DecodeString {
    NSData   *data = nil;

    data = [BNCEncodingUtils base64DecodeString:nil];
    XCTAssertEqual(data, nil);

    data = [BNCEncodingUtils base64DecodeString:@""];
    XCTAssertEqualObjects(data, [NSData new]);

    uint8_t truth[] = {0, 1, 2, 3, 4, 5};

    data = [BNCEncodingUtils base64DecodeString:@"AAECAwQF"];
    XCTAssertTrue( data.length == 6 && memcmp(data.bytes, truth, 6) == 0 );

    // Test that 1, 2, 3, 4, 5 length data encode correctly.

    #define testDecode(string, dataLength) { \
        data = [BNCEncodingUtils base64DecodeString:string]; \
        XCTAssertTrue( data.length == dataLength && memcmp(data.bytes, truth, dataLength) == 0 ); \
    }

    testDecode(@"AA==", 1);
    testDecode(@"AAE=", 2);
    testDecode(@"AAEC", 3);
    testDecode(@"AAECAw==", 4);
    testDecode(@"AAECAwQ=", 5);

    uint8_t b2[] = {
        0x00, 0x10, 0x83, 0x10, 0x51, 0x87, 0x20, 0x92, 0x8B, 0x30, 0xD3, 0x8F, 0x41, 0x14, 0x93, 0x51,
        0x55, 0x97, 0x61, 0x96, 0x9B, 0x71, 0xD7, 0x9F, 0x82, 0x18, 0xA3, 0x92, 0x59, 0xA7, 0xA2, 0x9A,
        0xAB, 0xB2, 0xDB, 0xAF, 0xC3, 0x1C, 0xB3, 0xD3, 0x5D, 0xB7, 0xE3, 0x9E, 0xBB, 0xF3, 0xDF, 0xBF,
    };
    data = [BNCEncodingUtils base64DecodeString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"];
    XCTAssertTrue( data.length == _countof(b2) && memcmp(data.bytes, b2, _countof(b2)) == 0 );

    // Test decode invalid data
    data = [BNCEncodingUtils base64DecodeString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcde (Junk:%&*^**) fghijklmnopqrstuvwxyz0123456789+/"];
    XCTAssertEqual(data, nil);
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

    s = [BNCEncodingUtils hexStringFromData:[NSData dataWithBytes:bytes2 length:sizeof(bytes2)]];
    XCTAssertEqualObjects(s, truth);
}

- (void) testDataFromHexString {

    NSData *data = nil;

    // nil
    data = [BNCEncodingUtils dataFromHexString:nil];
    XCTAssertEqual(data, nil);

    // empty string
    data = [BNCEncodingUtils dataFromHexString:@""];
    XCTAssertEqualObjects(data, [NSData data]);

    // upper string
    unsigned char bytes[] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef
    };

    NSString *stringUpper =
        @"000102030405060708090A0B0C0D0E0F"
         "E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF";

    data = [BNCEncodingUtils dataFromHexString:stringUpper];
    XCTAssertEqualObjects(data, [NSData dataWithBytes:bytes length:sizeof(bytes)]);

    // lower string

    NSString *stringLower =
        @"000102030405060708090a0b0c0d0e0f"
         "e0e1e2e3e4e5e6e7e8e9eaebecedeeef";

    data = [BNCEncodingUtils dataFromHexString:stringLower];
    XCTAssertEqualObjects(data, [NSData dataWithBytes:bytes length:sizeof(bytes)]);

    // white space

    NSString *stringWS =
        @"  000102030405060708090a0b0c0d0e0f\n"
         "e0e1e2e3e4e5e6\t\t\te7e8e9eaebeced\vee\ref";

    data = [BNCEncodingUtils dataFromHexString:stringWS];
    XCTAssertEqualObjects(data, [NSData dataWithBytes:bytes length:sizeof(bytes)]);

    // odd number of charaters

    NSString *stringShort =
        @"000102030405060708090a0b0c0d0e0f"
         "e0e1e2e3e4e5e6e7e8e9eaebecedeee";

    data = [BNCEncodingUtils dataFromHexString:stringShort];
    XCTAssertEqual(data, nil);

    // invalid characters

    NSString *stringInvalid =
        @"000102030405060708090a0b0c0d0e0fInvalid"
         "e0e1e2e3e4e5e6e7e8e9eaebecedeeef";

    data = [BNCEncodingUtils dataFromHexString:stringInvalid];
    XCTAssertEqual(data, nil);

    // singles

    NSString *stringShortShort1 = @"A";
    data = [BNCEncodingUtils dataFromHexString:stringShortShort1];
    XCTAssertEqual(data, nil);

    NSString *stringShortShort2 = @"af";
    unsigned char stringShortShort2Bytes[] = { 0xaf };
    data = [BNCEncodingUtils dataFromHexString:stringShortShort2];
    XCTAssertEqualObjects(data, [NSData dataWithBytes:stringShortShort2Bytes length:1]);
}

- (void) testPercentDecoding {

    NSString *s = nil;
    s = [BNCEncodingUtils stringByPercentDecodingString:nil];
    XCTAssert(s == nil);

    NSArray* tests = @[
        @"",
        @"",

        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",

        @"-._~",
        @"-._~",

        @"one%20two",
        @"one two",

        // @"one+two",
        // @"one two",

        @"one%2Btwo",
        @"one+two",

        @"%21%23%24%26%27%28%29%2A%2B%2C%3A%3B%3D%40%5B%5D",
        @"!#$&'()*+,:;=@[]",
    ];

    for (int i = 0; i < tests.count; i+=2) {
        NSString *result = [BNCEncodingUtils stringByPercentDecodingString:tests[i]];
        XCTAssertEqualObjects(result, tests[i+1]);
    }
}

- (void) testQueryItems {

    NSURL *URL = nil;
    NSArray<BNCKeyValue*>* items = nil;
    NSArray<BNCKeyValue*>* expected = nil;

    items = [BNCEncodingUtils queryItems:URL];
    XCTAssert(items != nil  && items.count == 0);

    URL = [NSURL URLWithString:@"http://example.com/thus?a=1&a=2&b=3"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"a" value:@"1"], [BNCKeyValue key:@"a" value:@"2"], [BNCKeyValue key:@"b" value:@"3"] ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?="];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?a="];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"a" value:@""] ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?=1"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"" value:@"1"] ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?a=1&"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"a" value:@"1"] ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?a=1&&b=2"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"a" value:@"1"], [BNCKeyValue key:@"b" value:@"2"] ];
    XCTAssertEqualObjects(items, expected);

    URL = [NSURL URLWithString:@"http://example.com/thus?a=1&b==2"];
    items = [BNCEncodingUtils queryItems:URL];
    expected = @[ [BNCKeyValue key:@"a" value:@"1"], [BNCKeyValue key:@"b" value:@"=2"] ];
    XCTAssertEqualObjects(items, expected);
}

@end

//
//  BNCEncodingUtils.m
//  Branch
//
//  Created by Graham Mueller on 4/1/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCEncodingUtils.h"

@interface BNCEncodingUtilsTests : XCTestCase

@end

@implementation BNCEncodingUtilsTests

#pragma mark - EncodeDictionaryToJsonString tests

- (void)testEncodeDictionaryToJsonStringWithExpectedParams {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate *date = [dateFormatter dateFromString:@"2015-04-01T00:00:00-05:00"];
    
    NSURL *someUrl = [NSURL URLWithString:@"https://branch.io"];
    NSDictionary *dataDict = @{ @"foo": @"bar", @"num": @1, @"array": @[ @"array", @"items" ], @"dict": @{ @"sub": @1 }, @"url": someUrl, @"date": date };
    NSString *expectedEncodedString = @"{\"foo\":\"bar\",\"num\":1,\"array\":[\"array\",\"items\"],\"dict\":{\"sub\":1},\"url\":\"https://branch.io\",\"date\":\"2015-04-01T00:00:00-05:00\"}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringWithUnexpectedParams {
    NSObject *arbitraryObj = [[NSObject alloc] init];
    NSDictionary *dataDict = @{ @"foo": @"bar", @"random": arbitraryObj };
    NSString *expectedEncodedString = @"{\"foo\":\"bar\"}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringStringWithNull {
    NSDictionary *dataDict = @{ @"foo": [NSNull null] };
    NSString *expectedEncodedString = @"{\"foo\":null}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict needSource:NO];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testEncodeDictionaryToJsonStringWithSubDictWithNeedSource {
    NSDictionary *dataDict = @{ @"root": @{ @"sub": @1 } };
    NSString *expectedEncodedString = @"{\"root\":{\"sub\":1},\"source\":\"ios\"}";
    
    NSString *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonString:dataDict needSource:YES];
    
    XCTAssertEqualObjects(expectedEncodedString, encodedValue);
}

- (void)testSimpleEncodeDictionaryToJsonData {
    NSDictionary *dataDict = @{ @"foo": @"bar" };
    NSData *expectedEncodedData = [@"{\"foo\":\"bar\",\"source\":\"ios\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *encodedValue = [BNCEncodingUtils encodeDictionaryToJsonData:dataDict];
    
    XCTAssertEqualObjects(expectedEncodedData, encodedValue);
}


#pragma mark - EncodeArrayToJsonString

- (void)testEncodeArrayToJsonStringWithExpectedParams {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    NSDate *date = [dateFormatter dateFromString:@"2015-04-01T00:00:00-05:00"];
    
    NSURL *someUrl = [NSURL URLWithString:@"https://branch.io"];
    NSArray *dataArray = @[ @"bar", @1, @[ @"array", @"items" ], @{ @"sub": @1 }, someUrl, date ];
    NSString *expectedEncodedString = @"[\"bar\",1,[\"array\",\"items\"],{\"sub\":1},\"https://branch.io\",\"2015-04-01T00:00:00-05:00\"]";
    
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

- (void)testDecodeBase64EncodedJsonStringToDictionary {
    NSString *encodedString = [BNCEncodingUtils base64EncodeStringToString:@"{\"foo\":\"bar\"}"];
    NSDictionary *expectedDataDict = @{ @"foo": @"bar" };
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeJsonStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

- (void)testDecodeQueryStringToDictionary {
    NSString *encodedString = @"foo=bar&baz=1&quux=&quo=Hi%20there";
    NSDictionary *expectedDataDict = @{ @"foo": @"bar", @"baz": @"1", @"quo": @"Hi there" }; // always goes to string
    
    NSDictionary *decodedValue = [BNCEncodingUtils decodeQueryStringToDictionary:encodedString];
    
    XCTAssertEqualObjects(decodedValue, expectedDataDict);
}

@end

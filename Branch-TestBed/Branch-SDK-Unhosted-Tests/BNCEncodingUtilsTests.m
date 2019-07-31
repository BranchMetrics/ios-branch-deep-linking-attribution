//
//  BNCEncodingUtilsTests.m
//  Branch-SDK-Unhosted-Tests
//
//  Created by Ernest Cho on 5/17/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCEncodingUtils.h"

@interface BNCEncodingUtilsTests : XCTestCase

@end

@implementation BNCEncodingUtilsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void) testSanitizeString {
    NSString*test  = @"\b\f\n\r\t\"`\\";
    NSString*truth = @"\\b\\f\\n\\r\\t\\\"'\\\\";
    NSString*result = [BNCEncodingUtils sanitizedStringFromString:test];
    XCTAssertEqualObjects(result, truth);
}

- (void)testSanitizeStringWithNil {
    NSString *result = [BNCEncodingUtils sanitizedStringFromString:nil];
    XCTAssertNil(result);
}

// INTENG-6187 bad access crash
- (void)testEncodeDictionaryToJsonStringCrashTest {
    NSString *expectedString = @"{\"World\":\"Hello\"}";
    
    // untyped collection
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:@"Hello" forKey:@"World"];
    [params setObject:@"Goodbye" forKey:@(100)];
    
    // encodeDictionaryToJsonString should ignore non-string keys
    NSString *result = [BNCEncodingUtils encodeDictionaryToJsonString:params];
    XCTAssertTrue([expectedString isEqualToString:result]);
}

@end

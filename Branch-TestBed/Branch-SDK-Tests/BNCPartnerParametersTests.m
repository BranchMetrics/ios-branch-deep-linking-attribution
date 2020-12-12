//
//  BNCPartnerParametersTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 12/9/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPartnerParameters.h"

// expose private methods for testing
@interface BNCPartnerParameters()
- (BOOL)sha256HashSanityCheckValue:(NSString *)value;
- (BOOL)isStringHex:(NSString *)string;
@end

@interface BNCPartnerParametersTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCPartnerParameters *partnerParams;
@end

@implementation BNCPartnerParametersTests

- (void)setUp {
    self.partnerParams = [BNCPartnerParameters new];
}

- (void)tearDown {
    
}

- (void)testStringHexNil {
    XCTAssertFalse([self.partnerParams isStringHex:nil]);
}

- (void)testStringHexEmpty {
    XCTAssertTrue([self.partnerParams isStringHex:@""]);
}

- (void)testStringHexDash {
    XCTAssertFalse([self.partnerParams isStringHex:@"-1"]);
}

- (void)testStringHexDecimal {
    XCTAssertFalse([self.partnerParams isStringHex:@"1.0"]);
}

- (void)testStringHexFraction {
    XCTAssertFalse([self.partnerParams isStringHex:@"2/4"]);
}

- (void)testStringHexAt {
    XCTAssertFalse([self.partnerParams isStringHex:@"test@12345"]);
}

- (void)testStringHexUpperG {
    XCTAssertFalse([self.partnerParams isStringHex:@"0123456789ABCDEFG"]);
}

- (void)testStringHexLowerG {
    XCTAssertFalse([self.partnerParams isStringHex:@"0123456789abcdefg"]);
}

- (void)testStringHexUpperCase {
    XCTAssertTrue([self.partnerParams isStringHex:@"0123456789ABCDEF"]);
}

- (void)testStringHexLowerCase {
    XCTAssertTrue([self.partnerParams isStringHex:@"0123456789abcdef"]);
}

- (void)testSha256HashSanityCheckValueNil {
    XCTAssertFalse([self.partnerParams sha256HashSanityCheckValue:nil]);
}

- (void)testSha256HashSanityCheckValueEmpty {
    XCTAssertFalse([self.partnerParams sha256HashSanityCheckValue:@""]);
}

- (void)testSha256HashSanityCheckValueTooShort {
    // 63 char string
    XCTAssertFalse([self.partnerParams sha256HashSanityCheckValue:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcde"]);
}

- (void)testSha256HashSanityCheckValueTooLong {
    // 65 char string
    XCTAssertFalse([self.partnerParams sha256HashSanityCheckValue:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdeff"]);
}

- (void)testSha256HashSanityCheckValueLowerCase {
    // 64 char string
    XCTAssertTrue([self.partnerParams sha256HashSanityCheckValue:@"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"]);
}

- (void)testSha256HashSanityCheckValueUpperCase {
    // 64 char string
    XCTAssertTrue([self.partnerParams sha256HashSanityCheckValue:@"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"]);
}

- (void)testSha256HashSanityCheckValueMixedCase {
    // 64 char string
    XCTAssertTrue([self.partnerParams sha256HashSanityCheckValue:@"0123456789ABCDEF0123456789ABCDEF1234567890abcdef1234567890abcdef"]);
}

- (void)testJsonEmpty {
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterEmpty {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@""];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterShort {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"0123456789ABCDEF0123456789ABCDEF1234567890abcdef1234567890abcde"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterPhoneNumberIsIgnored {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"1-555-555-5555"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterEmailIsIgnored {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"test@branch.io"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterBase64EncodedIsIgnored {
    // 123456789012345678901234567890123456789012345678 -> MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterHashedValue {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{\"fb\":{\"em\":\"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088\"}}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterExample {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
    [self.partnerParams addFaceBookParameterWithName:@"ph" value:@"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b"];
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    
    XCTAssertTrue([@"{\"fb\":{\"ph\":\"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b\",\"em\":\"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088\"}}" isEqualToString:jsonString]);
}

- (void)testJsonFBParameterClear {
    [self.partnerParams addFaceBookParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
    [self.partnerParams addFaceBookParameterWithName:@"ph" value:@"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b"];
    [self.partnerParams clearAllParameters];
    
    NSString *jsonString = [self jsonStringFromDictionary:[self.partnerParams parameterJson]];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

// sanity check test func on an empty dictionary
- (void)testEmptyJson {
    NSString *jsonString = [self jsonStringFromDictionary:@{}];
    XCTAssertTrue([@"{}" isEqualToString:jsonString]);
}

// sanity check test func on the sample json dictionary
- (void)testSampleJson {
    NSString *jsonString = [self jsonStringFromDictionary:@{
        @"fb": @{
            @"em": @"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088",
            @"ph": @"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b"
        }
    }];
    
    XCTAssertTrue([@"{\"fb\":{\"ph\":\"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b\",\"em\":\"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088\"}}" isEqualToString:jsonString]);
}

- (NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary {
    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    
    if (!error) {
        NSString *tmp = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        return tmp;
    } else {
        return @"";
    }
}

@end

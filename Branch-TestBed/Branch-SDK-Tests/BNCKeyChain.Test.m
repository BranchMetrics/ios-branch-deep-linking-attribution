/**
 @file          BNCKeyChain.Test.m
 @package       Branch-SDK-Tests
 @brief         BNCKeyChain tests.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCKeyChain.h"
//#import "BNCApplication.h"

@interface BNCKeyChainTest : BNCTestCase
@end

@implementation BNCKeyChainTest

- (void)testKeyChain {
    NSDate *testDate = [NSDate date];
    
    NSError *error = nil;
    NSDate *date = nil;
    NSString * const kServiceName = @"Service";
    
    // Remove and validate gone:

    error = [BNCKeyChain removeValuesForService:nil key:nil];
    // Error: 0xFFFF7B1E -34018 A required entitlement isn't present.
    // This happens when the unit test bundle isn't code signed.
    XCTAssertTrue(error == nil || error.code == -34018);

    // Check some keys:
    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(date == nil && error.code == errSecItemNotFound);

    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(date == nil && error.code == errSecItemNotFound);

    // TODO: Fix this.
    if ([UIApplication sharedApplication] == nil) {
        NSLog(@"No host application for keychain testing!");
        return;
    }
    
    // Test that local storage works:

    error = [BNCKeyChain storeDate:testDate forService:kServiceName key:@"key1" cloudAccessGroup:nil];
    XCTAssertTrue(error == nil);
    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(error == nil && [date isEqual:testDate]);

    error = [BNCKeyChain storeDate:[NSDate date] forService:kServiceName key:@"key2" cloudAccessGroup:nil];
    XCTAssertTrue(error == nil);
    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(error == nil && ![date isEqual:testDate]);

    // Remove by service:

    error = [BNCKeyChain removeValuesForService:kServiceName key:nil];
    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(date == nil && error.code == errSecItemNotFound);

    date = [BNCKeyChain retrieveDateForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(date == nil && error.code == errSecItemNotFound);
}

- (void) testSecurityAccessGroup {
    if ([UIApplication sharedApplication] == nil) {
        NSLog(@"No host application for keychain testing!");
        return;
    }
    NSString *group = [BNCKeyChain securityAccessGroup];
    XCTAssert(group.length > 0);
}

@end

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
    NSError *error = nil;
    NSString *value = nil;
    NSArray *array = nil;
    NSString*const kServiceName = @"Service";

    // Remove and validate gone:

    error = [BNCKeyChain removeValuesForService:nil key:nil];
    // Error: 0xFFFF7B1E -34018 A required entitlement isn't present.
    // This happens when the unit test bundle isn't code signed.
    XCTAssertTrue(error == nil || error.code == -34018);

    array = [BNCKeyChain retieveAllValuesWithError:&error];
    XCTAssertTrue(array == nil && error == errSecSuccess);

    // Check some keys:

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key3" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    // TODO: Fix this.
    if ([UIApplication sharedApplication] == nil) {
        NSLog(@"No host application for keychain testing!");
        return;
    }
    
    // Test that local storage works:

    error = [BNCKeyChain storeValue:@"1xyz123" forService:kServiceName key:@"key1" cloudAccessGroup:nil];
    XCTAssertTrue(error == nil);
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"1xyz123"]);

    error = [BNCKeyChain storeValue:@"2xyz123" forService:kServiceName key:@"key2" cloudAccessGroup:nil];
    XCTAssertTrue(error == nil);
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"2xyz123"]);

    error = [BNCKeyChain storeValue:@"3xyz123" forService:@"Service2" key:@"skey2" cloudAccessGroup:nil];
    XCTAssertTrue(error == nil);
    value = [BNCKeyChain retrieveValueForService:@"Service2" key:@"skey2" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"3xyz123"]);

    // Remove by service:

    error = [BNCKeyChain removeValuesForService:kServiceName key:nil];
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:@"Service2" key:@"skey2" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"3xyz123"]);

    // Check all values:

    array = [BNCKeyChain retieveAllValuesWithError:&error];
    XCTAssertTrue([array isEqualToArray:@[ @"3xyz123" ]] && error == errSecSuccess);
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

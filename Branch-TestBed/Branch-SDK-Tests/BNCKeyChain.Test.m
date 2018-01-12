//
//  BNCKeyChain.Test.m
//  Branch-SDK-Tests
//
//  Created by Edward on 1/10/18.
//  Copyright © 2018 Branch, Inc. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCKeyChain.h"

@interface BNCKeyChainTest : BNCTestCase
@end

@implementation BNCKeyChainTest

- (void)testKeyChain {

    NSString*const kServiceName = @"Service";

    // Remove and validate gone:

    NSError *error = nil;
    NSString *value = nil;
    error = [BNCKeyChain removeValuesForService:kServiceName key:nil];
    XCTAssertTrue(error == nil);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key3" error:&error];
    XCTAssertTrue(value == nil && error.code == errSecItemNotFound);

    // Test that storage works:

    error = [BNCKeyChain storeValue:@"1xyz123" forService:kServiceName key:@"key1" iCloud:NO];
    XCTAssertTrue(error == nil);
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"1xyz123"]);

    error = [BNCKeyChain storeValue:@"2xyz123" forService:kServiceName key:@"key2" iCloud:NO];
    XCTAssertTrue(error == nil);
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    XCTAssertTrue(error == nil && [value isEqualToString:@"2xyz123"]);

/*
    error = [BNCKeyChain storeValue:@"2xyz123" forService:kServiceName key:@"key2" iCloud:YES];
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    NSLog(@"%@", value);

    error = [BNCKeyChain storeValue:@"3xyz123" forService:@"Service2" key:@"skey2" iCloud:YES];
    value = [BNCKeyChain retrieveValueForService:@"Service2" key:@"skey2" error:&error];
    NSLog(@"%@", value);

    error = [BNCKeyChain removeValuesForService:kServiceName key:nil];
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key1" error:&error];
    NSLog(@"%@", value);
    value = [BNCKeyChain retrieveValueForService:kServiceName key:@"key2" error:&error];
    NSLog(@"%@", value);
    value = [BNCKeyChain retrieveValueForService:@"Service2" key:@"skey2" error:&error];
    NSLog(@"%@", value);
*/
}

@end

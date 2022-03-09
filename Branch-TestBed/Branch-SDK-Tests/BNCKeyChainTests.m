//
//  BNCKeyChainTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 1/6/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCKeyChain.h"

@interface BNCKeyChainTests : XCTestCase
@property (nonatomic, copy, readwrite) NSString *serviceName;
@end

@implementation BNCKeyChainTests

- (void)setUp {
    self.serviceName = @"Service";
}

- (void)tearDown {
    
}

- (void)testEnvironment {
    // Keychain tests must be hosted in an app, otherwise it won't have security access.
    XCTAssertFalse([UIApplication sharedApplication] == nil);

    NSString *group = [BNCKeyChain securityAccessGroup];
    XCTAssertTrue(group.length > 0);
}

- (void)testRemoveValues_Empty {
    NSError *error = [BNCKeyChain removeValuesForService:nil key:nil];
    XCTAssertTrue(error == nil);
}

- (void)testRetrieveDate_Empty {
    NSError *error;
    NSDate *date = [BNCKeyChain retrieveDateForService:self.serviceName key:@"testKey" error:&error];
    XCTAssertTrue(date == nil && error.code == errSecItemNotFound);
}

- (void)testStoreAndRetrieveDate {
    NSError *error;
    NSString *key = @"testKey";
    NSDate *date = [NSDate date];
    
    [BNCKeyChain storeDate:date forService:self.serviceName key:key cloudAccessGroup:nil];
    NSDate *tmp = [BNCKeyChain retrieveDateForService:self.serviceName key:key error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([date isEqualToDate:tmp]);
    
    // cleanup
    error = [BNCKeyChain removeValuesForService:self.serviceName key:key];
    XCTAssertNil(error);
}

- (void)testStore_Nil {
    NSError *error;
    NSString *key = @"testKey";
    NSDate *date = nil;
    
    error = [BNCKeyChain storeDate:date forService:self.serviceName key:key cloudAccessGroup:nil];
    XCTAssertTrue(error.code == errSecParam);
    
    NSDate *tmp = [BNCKeyChain retrieveDateForService:self.serviceName key:key error:&error];
    XCTAssertNil(tmp);
    XCTAssertTrue(error.code == errSecItemNotFound);
}

- (void)testStoreAndRetrieveMultipleDates {
    NSError *error;
    NSString *keyA = @"testKeyA";
    NSString *keyB = @"testKeyB";
    
    NSDate *dateA = [NSDate date];
    NSDate *dateB = [NSDate dateWithTimeIntervalSinceNow:1];
    XCTAssertFalse([dateA isEqualToDate:dateB]);
    
    [BNCKeyChain storeDate:dateA forService:self.serviceName key:keyA cloudAccessGroup:nil];
    [BNCKeyChain storeDate:dateB forService:self.serviceName key:keyB cloudAccessGroup:nil];

    NSDate *tmpA = [BNCKeyChain retrieveDateForService:self.serviceName key:keyA error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([dateA isEqualToDate:tmpA]);
    
    NSDate *tmpB = [BNCKeyChain retrieveDateForService:self.serviceName key:keyB error:&error];
    XCTAssertNil(error);
    XCTAssertTrue([dateB isEqualToDate:tmpB]);
    
    XCTAssertFalse([tmpA isEqualToDate:tmpB]);
    
    // cleanup
    error = [BNCKeyChain removeValuesForService:self.serviceName key:keyA];
    XCTAssertNil(error);
    error = [BNCKeyChain removeValuesForService:self.serviceName key:keyB];
    XCTAssertNil(error);
}

- (void)testStoreAndRetrieveDate_retrieveWrongKey {
    NSError *error;
    NSString *keyA = @"testKeyA";
    NSString *keyB = @"testKeyB";
    NSDate *date = [NSDate date];
    
    [BNCKeyChain storeDate:date forService:self.serviceName key:keyA cloudAccessGroup:nil];
    NSDate *tmp = [BNCKeyChain retrieveDateForService:self.serviceName key:keyB error:&error];
    XCTAssertNil(tmp);
    XCTAssertTrue(error.code == errSecItemNotFound);
    
    // cleanup
    error = [BNCKeyChain removeValuesForService:self.serviceName key:keyA];
    XCTAssertNil(error);
    error = [BNCKeyChain removeValuesForService:self.serviceName key:keyB];
    XCTAssertNil(error);
}


@end

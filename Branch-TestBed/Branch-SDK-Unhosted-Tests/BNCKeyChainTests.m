//
//  BNCKeyChainTests.m
//  Branch-SDK-Unhosted-Tests
//
//  Created by Ernest Cho on 1/5/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCKeyChain.h"

@interface BNCKeyChainTests : XCTestCase
@property (nonatomic, copy, readwrite) NSString *serviceName;
@property (nonatomic, copy, readwrite) NSString *key1;
@property (nonatomic, copy, readwrite) NSString *key2;
@end

@implementation BNCKeyChainTests

- (void)setUp {
    self.key1 = @"key1";
    self.key2 = @"key2";
    self.serviceName = @"UnitTest";
}

- (void)tearDown {
    
}

// Unhosted tests don't have an access group
- (void)testSecurityAccessGroup {
    NSString *group = [BNCKeyChain securityAccessGroup];
    XCTAssert(group == nil);
}

- (void)testRemoveValuesEmptyKeyChain {
    NSError *error = [BNCKeyChain removeValuesForService:self.serviceName key:self.key1];
    XCTAssertTrue(error == nil);
}

- (void)testRemoveValuesNil {
    NSError *error = [BNCKeyChain removeValuesForService:nil key:nil];
    XCTAssertTrue(error.code == -34018);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

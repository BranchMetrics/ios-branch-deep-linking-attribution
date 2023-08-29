//
//  BNCRequestFactoryTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/21/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCRequestFactory.h"

@interface BNCRequestFactoryTests : XCTestCase

@end

@implementation BNCRequestFactoryTests

- (void)setUp {
    
}

- (void)tearDown {
    
}

- (void)testExample {
    BNCRequestFactory *factory = [BNCRequestFactory new];
    XCTAssertNotNil(factory);

//    NSDictionary *v1 = [factory v1dictionary];
//    NSLog(@"V1 dictionary? %@", v1);
//    
//    NSDictionary *v2 = [factory v2dictionary];
//    NSLog(@"V2 dictionary? %@", v2);
}

@end

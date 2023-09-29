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

- (void)testInitWithBranchKeyNil {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:nil];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
    
    // key is omitted when nil
    XCTAssertNil([json objectForKey:@"branch_key"]);
}

- (void)testInitWithBranchKeyEmpty {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@""];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
    
    // empty string is allowed
    XCTAssertTrue([@"" isEqualToString:[json objectForKey:@"branch_key"]]);
}

- (void)testInitWithBranchKey {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
}

- (void)testDataForInstall {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    XCTAssertNotNil([json objectForKey:@"sdk"]);
    XCTAssertTrue([@"Apple" isEqualToString:[json objectForKey:@"brand"]]);
    XCTAssertNotNil([json objectForKey:@"ios_vendor_id"]);
    
    // not present on installs
    XCTAssertNil([json objectForKey:@"randomized_bundle_token"]);
}

- (void)testDataForOpen {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForOpen];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    XCTAssertNotNil([json objectForKey:@"sdk"]);
    XCTAssertTrue([@"Apple" isEqualToString:[json objectForKey:@"brand"]]);
    XCTAssertNotNil([json objectForKey:@"ios_vendor_id"]);
    
    // Present only on opens. Assumes test runs after the host app completes an install.
    // This is not a reliable assumption on test runners
    //XCTAssertNotNil([json objectForKey:@"randomized_bundle_token"]);
}

- (void)testDataForEvent {
    NSDictionary *event = @{@"name": @"ADD_TO_CART"};
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
}

- (void)testDataForEventWithContentItem {
    NSDictionary *event = @{
        @"name": @"ADD_TO_CART",
        @"content_items": @[
            @{
                @"$og_title": @"TestTitle",
                @"$quantity": @(2),
                @"$product_name": @"TestProduct",
                @"$price": @(10)
            }
        ]
    };
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *contentItems = [json objectForKey:@"content_items"];
    XCTAssertNotNil(contentItems);
    XCTAssertTrue(contentItems.count == 1);

    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
}

- (void)testDataForEventWithTwoContentItem {
    NSDictionary *event = @{
        @"name": @"ADD_TO_CART",
        @"content_items": @[
            @{
                @"$og_title": @"TestTitle1",
                @"$quantity": @(2),
                @"$product_name": @"TestProduct1",
                @"$price": @(10)
            },
            @{
                @"$og_title": @"TestTitle2",
                @"$quantity": @(3),
                @"$product_name": @"TestProduct2",
                @"$price": @(20)
            }
        ]
    };
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *contentItems = [json objectForKey:@"content_items"];
    XCTAssertNotNil(contentItems);
    XCTAssertTrue(contentItems.count == 2);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
}

- (void)testDataForEventEmpty {
    NSDictionary *event = @{};
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertNil([json objectForKey:@"name"]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
}

- (void)testDataForEventNil {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForEventWithEventDictionary:nil];
    XCTAssertNotNil(json);
    
    XCTAssertNil([json objectForKey:@"name"]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
}


- (void)testDataForShortURL {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
}

- (void)testDataForLATD {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd"];
    NSDictionary *json = [factory dataForInstall];
    XCTAssertNotNil(json);
}

@end

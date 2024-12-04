//
//  BNCRequestFactoryTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/21/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCRequestFactory.h"
#import "BranchConstants.h"
#import "BNCEncodingUtils.h"

@interface BNCRequestFactoryTests : XCTestCase
@property (nonatomic, copy, readwrite) NSString *requestUUID;
@property (nonatomic, copy, readwrite) NSNumber *requestCreationTimeStamp;
@end

@implementation BNCRequestFactoryTests

- (void)setUp {
    _requestUUID = [[NSUUID UUID ] UUIDString];
    _requestCreationTimeStamp = BNCWireFormatFromDate([NSDate date]);
}

- (void)tearDown {
    
}

- (void)testInitWithBranchKeyNil {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:nil UUID:_requestUUID TimeStamp:_requestCreationTimeStamp];
    NSDictionary *json = [factory dataForInstallWithLinkParams:nil];
    XCTAssertNotNil(json);
    
    // key is omitted when nil
    XCTAssertNil([json objectForKey:@"branch_key"]);
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testInitWithBranchKeyEmpty {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForInstallWithLinkParams:nil];
    XCTAssertNotNil(json);
    
    // empty string is allowed
    XCTAssertTrue([@"" isEqualToString:[json objectForKey:@"branch_key"]]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testInitWithBranchKey {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForInstallWithLinkParams:nil];
    XCTAssertNotNil(json);
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForInstall {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForInstallWithLinkParams:nil];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    XCTAssertNotNil([json objectForKey:@"sdk"]);
    XCTAssertTrue([@"Apple" isEqualToString:[json objectForKey:@"brand"]]);
    XCTAssertNotNil([json objectForKey:@"ios_vendor_id"]);
    
    // not present on installs
    XCTAssertNil([json objectForKey:@"randomized_bundle_token"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForOpen {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForInstallWithLinkParams:nil];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    XCTAssertNotNil([json objectForKey:@"sdk"]);
    XCTAssertTrue([@"Apple" isEqualToString:[json objectForKey:@"brand"]]);
    XCTAssertNotNil([json objectForKey:@"ios_vendor_id"]);
    
    // Present only on opens. Assumes test runs after the host app completes an install.
    // This is not a reliable assumption on test runners
    //XCTAssertNotNil([json objectForKey:@"randomized_bundle_token"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForEvent {
    NSDictionary *event = @{@"name": @"ADD_TO_CART"};
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
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
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *contentItems = [json objectForKey:@"content_items"];
    XCTAssertNotNil(contentItems);
    XCTAssertTrue(contentItems.count == 1);

    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
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
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"ADD_TO_CART" isEqualToString:[json objectForKey:@"name"]]);
    
    NSDictionary *contentItems = [json objectForKey:@"content_items"];
    XCTAssertNotNil(contentItems);
    XCTAssertTrue(contentItems.count == 2);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForEventEmpty {
    NSDictionary *event = @{};
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[event mutableCopy]];
    XCTAssertNotNil(json);
    
    XCTAssertNil([json objectForKey:@"name"]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForEventNil {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:nil];
    XCTAssertNotNil(json);
    
    XCTAssertNil([json objectForKey:@"name"]);
    
    NSDictionary *userData = [json objectForKey:@"user_data"];
    XCTAssertNotNil(userData);
    XCTAssertNotNil([userData objectForKey:@"idfv"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}


- (void)testDataForShortURL {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForShortURLWithLinkDataDictionary:@{}.mutableCopy isSpotlightRequest:NO];
    XCTAssertNotNil(json);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForLATD {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForLATDWithDataDictionary:@{}.mutableCopy];
    XCTAssertNotNil(json);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

@end

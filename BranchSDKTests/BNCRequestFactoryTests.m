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
#import "BNCAppGroupsData.h"
#import "BNCPreferenceHelper.h"

static NSTimeInterval const kAppClipInstallTime = 1700000000;

// Reports App Clip data as saved, without an App Group.
@interface BNCAppGroupsDataWithSavedAppClip : BNCAppGroupsData
@end

@implementation BNCAppGroupsDataWithSavedAppClip

- (BOOL)loadAppClipData {
    self.bundleID = @"io.branch.example.Clip";
    self.installDate = [NSDate dateWithTimeIntervalSince1970:kAppClipInstallTime];
    self.url = @"https://example.app.link/clip";
    self.branchToken = @"clip_device_token";
    self.bundleToken = @"clip_bundle_token";
    return YES;
}

@end

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
    NSDictionary *json = [factory dataForRequestInstallWithURLString:@"https://branch.io"];
    XCTAssertNotNil(json);
    
    // key is omitted when nil
    XCTAssertNil([json objectForKey:@"branch_key"]);
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testInitWithBranchKeyEmpty {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForRequestInstallWithURLString:@"https://branch.io"];
    XCTAssertNotNil(json);
    
    // empty string is allowed
    XCTAssertTrue([@"" isEqualToString:[json objectForKey:@"branch_key"]]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testInitWithBranchKey {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForRequestInstallWithURLString:@"https://branch.io"];
    XCTAssertNotNil(json);
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForRequestInstall {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForRequestInstallWithURLString:@"https://branch.io"];
    XCTAssertNotNil(json);
    
    XCTAssertTrue([@"key_abcd" isEqualToString:[json objectForKey:@"branch_key"]]);
    XCTAssertNotNil([json objectForKey:@"sdk"]);
    XCTAssertTrue([@"Apple" isEqualToString:[json objectForKey:@"brand"]]);
    XCTAssertNotNil([json objectForKey:@"ios_vendor_id"]);
    
    XCTAssertTrue(self.requestCreationTimeStamp  == [json objectForKey:BRANCH_REQUEST_KEY_REQUEST_CREATION_TIME_STAMP]);
    XCTAssertTrue([self.requestUUID isEqualToString:[json objectForKey:BRANCH_REQUEST_KEY_REQUEST_UUID]]);
}

- (void)testDataForRequestOpen {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForRequestOpenWithURLString:@"https://branch.io"];
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

- (void)testPayloadsOmitRemovedFacebookAndAdNetworkKeys {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary<NSString *, NSDictionary *> *payloads = @{
        @"requestInstall": [factory dataForRequestInstallWithURLString:@"https://branch.io"],
        @"requestOpen": [factory dataForRequestOpenWithURLString:@"https://branch.io"],
        @"deeplink": [factory dataForDeepLinkWithURLString:@"https://branch.io"],
        @"event": [factory dataForEventWithEventDictionary:[@{@"name": @"ADD_TO_CART"} mutableCopy]],
        @"shortURL": [factory dataForShortURLWithLinkDataDictionary:@{}.mutableCopy isSpotlightRequest:NO],
        @"latd": [factory dataForLATDWithDataDictionary:@{}.mutableCopy],
    };

    [payloads enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSDictionary *json, BOOL *stop) {
        NSDictionary *userData = json[@"user_data"];
        XCTAssertNil(json[@"limit_facebook_tracking"], @"%@", name);
        XCTAssertNil(json[@"disable_ad_network_callouts"], @"%@", name);
        XCTAssertNil(userData[@"limit_facebook_tracking"], @"%@", name);
        XCTAssertNil(userData[@"disable_ad_network_callouts"], @"%@", name);
    }];
}

#pragma mark - App Clip handoff

- (BNCRequestFactory *)factoryWithSavedAppClipData {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    [factory setValue:[BNCAppGroupsDataWithSavedAppClip new] forKey:@"appGroupsData"];
    return factory;
}

- (void)testDataForRequestInstallAddsSavedAppClipData {
    NSDictionary *json = [[self factoryWithSavedAppClipData] dataForRequestInstallWithURLString:nil];

    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID], @"io.branch.example.Clip");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME], BNCWireFormatFromDate([NSDate dateWithTimeIntervalSince1970:kAppClipInstallTime]));
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL], @"https://example.app.link/clip");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN], @"clip_device_token");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN], @"clip_bundle_token");
}

- (void)testDataForRequestOpenOmitsSavedAppClipData {
    NSDictionary *json = [[self factoryWithSavedAppClipData] dataForRequestOpenWithURLString:nil];

    XCTAssertNil(json[BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID]);
    XCTAssertNil(json[BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN]);
    XCTAssertNil(json[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL]);
}

// Builds the deep link payload with the given bundle token, restoring the stored one afterwards.
- (NSDictionary *)deepLinkPayloadWithSavedAppClipDataForURLString:(NSString *)urlString bundleToken:(NSString *)bundleToken {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.randomizedBundleToken = bundleToken;

    NSDictionary *json = [[self factoryWithSavedAppClipData] dataForDeepLinkWithURLString:urlString];

    preferenceHelper.randomizedBundleToken = savedBundleToken;
    return json;
}

// The first-launch lookup without a link carries the App Clip's data, so it can resolve the App Clip's link.
- (void)testDataForDeepLinkOnFirstLaunchAddsSavedAppClipData {
    NSDictionary *json = [self deepLinkPayloadWithSavedAppClipDataForURLString:nil bundleToken:nil];

    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID], @"io.branch.example.Clip");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_LATEST_APP_CLIP_INSTALL_TIME], BNCWireFormatFromDate([NSDate dateWithTimeIntervalSince1970:kAppClipInstallTime]));
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL], @"https://example.app.link/clip");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_DEVICE_TOKEN], @"clip_device_token");
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_APP_CLIP_RANDOMIZED_BUNDLE_TOKEN], @"clip_bundle_token");
}

// A first launch opened by a link resolves that link, so the App Clip's link does not replace it.
- (void)testDataForDeepLinkWithLaunchLinkOmitsSavedAppClipData {
    NSDictionary *json = [self deepLinkPayloadWithSavedAppClipDataForURLString:@"https://example.app.link/launch" bundleToken:nil];

    XCTAssertNil(json[BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID]);
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL], @"https://example.app.link/launch");
}

- (void)testDataForDeepLinkAfterFirstLaunchOmitsSavedAppClipData {
    NSDictionary *json = [self deepLinkPayloadWithSavedAppClipDataForURLString:nil bundleToken:@"existing_bundle_token"];

    XCTAssertNil(json[BRANCH_REQUEST_KEY_APP_CLIP_BUNDLE_ID]);
    XCTAssertNil(json[BRANCH_REQUEST_KEY_UNIVERSAL_LINK_URL]);
}

@end

//
//  BNCEvent.Test.m
//  Branch-TestBed
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCEvent.h"
#import "BNCDeviceInfo.h"

@interface BNCEventTest : BNCTestCase
@end

@implementation BNCEventTest

- (void) testEvent {

    // Set up the event properties --

    BNCEventProperties *eventProperties = [BNCEventProperties new];
    eventProperties.transactionID   = @"12344555";
    eventProperties.currency        = BNCCurrencyUSD;
    eventProperties.revenue         = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    eventProperties.shipping        = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    eventProperties.tax             = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    eventProperties.coupon          = @"test_coupon";
    eventProperties.affiliation     = @"test_affiliation";
    eventProperties.eventDescription= @"Event _description";
    eventProperties.productCondition= BNCProductConditionFair;
    eventProperties.userInfo        = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };

    NSDictionary *testDictionary = [eventProperties dictionary];
    NSMutableDictionary *dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"V2EventProperties"];
    XCTAssertEqualObjects(testDictionary, dictionary);

    // Set up the Branch Univseral Object --

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    buo.imageUrl            = @"https://test_img_url";
    buo.keywords            = @[ @"My_Keyword1", @"My_Keyword2"];
    buo.creationDate        = [NSDate dateWithTimeIntervalSince1970:1501869445321.0/1000.0];
    buo.expirationDate      = [NSDate dateWithTimeIntervalSince1970:212123232544.0/1000.0];
    buo.indexLocally        = YES;
    buo.indexPublicly       = NO;

    buo.schemaData.contentSchema    = BNCContentSchemaCommerceProduct;
    buo.schemaData.quantity         = 2;
    buo.schemaData.price            = [NSDecimalNumber decimalNumberWithString:@"23.2"];
    buo.schemaData.currency         = BNCCurrencyUSD;
    buo.schemaData.sku              = @"1994320302";
    buo.schemaData.productName      = @"my_product_name1";
    buo.schemaData.productBrand     = @"my_prod_Brand1";
    buo.schemaData.productCategory  = BNCProductCategoryBabyToddler;
    buo.schemaData.productVariant   = @"3T";
    buo.schemaData.ratingAverage    = 5;
    buo.schemaData.ratingCount      = 5;
    buo.schemaData.ratingMaximum    = 7;
    buo.schemaData.addressStreet    = @"Street_name1";
    buo.schemaData.addressCity      = @"city1";
    buo.schemaData.addressRegion    = @"Region1";
    buo.schemaData.addressCountry   = @"Country1";
    buo.schemaData.addressPostalCode= @"postal_code";
    buo.schemaData.latitude         = 12.07;
    buo.schemaData.longitude        = -97.5;
    buo.schemaData.imageCaptions    = @[@"my_img_caption1", @"my_img_caption_2"];
    buo.schemaData.userInfo         = (NSMutableDictionary*) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1"
    };

    testDictionary = [buo dictionary];
    dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    dictionary[@"$publicly_indexable"] = nil; // Remove this value since we don't add false values.
    XCTAssertEqualObjects(testDictionary, dictionary);

    // Mock the result. Fix up the expectedParameters --

    BNCDeviceInfo *device = [BNCDeviceInfo getInstance];
    NSMutableDictionary *expectedRequest = [self mutableDictionaryFromBundleJSONWithKey:@"V2EventJSON"];
    expectedRequest[@"hardware_id"]     = device.hardwareId;
    expectedRequest[@"screen_height"]   = device.screenHeight;
    expectedRequest[@"screen_width"]    = device.screenWidth;
    expectedRequest[@"os"]              = device.osName;
    expectedRequest[@"os_version"]      = device.osVersion;
    expectedRequest[@"model"]           = device.modelName;
    expectedRequest[@"sdk"]             = [NSString stringWithFormat:@"ios%@", BNC_SDK_VERSION];
    expectedRequest[@"ios_vendor_id"]   = device.vendorId;
    expectedRequest[@"user_agent"]      = [BNCDeviceInfo userAgentString];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"v2 Event"];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    OCMStub(
        [serverInterfaceMock
            postRequest:[OCMArg any]
            url:[OCMArg any]
            key:[OCMArg any]
            callback:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });


//    [[serverInterfaceMock expect]
//        postRequest:expectedRequest
//        url:[self stringMatchingPattern:@"v2/event/standard"]
//        key:[OCMArg any]
//        callback:[OCMArg any]];

    Branch *branch = [Branch getInstance:@"key_live_foo"];
    [[BNCServerRequestQueue getInstance] clearQueue];
    [branch logStandardEvent:BNCStandardEventPurchase
        withProperties:eventProperties
        contentItems:@[buo]];

//    sleep(1); // Sleep to let the event fire.
//    [serverInterfaceMock verify];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end

//
//  BranchEvent.Test.m
//  Branch-TestBed
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BranchEvent.h"
#import "BNCDeviceInfo.h"

@interface Branch (BranchEventTest)
- (void) processNextQueueItem;
@end

@interface BranchEventTest : BNCTestCase
@end

@implementation BranchEventTest

- (void) testEvent {

    // Set up the Branch Universal Object --

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

    buo.schemaData.contentSchema    = BranchContentSchemaCommerceProduct;
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

    // Set up the event properties --

    BranchEvent *event    = [BranchEvent standardEventWithType:BranchStandardEventPurchase];
    event.transactionID   = @"12344555";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    event.shipping        = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    event.tax             = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    event.coupon          = @"test_coupon";
    event.affiliation     = @"test_affiliation";
    event.eventDescription= @"Event _description";
    event.productCondition= BNCProductConditionFair;
    event.userInfo        = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };

    NSDictionary *testDictionary = [event dictionary];
    NSMutableDictionary *dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"V2EventProperties"];
    XCTAssertEqualObjects(testDictionary, dictionary);

    testDictionary = [buo dictionary];
    dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    dictionary[@"$publicly_indexable"] = nil; // Remove this value since we don't add false values.
    XCTAssertEqualObjects(testDictionary, dictionary);

    // Mock the result. Fix up the expectedParameters for simulator hardware --

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

    Branch *branch = [Branch getInstance:@"key_live_foo"];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"v2-event"];
    id serverInterfaceMock = OCMPartialMock(branch.serverInterface);

    OCMStub(
        [serverInterfaceMock genericHTTPRequest:[OCMArg any]
            retryNumber:0
            callback:[OCMArg any]
            retryHandler:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {

        __unsafe_unretained NSURLRequest *request = nil;
        [invocation getArgument:&request atIndex:2];

        NSError *error = nil;
        NSString *url = request.URL.absoluteString;
        NSData *bodyData = request.HTTPBody;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&error];
        XCTAssertNil(error);

        NSLog(@"1");
        NSLog(@"URL: %@.", url);
        NSLog(@"Body: %@.", parameters);

        if ([url containsString:@"v2/event/standard"]) {
            XCTAssertEqualObjects(expectedRequest, parameters);
            [expectation fulfill];
        }
    });

    [branch clearNetworkQueue];
    event.contentItems = @[ buo ];
    [event logEvent];
    [self waitForExpectations:@[expectation] timeout:2.0];
    [serverInterfaceMock stopMocking];
}

- (void) testUserCompletedAction {
    // Mock the result. Fix up the expectedParameters for simulator hardware --

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

    expectedRequest[@"event_data"]      = nil;
    expectedRequest[@"custom_data"]     = nil;

    Branch *branch = [Branch getInstance:@"key_live_foo"];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"v2-event-user-action"];
    id serverInterfaceMock = OCMPartialMock(branch.serverInterface);

    OCMStub(
        [serverInterfaceMock genericHTTPRequest:[OCMArg any]
            retryNumber:0
            callback:[OCMArg any]
            retryHandler:[OCMArg any]]
    ).andDo(^(NSInvocation *invocation) {

        __unsafe_unretained NSURLRequest *request = nil;
        [invocation getArgument:&request atIndex:2];

        NSError *error = nil;
        NSString *url = request.URL.absoluteString;
        NSData *bodyData = request.HTTPBody;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&error];
        XCTAssertNil(error);

        NSLog(@"2");
        NSLog(@"URL: %@.", url);
        NSLog(@"Body: %@.", parameters);

        if ([url containsString:@"v2/event/standard"]) {
            XCTAssertEqualObjects(expectedRequest, parameters);
            [expectation fulfill];
        }
    });

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

    buo.schemaData.contentSchema    = BranchContentSchemaCommerceProduct;
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

    // Set up and invoke --
    [branch clearNetworkQueue];
    [buo userCompletedAction:BranchStandardEventPurchase];
//    [branch processNextQueueItem];
//    [branch processNextQueueItem];
    [self waitForExpectations:@[expectation] timeout:2.0];
    [serverInterfaceMock stopMocking];
}

@end

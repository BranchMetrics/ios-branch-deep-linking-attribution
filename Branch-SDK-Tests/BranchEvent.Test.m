//
//  BranchEvent.Test.m
//  Branch-SDK-Tests
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BranchEvent.h"
#import "BNCDeviceInfo.h"

@interface Branch (BranchEventTest)
- (void) processNextQueueItem;
@end

@interface BranchEvent()

- (NSString *)jsonStringForAdType:(BranchEventAdType)adType;

// private BranchEvent methods used to check data before sending to network service.
- (NSDictionary *)buildEventDictionary;
- (BranchEventRequest *)buildRequestWithEventDictionary:(NSDictionary *)eventDictionary;

@end

@interface BranchEventTest : BNCTestCase
@end

@implementation BranchEventTest

- (void) setUp {
    [BNCPreferenceHelper preferenceHelper].identityID = @"575759106028389737";
    [[BNCPreferenceHelper preferenceHelper] clearInstrumentationDictionary];
}

- (void) testDescription {
    BranchEvent *event    = [BranchEvent standardEvent:BranchStandardEventPurchase];
    event.transactionID   = @"1234";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"10.50"];
    event.eventDescription= @"Event description.";
    event.customData      = (NSMutableDictionary*) @{
        @"Key1": @"Value1"
    };

    NSString *d = event.description;
    BNCTAssertEqualMaskedString(d,
        @"<BranchEvent 0x**************** PURCHASE txID: 1234 Amt: USD 10.5 desc: Event description. "
         "items: 0 customData: {\n    Key1 = Value1;\n}>");
}

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
    buo.locallyIndex        = YES;
    buo.publiclyIndex       = NO;

    buo.contentMetadata.contentSchema    = BranchContentSchemaCommerceProduct;
    buo.contentMetadata.quantity         = 2;
    buo.contentMetadata.price            = [NSDecimalNumber decimalNumberWithString:@"23.2"];
    buo.contentMetadata.currency         = BNCCurrencyUSD;
    buo.contentMetadata.sku              = @"1994320302";
    buo.contentMetadata.productName      = @"my_product_name1";
    buo.contentMetadata.productBrand     = @"my_prod_Brand1";
    buo.contentMetadata.productCategory  = BNCProductCategoryBabyToddler;
    buo.contentMetadata.productVariant   = @"3T";
    buo.contentMetadata.condition        = BranchConditionFair;

    buo.contentMetadata.ratingAverage    = 5;
    buo.contentMetadata.ratingCount      = 5;
    buo.contentMetadata.ratingMax        = 7;
    buo.contentMetadata.rating           = 6;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (NSMutableDictionary*) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1",
        @"Custom_Content_metadata_key2": @"Custom_Content_metadata_val2"
    };

    // Set up the event properties --

    BranchEvent *event    = [BranchEvent standardEvent:BranchStandardEventPurchase];
    event.alias           = @"event alias";
    event.transactionID   = @"12344555";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    event.shipping        = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    event.tax             = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    event.coupon          = @"test_coupon";
    event.affiliation     = @"test_affiliation";
    event.eventDescription= @"Event _description";
    event.searchQuery     = @"Query";
    event.customData      = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };

    NSDictionary *testDictionary = [event dictionary];
    NSMutableDictionary *dictionary =
        [self mutableDictionaryFromBundleJSONWithKey:@"V2EventProperties"];
    XCTAssertEqualObjects(testDictionary, dictionary);

    testDictionary = [buo dictionary];
    dictionary = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    dictionary[@"$publicly_indexable"] = nil; // Remove this value since we don't add false values.
    XCTAssertEqualObjects(testDictionary, dictionary);

    // Mock the result. Fix up the expectedParameters for simulator hardware --

    NSMutableDictionary *expectedRequest =
        [self mutableDictionaryFromBundleJSONWithKey:@"V2EventJSON"];
    expectedRequest[@"branch_key"] = Branch.branchKey;
    expectedRequest[@"user_data"] = [[BNCDeviceInfo getInstance] v2dictionary];

    Branch *branch = [Branch getInstance:@"key_live_foo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"v2-event"];
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
        NSMutableDictionary *parameters =
            [NSJSONSerialization JSONObjectWithData:bodyData
                options:NSJSONReadingMutableContainers error:&error];
        XCTAssertNil(error);

        NSLog(@"testEvent 1");
        NSLog(@"URL: %@.", url);
        NSLog(@"Body: %@.", parameters);

        if ([url containsString:@"branch.io/v2/event/standard"]) {
            XCTAssertEqualObjects(expectedRequest, parameters);
            [expectation fulfill];
        }
    });

    [branch clearNetworkQueue];
    event.contentItems = (NSMutableArray*) @[ buo ];
    [event logEvent];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
}

- (void) testUserCompletedAction {
    // Mock the result. Fix up the expectedParameters for simulator hardware --

    NSMutableDictionary *expectedRequest =
        [self mutableDictionaryFromBundleJSONWithKey:@"V2EventJSON"];
    expectedRequest[@"branch_key"] = Branch.branchKey;
    expectedRequest[@"user_data"] = [[BNCDeviceInfo getInstance] v2dictionary];
    expectedRequest[@"event_data"] = nil;
    expectedRequest[@"custom_data"] = nil;
    expectedRequest[@"customer_event_alias"] = nil;

    Branch *branch = [Branch getInstance:@"key_live_foo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"v2-event-user-action"];
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
        NSDictionary *parameters =
            [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&error];
        XCTAssertNil(error);

        NSLog(@"2");
        NSLog(@"URL: %@.", url);
        NSLog(@"Body: %@.", parameters);

        if ([url containsString:@"branch.io/v2/event/standard"]) {
            XCTAssertEqualObjects(expectedRequest, parameters);
            [expectation fulfill];
        } else {
            XCTFail(@"URL is unexpected. %@", url);
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
    buo.locallyIndex        = YES;
    buo.publiclyIndex       = NO;

    buo.contentMetadata.contentSchema    = BranchContentSchemaCommerceProduct;
    buo.contentMetadata.quantity         = 2;
    buo.contentMetadata.price            = [NSDecimalNumber decimalNumberWithString:@"23.2"];
    buo.contentMetadata.currency         = BNCCurrencyUSD;
    buo.contentMetadata.sku              = @"1994320302";
    buo.contentMetadata.productName      = @"my_product_name1";
    buo.contentMetadata.productBrand     = @"my_prod_Brand1";
    buo.contentMetadata.productCategory  = BNCProductCategoryBabyToddler;
    buo.contentMetadata.productVariant   = @"3T";
    buo.contentMetadata.condition        = @"FAIR";
    buo.contentMetadata.ratingAverage    = 5;
    buo.contentMetadata.ratingCount      = 5;
    buo.contentMetadata.ratingMax        = 7;
    buo.contentMetadata.rating           = 6;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (NSMutableDictionary*) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1",
        @"Custom_Content_metadata_key2": @"Custom_Content_metadata_val2"
    };

    // Set up and invoke --
    [branch clearNetworkQueue];
    [buo userCompletedAction:@"PURCHASE"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    [serverInterfaceMock stopMocking];
}

- (void) testExampleSyntax {
    BranchUniversalObject *contentItem = [BranchUniversalObject new];
    contentItem.canonicalIdentifier = @"item/123";
    contentItem.canonicalUrl = @"https://branch.io/item/123";
    contentItem.contentMetadata.ratingAverage = 5.0;

    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventCompleteRegistration];
    event.eventDescription = @"Product Search";
    event.searchQuery = @"product name";
    event.customData[@"rating"] = @"5";
    [event logEvent];
}

- (void)testStandardInviteEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventInvite];

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"INVITE"]);

    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomInviteEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"INVITE"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"INVITE"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardLoginEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventLogin];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"LOGIN"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomLoginEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"LOGIN"];

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"LOGIN"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardReserveEvent {
    
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventReserve];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"RESERVE"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomReserveEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"RESERVE"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"RESERVE"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardSubscribeEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventSubscribe];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"SUBSCRIBE"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"currency"] isEqualToString:BNCCurrencyUSD]);
    XCTAssert([eventData[@"revenue"] isEqual:[NSDecimalNumber decimalNumberWithString:@"1.0"]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomSubscribeEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"SUBSCRIBE"];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"SUBSCRIBE"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"currency"] isEqualToString:BNCCurrencyUSD]);
    XCTAssert([eventData[@"revenue"] isEqual:[NSDecimalNumber decimalNumberWithString:@"1.0"]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardStartTrialEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventStartTrial];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"START_TRIAL"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"currency"] isEqualToString:BNCCurrencyUSD]);
    XCTAssert([eventData[@"revenue"] isEqual:[NSDecimalNumber decimalNumberWithString:@"1.0"]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomStartTrialEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"START_TRIAL"];
    event.currency = BNCCurrencyUSD;
    event.revenue = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"START_TRIAL"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"currency"] isEqualToString:BNCCurrencyUSD]);
    XCTAssert([eventData[@"revenue"] isEqual:[NSDecimalNumber decimalNumberWithString:@"1.0"]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardClickAdEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventClickAd];
    event.adType = BranchEventAdTypeBanner;

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"CLICK_AD"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"ad_type"] isEqual:[event jsonStringForAdType:event.adType]]);

    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomClickAdEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"CLICK_AD"];
    event.adType = BranchEventAdTypeBanner;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"CLICK_AD"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"ad_type"] isEqual:[event jsonStringForAdType:event.adType]]);

    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardViewAdEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    event.adType = BranchEventAdTypeBanner;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"VIEW_AD"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"ad_type"] isEqual:[event jsonStringForAdType:event.adType]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomViewAdEvent {
    
    BranchEvent *event = [BranchEvent customEventWithName:@"VIEW_AD"];
    event.adType = BranchEventAdTypeBanner;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"item/12345";
    buo.canonicalUrl        = @"https://branch.io/deepviews";
    buo.title               = @"My Content Title";
    buo.contentDescription  = @"my_product_description1";
    
    NSMutableArray<BranchUniversalObject *> *contentItems = [NSMutableArray new];
    [contentItems addObject:buo];
    event.contentItems = contentItems;
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"VIEW_AD"]);
    XCTAssertNotNil(eventDictionary[@"content_items"]);
    
    NSDictionary *eventData = eventDictionary[@"event_data"];
    XCTAssert([eventData[@"ad_type"] isEqual:[event jsonStringForAdType:event.adType]]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testJsonStringForAdTypeNone {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    XCTAssertNil([event jsonStringForAdType:BranchEventAdTypeNone]);
}
    
- (void)testJsonStringForAdTypeBanner {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    XCTAssertTrue([[event jsonStringForAdType:BranchEventAdTypeBanner] isEqualToString:@"BANNER"]);
}

- (void)testJsonStringForAdTypeInterstitial {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    XCTAssertTrue([[event jsonStringForAdType:BranchEventAdTypeInterstitial] isEqualToString:@"INTERSTITIAL"]);
}

- (void)testJsonStringForAdTypeRewardedVideo {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    XCTAssertTrue([[event jsonStringForAdType:BranchEventAdTypeRewardedVideo] isEqualToString:@"REWARDED_VIDEO"]);
}

- (void)testJsonStringForAdTypeNative {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventViewAd];
    XCTAssertTrue([[event jsonStringForAdType:BranchEventAdTypeNative] isEqualToString:@"NATIVE"]);
}

@end

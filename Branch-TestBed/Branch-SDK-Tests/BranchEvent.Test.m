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
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = @"575759106028389737";
    [[BNCPreferenceHelper sharedInstance] clearInstrumentationDictionary];
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

- (void) testExampleSyntax {
    BranchUniversalObject *contentItem = [BranchUniversalObject new];
    contentItem.canonicalIdentifier = @"item/123";
    contentItem.canonicalUrl = @"https://branch.io/item/123";
    contentItem.contentMetadata.ratingAverage = 5.0;

    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventCompleteRegistration];
    event.eventDescription = @"Product Search";
    event.searchQuery = @"product name";    
    event.customData = @{ @"rating": @"5" };
    
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

- (void)testStandardOptInEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventOptIn];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"OPT_IN"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomOptInEvent {
    BranchEvent *event = [BranchEvent customEventWithName:@"OPT_IN"];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"OPT_IN"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardOptOutEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventOptOut];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"OPT_OUT"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomOptOutEvent {
    BranchEvent *event = [BranchEvent customEventWithName:@"OPT_OUT"];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"OPT_OUT"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}


- (void)testStandardInitiateStreamEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventInitiateStream];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"INITIATE_STREAM"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomInitiateStreamEvent {
    BranchEvent *event = [BranchEvent customEventWithName:@"INITIATE_STREAM"];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"INITIATE_STREAM"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testStandardCompleteStreamEvent {
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventCompleteStream];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"COMPLETE_STREAM"]);
    
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
    XCTAssert([request.serverURL.absoluteString containsString:@"branch.io/v2/event/standard"]);
}

- (void)testCustomCompleteStreamEvent {
    BranchEvent *event = [BranchEvent customEventWithName:@"COMPLETE_STREAM"];
    
    NSDictionary *eventDictionary = [event buildEventDictionary];
    XCTAssertNotNil(eventDictionary);
    XCTAssert([eventDictionary[@"name"] isEqualToString:@"COMPLETE_STREAM"]);
    
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

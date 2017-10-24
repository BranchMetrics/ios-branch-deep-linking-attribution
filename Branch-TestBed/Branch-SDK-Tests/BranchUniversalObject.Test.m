//
//  BranchUniversalObject.Test.m
//  Branch-TestBed
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCTestCase.h"
#import "BranchUniversalObject.h"
#import "NSString+Branch.h"
#import "Branch.h"

@interface BranchUniversalObjectTest : BNCTestCase
@end

@implementation BranchUniversalObjectTest

- (void) testDeserialize {

    NSString *jsonString = [self stringFromBundleWithKey:@"BranchUniversalObjectJSON"];
    XCTAssertTrue(jsonString, @"Can't load BranchUniversalObjectJSON resource from plist!");

    NSError *error = nil;
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
            options:0 error:&error];
    XCTAssertNil(error);
    XCTAssert(dictionary);

    BranchUniversalObject *buo = [BranchUniversalObject objectWithDictionary:dictionary];
    XCTAssert(buo);

    XCTAssertEqualObjects(buo.contentMetadata.contentSchema,     BranchContentSchemaCommerceProduct);
    XCTAssertEqual(buo.contentMetadata.quantity,                 2);
    XCTAssertEqualObjects(buo.contentMetadata.price,             [NSDecimalNumber decimalNumberWithString:@"23.20"]);
    XCTAssertEqualObjects(buo.contentMetadata.currency,          BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.contentMetadata.sku,               @"1994320302");
    XCTAssertEqualObjects(buo.contentMetadata.productName,       @"my_product_name1");
    XCTAssertEqualObjects(buo.contentMetadata.productBrand,      @"my_prod_Brand1");
    XCTAssertEqualObjects(buo.contentMetadata.productCategory,   BNCProductCategoryBabyToddler);
    XCTAssertEqualObjects(buo.contentMetadata.productVariant,    @"3T");
    XCTAssertEqualObjects(buo.contentMetadata.condition,         @"FAIR");
    XCTAssertEqual(buo.contentMetadata.ratingAverage,            5);
    XCTAssertEqual(buo.contentMetadata.ratingCount,              5);
    XCTAssertEqual(buo.contentMetadata.ratingMax,                7);
    XCTAssertEqualObjects(buo.contentMetadata.addressStreet,     @"Street_name1");
    XCTAssertEqualObjects(buo.contentMetadata.addressCity,       @"city1");
    XCTAssertEqualObjects(buo.contentMetadata.addressRegion,     @"Region1");
    XCTAssertEqualObjects(buo.contentMetadata.addressCountry,    @"Country1");
    XCTAssertEqualObjects(buo.contentMetadata.addressPostalCode, @"postal_code");
    XCTAssertEqual(buo.contentMetadata.latitude,                 12.07);
    XCTAssertEqual(buo.contentMetadata.longitude,                -97.5);
    NSArray *array = @[@"my_img_caption1", @"my_img_caption_2"];
    XCTAssertEqualObjects(buo.contentMetadata.imageCaptions,     array);
    XCTAssertEqualObjects(buo.contentMetadata.customMetadata,
                          @{@"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1"});
    XCTAssertEqualObjects(buo.title,                        @"My Content Title");
    XCTAssertEqualObjects(buo.canonicalIdentifier,          @"item/12345");
    XCTAssertEqualObjects(buo.canonicalUrl,                 @"https://branch.io/deepviews");
    array = @[@"My_Keyword1", @"My_Keyword2"];
    XCTAssertEqualObjects(buo.keywords,                     array);
    XCTAssertEqualObjects(buo.contentDescription,           @"my_product_description1");
    XCTAssertEqualObjects(buo.imageUrl,                     @"https://test_img_url");
    XCTAssertEqualObjects(buo.expirationDate,               [NSDate dateWithTimeIntervalSince1970:(double)212123232544.0/1000.0]);
    XCTAssertEqual(buo.publiclyIndex,                       NO);
    XCTAssertEqual(buo.locallyIndex,                        YES);
    XCTAssertEqualObjects(buo.creationDate,                 [NSDate dateWithTimeIntervalSince1970:(double)1501869445321.0/1000.0]);

    XCTAssertEqualObjects(buo.expirationDate.description,   @"1976-09-21 03:07:12 +0000");
    XCTAssertEqualObjects(buo.creationDate.description,     @"2017-08-04 17:57:25 +0000");

    // Check serialization of the dictionary.

    NSDictionary *newDictionary = [buo dictionary];
    XCTAssert(newDictionary);

    NSMutableDictionary *oldDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    oldDictionary[@"$publicly_indexable"] = nil; // Remove this value since we don't add false values.
    XCTAssertEqualObjects(oldDictionary, newDictionary);

    NSData* data = [NSJSONSerialization dataWithJSONObject:newDictionary options:0 error:&error];
    XCTAssertNil(error);
    XCTAssert(data);

    // NSString *newString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // Can't compare strings since the item order may be different.
    // XCTAssertEqualObjects(jsonString, newString);
}

- (void) testSchemaDescription {
    NSDictionary *d = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    BranchUniversalObject *b = [BranchUniversalObject objectWithDictionary:d];
    NSString *s = b.contentMetadata.description;
    BNCTAssertEqualMaskedString(s,
        @"<BranchContentMetadata 0x**************** schema: COMMERCE_PRODUCT userData: 1 items>");
}

- (void) testBUODescription {
    NSString *mask = [self stringFromBundleWithKey:@"BUODescription"];
    NSDictionary *d = [self mutableDictionaryFromBundleJSONWithKey:@"BranchUniversalObjectJSON"];
    BranchUniversalObject *b = [BranchUniversalObject objectWithDictionary:d];
    NSString *s = b.description;
    NSLog(@"%@\n%@", s, mask);
    XCTAssertTrue([s bnc_isEqualToMaskedString:mask]);
}

- (void) testDeprecations {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"

    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.price = 10.00;
    buo.currency = BNCCurrencyUSD;
    buo.type = @"Purchase";
    buo.contentIndexMode = BranchContentIndexModePublic;
    buo.metadata = @{ @"Key1": @"Value1" };
    buo.automaticallyListOnSpotlight = YES;

    XCTAssertEqualObjects(buo.contentMetadata.price, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
    XCTAssertEqualObjects(buo.contentMetadata.currency, BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.contentMetadata.contentSchema, @"Purchase");
    XCTAssertEqual(buo.locallyIndex, YES);
    XCTAssertEqual(buo.publiclyIndex, YES);
    XCTAssertEqualObjects(buo.contentMetadata.customMetadata, @{ @"Key1": @"Value1" } );

    XCTAssertEqual(buo.price, 10.00);
    XCTAssertEqualObjects(buo.currency, BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.type, @"Purchase");;
    XCTAssertEqual(buo.contentIndexMode, BranchContentIndexModePublic);
    XCTAssertEqualObjects(buo.metadata, @{ @"Key1": @"Value1" });
    XCTAssertEqual(buo.automaticallyListOnSpotlight, YES);

    buo.contentMetadata.customMetadata = (NSMutableDictionary*) @{ @"Key2": @"Value2" };
    buo.contentMetadata.customMetadata[@"Key3"] = @"Value3";
    [buo addMetadataKey:@"Key4" value:@"Value4"];
    NSDictionary *d = @{
        @"Key2": @"Value2",
        @"Key3": @"Value3",
        @"Key4": @"Value4",
    };
    XCTAssertEqualObjects(buo.metadata, d);

    #pragma clang diagnostic pop
}

- (void) testDictionary {
    NSDictionary *d = nil;
    BranchUniversalObject *buo = [BranchUniversalObject new];

    buo.contentMetadata.customMetadata = (id) @{};
    d = [NSDictionary new];
    XCTAssertEqualObjects(buo.contentMetadata.customMetadata, d);

    buo.contentMetadata.customMetadata = (id) @{};
    buo.contentMetadata.customMetadata[@"a"] = @"b";
    d = @{ @"a": @"b" };
    XCTAssertEqualObjects(buo.contentMetadata.customMetadata, d);

    buo.contentMetadata.customMetadata = [NSMutableDictionary dictionaryWithDictionary:@{@"1": @"2"}];
    buo.contentMetadata.customMetadata[@"3"] = @"4";
    d = @{
        @"1": @"2",
        @"3": @"4",
    };
    XCTAssertEqualObjects(buo.contentMetadata.customMetadata, d);
}

- (void) testRegisterView {
    Branch *branch = [Branch getInstance:@"key_live_foo"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"testRegisterView"];
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

        NSString *eventName = parameters[@"name"];
        if ([url containsString:@"branch.io/v2/event/standard"] &&
            [eventName isEqualToString:@"VIEW_ITEM"]) {
            [expectation fulfill];
        }
    });

    [branch clearNetworkQueue];
    BranchUniversalObject *buo = [BranchUniversalObject new];
    buo.canonicalIdentifier = @"Uniq!";
    buo.title = @"Object Title";
    [buo registerViewWithCallback:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
        XCTAssertNil(error);
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end

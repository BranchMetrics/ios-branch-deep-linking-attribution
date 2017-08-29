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

    XCTAssertEqualObjects(buo.schemaData.contentSchema,     BranchContentSchemaCommerceProduct);
    XCTAssertEqual(buo.schemaData.quantity,                 2);
    XCTAssertEqualObjects(buo.schemaData.price,             [NSDecimalNumber decimalNumberWithString:@"23.20"]);
    XCTAssertEqualObjects(buo.schemaData.currency,          BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.schemaData.sku,               @"1994320302");
    XCTAssertEqualObjects(buo.schemaData.productName,       @"my_product_name1");
    XCTAssertEqualObjects(buo.schemaData.productBrand,      @"my_prod_Brand1");
    XCTAssertEqualObjects(buo.schemaData.productCategory,   BNCProductCategoryBabyToddler);
    XCTAssertEqualObjects(buo.schemaData.productVariant,    @"3T");
    XCTAssertEqual(buo.schemaData.ratingAverage,            5);
    XCTAssertEqual(buo.schemaData.ratingCount,              5);
    XCTAssertEqual(buo.schemaData.ratingMaximum,            7);
    XCTAssertEqualObjects(buo.schemaData.addressStreet,     @"Street_name1");
    XCTAssertEqualObjects(buo.schemaData.addressCity,       @"city1");
    XCTAssertEqualObjects(buo.schemaData.addressRegion,     @"Region1");
    XCTAssertEqualObjects(buo.schemaData.addressCountry,    @"Country1");
    XCTAssertEqualObjects(buo.schemaData.addressPostalCode, @"postal_code");
    XCTAssertEqual(buo.schemaData.latitude,                 12.07);
    XCTAssertEqual(buo.schemaData.longitude,                -97.5);
    NSArray *array = @[@"my_img_caption1", @"my_img_caption_2"];
    XCTAssertEqualObjects(buo.schemaData.imageCaptions,     array);
    XCTAssertEqualObjects(buo.schemaData.userInfo,          @{@"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1"});
    XCTAssertEqualObjects(buo.title,                        @"My Content Title");
    XCTAssertEqualObjects(buo.canonicalIdentifier,          @"item/12345");
    XCTAssertEqualObjects(buo.canonicalUrl,                 @"https://branch.io/deepviews");
    array = @[@"My_Keyword1", @"My_Keyword2"];
    XCTAssertEqualObjects(buo.keywords,                     array);
    XCTAssertEqualObjects(buo.contentDescription,           @"my_product_description1");
    XCTAssertEqualObjects(buo.imageUrl,                     @"https://test_img_url");
    XCTAssertEqualObjects(buo.expirationDate,               [NSDate dateWithTimeIntervalSince1970:(double)212123232544.0/1000.0]);
    XCTAssertEqual(buo.indexPublicly,                       NO);
    XCTAssertEqual(buo.indexLocally,                        YES);
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
    NSString *s = b.schemaData.description;
    BNCTAssertEqualMaskedString(s,
        @"<BranchSchemaData 0x**************** schema: COMMERCE_PRODUCT userData: 1 items>");
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

    XCTAssertEqualObjects(buo.schemaData.price, [NSDecimalNumber decimalNumberWithString:@"10.00"]);
    XCTAssertEqualObjects(buo.schemaData.currency, BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.schemaData.contentSchema, @"Purchase");
    XCTAssertEqual(buo.indexLocally, YES);
    XCTAssertEqual(buo.indexPublicly, YES);
    XCTAssertEqualObjects(buo.schemaData.userInfo, @{ @"Key1": @"Value1" } );

    XCTAssertEqual(buo.price, 10.00);
    XCTAssertEqualObjects(buo.currency, BNCCurrencyUSD);
    XCTAssertEqualObjects(buo.type, @"Purchase");;
    XCTAssertEqual(buo.contentIndexMode, BranchContentIndexModePublic);
    XCTAssertEqualObjects(buo.metadata, @{ @"Key1": @"Value1" });
    XCTAssertEqual(buo.automaticallyListOnSpotlight, YES);

    buo.schemaData.userInfo = (NSMutableDictionary*) @{ @"Key2": @"Value2" };
    buo.schemaData.userInfo[@"Key3"] = @"Value3";
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

    buo.schemaData.userInfo = (id) @{};
    d = [NSDictionary new];
    XCTAssertEqualObjects(buo.schemaData.userInfo, d);

    buo.schemaData.userInfo = (id) @{};
    buo.schemaData.userInfo[@"a"] = @"b";
    d = @{ @"a": @"b" };
    XCTAssertEqualObjects(buo.schemaData.userInfo, d);

    buo.schemaData.userInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"1": @"2"}];
    buo.schemaData.userInfo[@"3"] = @"4";
    d = @{
        @"1": @"2",
        @"3": @"4",
    };
    XCTAssertEqualObjects(buo.schemaData.userInfo, d);
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
            [eventName isEqualToString:@"VIEW_CONTENT"]) {
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

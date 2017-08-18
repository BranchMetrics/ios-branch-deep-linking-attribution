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
    XCTAssertEqualObjects(buo.schemaData.productCategory,   @"Baby & Toddler");
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
    XCTAssertEqualObjects(buo.expirationDate,               [NSDate dateWithTimeIntervalSince1970:212123232544.0/1000.0]);
    XCTAssertEqual(buo.indexPublicly,                       NO);
    XCTAssertEqual(buo.indexLocally,                        YES);
    XCTAssertEqualObjects(buo.creationDate,                 [NSDate dateWithTimeIntervalSince1970:1501869445321.0/1000.0]);

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

@end

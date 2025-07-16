//
//  BranchUniversalObjectTests.m
//  Branch-TestBed
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchUniversalObject.h"

@interface BranchUniversalObjectTests : XCTestCase
@end

@implementation BranchUniversalObjectTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

#pragma mark BranchContentMetadata tests

- (BranchContentMetadata *)branchContentMetadataWithAllPropertiesSet {
    BranchContentMetadata *metadata = [BranchContentMetadata new];
    metadata.contentSchema = BranchContentSchemaOther;
    metadata.quantity = 10;
    metadata.price = [[NSDecimalNumber alloc] initWithDouble:5.5];
    metadata.currency = BNCCurrencyUSD;
    metadata.sku = @"testSKU";
    metadata.productName = @"testProductName";
    metadata.productBrand = @"testProductBrand";
    metadata.productCategory = BNCProductCategoryApparel;
    metadata.productVariant = @"testProductVariant";
    metadata.condition = BranchConditionNew;
    metadata.ratingAverage = 3.5;
    metadata.ratingCount = 2;
    metadata.ratingMax = 4;
    metadata.rating = 3;
    metadata.addressStreet = @"195 Page Mill Road";
    metadata.addressCity = @"Palo Alto";
    metadata.addressRegion = @"CA";
    metadata.addressCountry = @"USA";
    metadata.addressPostalCode = @"94306";
    metadata.latitude = 37.426;
    metadata.longitude = -122.138;
    
    metadata.imageCaptions = @[
        @"Hello World",
        @"Goodbye World"
    ].mutableCopy;
    
    metadata.customMetadata = @{
        @"custom0": @"custom data 0"
    }.mutableCopy;
    
    return metadata;
}

- (void)verifyBranchContentMetadataWithAllProperties:(BranchContentMetadata *)metadata {
    XCTAssertNotNil(metadata);

    XCTAssertEqual(BranchContentSchemaOther, metadata.contentSchema);
    XCTAssertTrue([@(10) isEqualToNumber:@(metadata.quantity)]);
    XCTAssertTrue([[[NSDecimalNumber alloc] initWithDouble:5.5] isEqualToNumber:metadata.price]);

    XCTAssertEqual(BNCCurrencyUSD, metadata.currency);
    XCTAssertTrue([@"testSKU" isEqualToString:metadata.sku]);
    XCTAssertTrue([@"testProductName" isEqualToString:metadata.productName]);
    XCTAssertTrue([@"testProductBrand" isEqualToString:metadata.productBrand]);
    XCTAssertEqual(BNCProductCategoryApparel, metadata.productCategory);
    XCTAssertTrue([@"testProductVariant" isEqualToString:metadata.productVariant]);
    XCTAssertEqual(BranchConditionNew, metadata.condition);
    XCTAssertTrue([@(3.5) isEqualToNumber:@(metadata.ratingAverage)]);
    XCTAssertTrue([@(2) isEqualToNumber:@(metadata.ratingCount)]);
    XCTAssertTrue([@(4) isEqualToNumber:@(metadata.ratingMax)]);
    XCTAssertTrue([@(3) isEqualToNumber:@(metadata.rating)]);

    XCTAssertTrue([@"195 Page Mill Road" isEqualToString:metadata.addressStreet]);
    XCTAssertTrue([@"Palo Alto" isEqualToString:metadata.addressCity]);
    XCTAssertTrue([@"CA" isEqualToString:metadata.addressRegion]);
    XCTAssertTrue([@"USA" isEqualToString:metadata.addressCountry]);
    XCTAssertTrue([@"94306" isEqualToString:metadata.addressPostalCode]);
    
    XCTAssertTrue([@(37.426) isEqualToNumber:@(metadata.latitude)]);
    XCTAssertTrue([@(-122.138) isEqualToNumber:@(metadata.longitude)]);

    XCTAssertNotNil(metadata.imageCaptions);
    XCTAssertTrue(metadata.imageCaptions.count == 2);
    XCTAssertTrue([metadata.imageCaptions[0] isEqualToString:@"Hello World"]);
    XCTAssertTrue([metadata.imageCaptions[1] isEqualToString:@"Goodbye World"]);

    XCTAssertNotNil(metadata.customMetadata);
    XCTAssertTrue(metadata.customMetadata.allKeys.count == 1);
}

- (void)verifyBranchContentMetadataDictionaryWithAllPropertiesSet:(NSDictionary *)dict {
    XCTAssertTrue([@"OTHER" isEqualToString:dict[@"$content_schema"]]);
    XCTAssertTrue([@(10) isEqualToNumber:dict[@"$quantity"]]);
    XCTAssertTrue([[[NSDecimalNumber alloc] initWithDouble:5.5] isEqualToNumber:dict[@"$price"]]);
    XCTAssertTrue([@"USD" isEqualToString:dict[@"$currency"]]);
    XCTAssertTrue([@"testSKU" isEqualToString:dict[@"$sku"]]);
    XCTAssertTrue([@"testProductName" isEqualToString:dict[@"$product_name"]]);
    XCTAssertTrue([@"testProductBrand" isEqualToString:dict[@"$product_brand"]]);
    XCTAssertTrue([@"Apparel & Accessories" isEqualToString:dict[@"$product_category"]]);
    XCTAssertTrue([@"testProductVariant" isEqualToString:dict[@"$product_variant"]]);
    XCTAssertTrue([@"NEW" isEqualToString:dict[@"$condition"]]);

    XCTAssertTrue([@(3.5) isEqualToNumber:dict[@"$rating_average"]]);
    XCTAssertTrue([@(2) isEqualToNumber:dict[@"$rating_count"]]);
    XCTAssertTrue([@(4) isEqualToNumber:dict[@"$rating_max"]]);
    XCTAssertTrue([@(3) isEqualToNumber:dict[@"$rating"]]);

    XCTAssertTrue([@"195 Page Mill Road" isEqualToString:dict[@"$address_street"]]);
    XCTAssertTrue([@"Palo Alto" isEqualToString:dict[@"$address_city"]]);
    XCTAssertTrue([@"CA" isEqualToString:dict[@"$address_region"]]);
    XCTAssertTrue([@"USA" isEqualToString:dict[@"$address_country"]]);
    XCTAssertTrue([@"94306" isEqualToString:dict[@"$address_postal_code"]]);

    XCTAssertTrue([@(37.426) isEqualToNumber:dict[@"$latitude"]]);
    XCTAssertTrue([@(-122.138) isEqualToNumber:dict[@"$longitude"]]);

    XCTAssertTrue([dict[@"$image_captions"] isKindOfClass:NSArray.class]);
    NSArray *tmp = dict[@"$image_captions"];
    XCTAssertTrue(tmp.count == 2);
    XCTAssertTrue([tmp[0] isEqualToString:@"Hello World"]);
    XCTAssertTrue([tmp[1] isEqualToString:@"Goodbye World"]);
    
    XCTAssertTrue([@"custom data 0" isEqualToString:dict[@"custom0"]]);
}

- (void)testBranchContentMetadataCreation_NoPropertiesSet {
    BranchContentMetadata *metadata = [BranchContentMetadata new];
    
    // most properties default to nil. primitives default to 0
    XCTAssertNil(metadata.contentSchema);
    XCTAssertEqual(0, metadata.quantity);
    XCTAssertNil(metadata.price);
    XCTAssertNil(metadata.currency);
    XCTAssertNil(metadata.sku);
    XCTAssertNil(metadata.productName);
    XCTAssertNil(metadata.productBrand);
    XCTAssertNil(metadata.productCategory);
    XCTAssertNil(metadata.productVariant);
    XCTAssertNil(metadata.condition);
    XCTAssertEqual(0, metadata.ratingAverage);
    XCTAssertEqual(0, metadata.ratingCount);
    XCTAssertEqual(0, metadata.ratingMax);
    XCTAssertEqual(0, metadata.rating);
    XCTAssertNil(metadata.addressStreet);
    XCTAssertNil(metadata.addressCity);
    XCTAssertNil(metadata.addressRegion);
    XCTAssertNil(metadata.addressCountry);
    XCTAssertNil(metadata.addressPostalCode);
    XCTAssertEqual(0, metadata.latitude);
    XCTAssertEqual(0, metadata.longitude);
    
    // defaults to an empty array
    XCTAssertNotNil(metadata.imageCaptions);
    XCTAssertTrue(metadata.imageCaptions.count == 0);
    
    // defaults to an empty dictionary
    XCTAssertNotNil(metadata.customMetadata);
    XCTAssertTrue(metadata.customMetadata.allKeys.count == 0);
}

- (void)testBranchContentMetadataCreation_AllPropertiesSet {
    BranchContentMetadata *metadata = [self branchContentMetadataWithAllPropertiesSet];
    [self verifyBranchContentMetadataWithAllProperties:metadata];
}

- (void)testBranchContentMetadataDictionary_NoPropertiesSet {
    BranchContentMetadata *metadata = [BranchContentMetadata new];
    NSDictionary *dict = metadata.dictionary;
    
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.allKeys.count == 0);
}

- (void)testBranchContentMetadataDictionary_AllPropertiesSet {
    BranchContentMetadata *metadata = [self branchContentMetadataWithAllPropertiesSet];
    NSDictionary *dict = metadata.dictionary;

    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.allKeys.count == 23);
    [self verifyBranchContentMetadataDictionaryWithAllPropertiesSet:dict];
}

- (void)testBranchContentMetadata_contentMetadataWithDictionary {
    BranchContentMetadata *original = [self branchContentMetadataWithAllPropertiesSet];
    NSDictionary *dict = [original dictionary];
    
    BranchContentMetadata *metadata = [BranchContentMetadata contentMetadataWithDictionary:dict];
    [self verifyBranchContentMetadataWithAllProperties:metadata];
}

- (void)testBranchContentMetadataDescription_NoPropertiesSet {
    BranchContentMetadata *metadata = [BranchContentMetadata new];
    NSString *desc = [metadata description];
    XCTAssertTrue([desc containsString:@"BranchContentMetadata"]);
    XCTAssertTrue([desc containsString:@"schema: (null) userData: 0 items"]);
}

- (void)testBranchContentMetadataDescription_AllPropertiesSet {
    BranchContentMetadata *metadata = [self branchContentMetadataWithAllPropertiesSet];
    NSString *desc = [metadata description];
    XCTAssertTrue([desc containsString:@"BranchContentMetadata"]);
    XCTAssertTrue([desc containsString:@"schema: OTHER userData: 1 items"]);
}

#pragma mark BranchUniversalObject tests

- (BranchUniversalObject *)branchUniversalObjectWithAllPropertiesSet {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"io.branch.testObject"];
    buo.canonicalUrl = @"https://branch.io";
    buo.title = @"Test Title";
    buo.contentDescription = @"the quick brown fox jumps over the lazy dog";
    buo.imageUrl = @"https://branch.io";
    buo.keywords = @[@"keyword1", @"keyword2"];
    buo.expirationDate = [NSDate dateWithTimeIntervalSinceNow:1];
    buo.locallyIndex = YES;
    buo.publiclyIndex = YES;
    
    buo.contentMetadata = [self branchContentMetadataWithAllPropertiesSet];
    return buo;
}

- (void)verifyBranchUniversalObjectWithAllPropertiesSet:(BranchUniversalObject *)buo {
    XCTAssertNotNil(buo);
    XCTAssertTrue([@"https://branch.io" isEqualToString:buo.canonicalUrl]);
    XCTAssertTrue([@"Test Title" isEqualToString:buo.title]);
    XCTAssertTrue([@"the quick brown fox jumps over the lazy dog" isEqualToString:buo.contentDescription]);
    XCTAssertTrue([@"https://branch.io" isEqualToString:buo.imageUrl]);
    
    XCTAssertTrue(buo.keywords.count == 2);
    XCTAssertTrue([buo.keywords[0] isEqualToString:@"keyword1"]);
    XCTAssertTrue([buo.keywords[1] isEqualToString:@"keyword2"]);

    XCTAssertTrue([buo.creationDate compare:buo.expirationDate] == NSOrderedAscending);
    
    XCTAssertTrue(buo.locallyIndex);
    XCTAssertTrue(buo.publiclyIndex);
    
    [self verifyBranchContentMetadataWithAllProperties:buo.contentMetadata];
}

- (void)verifyBranchUniversalObjectDictionaryWithAllPropertiesSet:(NSDictionary *)dict {
    XCTAssertTrue([@"io.branch.testObject" isEqualToString:dict[@"$canonical_identifier"]]);
    XCTAssertTrue([@"https://branch.io" isEqualToString:dict[@"$canonical_url"]]);
    XCTAssertTrue([@"Test Title" isEqualToString:dict[@"$og_title"]]);
    XCTAssertTrue([@"the quick brown fox jumps over the lazy dog" isEqualToString:dict[@"$og_description"]]);
    XCTAssertTrue([@"https://branch.io" isEqualToString:dict[@"$og_image_url"]]);

    XCTAssertTrue(dict[@"$locally_indexable"]);
    XCTAssertTrue(dict[@"$publicly_indexable"]);
    
    XCTAssertTrue([dict[@"$creation_timestamp"] isKindOfClass:NSNumber.class]);
    XCTAssertTrue([dict[@"$exp_date"] isKindOfClass:NSNumber.class]);
    NSNumber *creationDate  = dict[@"$creation_timestamp"];
    NSNumber *expirationDate = dict[@"$exp_date"];
    XCTAssertTrue([creationDate compare:expirationDate] == NSOrderedAscending);
    
    XCTAssertTrue([dict[@"$keywords"] isKindOfClass:NSArray.class]);
    NSArray *tmp = dict[@"$keywords"];
    XCTAssertTrue(tmp.count == 2);
    XCTAssertTrue([tmp[0] isEqualToString:@"keyword1"]);
    XCTAssertTrue([tmp[1] isEqualToString:@"keyword2"]);

    // the BranchContentMetadata dictionary is NOT in a sub dictionary, it is merged in at the top level
    [self verifyBranchContentMetadataDictionaryWithAllPropertiesSet:dict];
}

- (void)testBranchUniversalObjectCreation {
    BranchUniversalObject *buo = [BranchUniversalObject new];
    XCTAssertNotNil(buo);
    
    XCTAssertNil(buo.canonicalIdentifier);
    XCTAssertNil(buo.canonicalUrl);
    XCTAssertNil(buo.title);
    XCTAssertNil(buo.contentDescription);
    XCTAssertNil(buo.imageUrl);
    XCTAssertNil(buo.keywords);
    XCTAssertNil(buo.creationDate);
    XCTAssertNil(buo.expirationDate);
    XCTAssertFalse(buo.locallyIndex);
    XCTAssertFalse(buo.publiclyIndex);
    
    XCTAssertNotNil(buo.contentMetadata);
}

- (void)testBranchUniversalObjectCreation_initWithCanonicalIdentifier {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"io.branch.testObject"];
    XCTAssertNotNil(buo);
    
    XCTAssertTrue([@"io.branch.testObject" isEqualToString:buo.canonicalIdentifier]);
    XCTAssertNil(buo.canonicalUrl);
    XCTAssertNil(buo.title);
    XCTAssertNil(buo.contentDescription);
    XCTAssertNil(buo.imageUrl);
    XCTAssertNil(buo.keywords);
    XCTAssertNotNil(buo.creationDate);
    XCTAssertNil(buo.expirationDate);
    XCTAssertFalse(buo.locallyIndex);
    XCTAssertFalse(buo.publiclyIndex);
    
    XCTAssertNotNil(buo.contentMetadata);
}

- (void)testBranchUniversalObjectCreation_initWithTitle {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithTitle:@"Test Title"];
    XCTAssertNotNil(buo);
    
    XCTAssertNil(buo.canonicalIdentifier);
    XCTAssertNil(buo.canonicalUrl);
    XCTAssertTrue([@"Test Title" isEqualToString:buo.title]);
    XCTAssertNil(buo.contentDescription);
    XCTAssertNil(buo.imageUrl);
    XCTAssertNil(buo.keywords);
    XCTAssertNotNil(buo.creationDate);
    XCTAssertNil(buo.expirationDate);
    XCTAssertFalse(buo.locallyIndex);
    XCTAssertFalse(buo.publiclyIndex);
    
    XCTAssertNotNil(buo.contentMetadata);
}

- (void)testBranchUniversalObject_AllPropertiesSet {
    BranchUniversalObject *buo = [self branchUniversalObjectWithAllPropertiesSet];
    [self verifyBranchUniversalObjectWithAllPropertiesSet:buo];
}

- (void)testBranchUniversalObjectDescription_AllPropertiesSet {
    BranchUniversalObject *buo = [self branchUniversalObjectWithAllPropertiesSet];
    NSString *desc = buo.description;
    
    // Verifies a few properties used to generate the description string
    XCTAssertTrue([desc containsString:@"BranchUniversalObject"]);
    XCTAssertTrue([desc containsString:@"canonicalIdentifier: io.branch.testObject"]);
    XCTAssertTrue([desc containsString:@"title: Test Title"]);
    XCTAssertTrue([desc containsString:@"contentDescription: the quick brown fox jumps over the lazy dog"]);
}

- (void)testBranchUniversalObjectDictionary_AllPropertiesSet {
    BranchUniversalObject *buo = [self branchUniversalObjectWithAllPropertiesSet];
    NSDictionary *dict = buo.dictionary;
    
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.allKeys.count == 33);
    [self verifyBranchUniversalObjectDictionaryWithAllPropertiesSet:dict];
}

- (void)testBranchUniversalObject_objectWithDictionary {
    BranchUniversalObject *original = [self branchUniversalObjectWithAllPropertiesSet];
    NSDictionary *dict = [original dictionary];
        
    BranchUniversalObject *buo = [BranchUniversalObject objectWithDictionary:dict];
    [self verifyBranchUniversalObjectWithAllPropertiesSet:buo];
}

- (void)testBranchUniversalObject_getDictionaryWithCompleteLinkProperties_NoLinkPropertiesSet {
    BranchUniversalObject *original = [self branchUniversalObjectWithAllPropertiesSet];
    BranchLinkProperties *linkProperties = [BranchLinkProperties new];
    NSDictionary *dict = [original getDictionaryWithCompleteLinkProperties:linkProperties];
    
    XCTAssertNotNil(dict);
    XCTAssertTrue([@(0) isEqualToNumber:dict[@"~duration"]]);
}

- (void)testBranchUniversalObject_getDictionaryWithCompleteLinkProperties_AllLinkPropertiesSet {
    BranchUniversalObject *original = [self branchUniversalObjectWithAllPropertiesSet];
    BranchLinkProperties *linkProperties = [BranchLinkProperties new];
    
    linkProperties.tags = @[@"tag1", @"tag2"];
    linkProperties.feature = @"test feature";
    linkProperties.alias = @"test alias";
    linkProperties.channel = @"test channel";
    linkProperties.matchDuration = 10;
    
    // BranchUniversalObject.controlParams overwrites BranchContentMetadata.customMetadata
    linkProperties.controlParams = @{
        @"testControlParam": @"test control param",
        //@"custom0": @"test control param"
    };
    
    NSDictionary *dict = [original getDictionaryWithCompleteLinkProperties:linkProperties];
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.allKeys.count == 39);
    
    XCTAssertTrue([@(10) isEqualToNumber:dict[@"~duration"]]);
    XCTAssertTrue([@"test alias" isEqualToString:dict[@"~alias"]]);
    XCTAssertTrue([@"test channel" isEqualToString:dict[@"~channel"]]);
    XCTAssertTrue([@"test feature" isEqualToString:dict[@"~feature"]]);
    
    XCTAssertTrue([@"test control param" isEqualToString:dict[@"testControlParam"]]);
    
    // BranchUniversalObject fields are at the top level of the dictionary
    [self verifyBranchUniversalObjectDictionaryWithAllPropertiesSet:dict];
}

- (void)testBranchUniversalObject_getParamsForServerRequestWithAddedLinkProperties_NoLinkPropertiesSet {
    BranchUniversalObject *original = [self branchUniversalObjectWithAllPropertiesSet];
    BranchLinkProperties *linkProperties = [BranchLinkProperties new];

    // Nothing is added with this call
    NSDictionary *dict = [original getParamsForServerRequestWithAddedLinkProperties:linkProperties];
    
    XCTAssertNotNil(dict);

    // BranchUniversalObject fields are at the top level of the dictionary
    [self verifyBranchUniversalObjectDictionaryWithAllPropertiesSet:dict];
}

- (void)testBranchUniversalObject_getParamsForServerRequestWithAddedLinkProperties_AllLinkPropertiesSet {
    BranchUniversalObject *original = [self branchUniversalObjectWithAllPropertiesSet];
    BranchLinkProperties *linkProperties = [BranchLinkProperties new];
    linkProperties.tags = @[@"tag1", @"tag2"];
    linkProperties.feature = @"test feature";
    linkProperties.alias = @"test alias";
    linkProperties.channel = @"test channel";
    linkProperties.matchDuration = 10;
    
    // BranchUniversalObject.controlParams overwrites BranchContentMetadata.customMetadata
    linkProperties.controlParams = @{
        @"testControlParam": @"test control param",
        //@"custom0": @"test control param"
    };
    
    NSDictionary *dict = [original getParamsForServerRequestWithAddedLinkProperties:linkProperties];
    XCTAssertNotNil(dict);
    XCTAssertTrue(dict.allKeys.count == 34);

    // only the control parameters are in the dictionary
    XCTAssertTrue([@"test control param" isEqualToString:dict[@"testControlParam"]]);
    XCTAssertNil(dict[@"~duration"]);
    XCTAssertNil(dict[@"~alias"]);
    XCTAssertNil(dict[@"~channel"]);
    XCTAssertNil(dict[@"~feature"]);

    // BranchUniversalObject fields are at the top level of the dictionary
    [self verifyBranchUniversalObjectDictionaryWithAllPropertiesSet:dict];
}

@end

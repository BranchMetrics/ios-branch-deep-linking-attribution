//
//  BranchUniversalObject.m
//  Branch-SDK
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BranchUniversalObject.h"
#import "NSError+Branch.h"
#import "BranchConstants.h"
#import "BranchLogger.h"
#import "BNCEncodingUtils.h"
#import "Branch.h"
#import "BranchEvent.h"
#import "NSMutableDictionary+Branch.h"

#if !TARGET_OS_TV
#import "BNCUserAgentCollector.h"
#endif

#pragma mark BranchContentSchema

BranchContentSchema _Nonnull BranchContentSchemaCommerceAuction     = @"COMMERCE_AUCTION";
BranchContentSchema _Nonnull BranchContentSchemaCommerceBusiness    = @"COMMERCE_BUSINESS";
BranchContentSchema _Nonnull BranchContentSchemaCommerceOther       = @"COMMERCE_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaCommerceProduct     = @"COMMERCE_PRODUCT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceRestaurant  = @"COMMERCE_RESTAURANT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceService     = @"COMMERCE_SERVICE";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelFlight= @"COMMERCE_TRAVEL_FLIGHT";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelHotel = @"COMMERCE_TRAVEL_HOTEL";
BranchContentSchema _Nonnull BranchContentSchemaCommerceTravelOther = @"COMMERCE_TRAVEL_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaGameState           = @"GAME_STATE";
BranchContentSchema _Nonnull BranchContentSchemaMediaImage          = @"MEDIA_IMAGE";
BranchContentSchema _Nonnull BranchContentSchemaMediaMixed          = @"MEDIA_MIXED";
BranchContentSchema _Nonnull BranchContentSchemaMediaMusic          = @"MEDIA_MUSIC";
BranchContentSchema _Nonnull BranchContentSchemaMediaOther          = @"MEDIA_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaMediaVideo          = @"MEDIA_VIDEO";
BranchContentSchema _Nonnull BranchContentSchemaOther               = @"OTHER";
BranchContentSchema _Nonnull BranchContentSchemaTextArticle         = @"TEXT_ARTICLE";
BranchContentSchema _Nonnull BranchContentSchemaTextBlog            = @"TEXT_BLOG";
BranchContentSchema _Nonnull BranchContentSchemaTextOther           = @"TEXT_OTHER";
BranchContentSchema _Nonnull BranchContentSchemaTextRecipe          = @"TEXT_RECIPE";
BranchContentSchema _Nonnull BranchContentSchemaTextReview          = @"TEXT_REVIEW";
BranchContentSchema _Nonnull BranchContentSchemaTextSearchResults   = @"TEXT_SEARCH_RESULTS";
BranchContentSchema _Nonnull BranchContentSchemaTextStory           = @"TEXT_STORY";
BranchContentSchema _Nonnull BranchContentSchemaTextTechnicalDoc    = @"TEXT_TECHNICAL_DOC";

#pragma mark - BranchCondition

BranchCondition _Nonnull BranchConditionOther         = @"OTHER";
BranchCondition _Nonnull BranchConditionExcellent     = @"EXCELLENT";
BranchCondition _Nonnull BranchConditionNew           = @"NEW";
BranchCondition _Nonnull BranchConditionGood          = @"GOOD";
BranchCondition _Nonnull BranchConditionFair          = @"FAIR";
BranchCondition _Nonnull BranchConditionPoor          = @"POOR";
BranchCondition _Nonnull BranchConditionUsed          = @"USED";
BranchCondition _Nonnull BranchConditionRefurbished   = @"REFURBISHED";

#pragma mark - BranchContentMetadata

@interface BranchContentMetadata () {
    NSMutableArray      *_imageCaptions;
    NSMutableDictionary *_customMetadata;
}
@end

@implementation BranchContentMetadata

- (NSDictionary*_Nonnull) dictionary {
    NSMutableDictionary*dictionary = [NSMutableDictionary new];

    for (NSString *key in self.customMetadata.keyEnumerator) {
        NSString *value = self.customMetadata[key];
        dictionary[key] = value;
    }

    [dictionary bnc_addString:self.contentSchema forKey:@"$content_schema"];
    [dictionary bnc_addDouble:self.quantity forKey:@"$quantity"];
    [dictionary bnc_addDecimal:self.price forKey:@"$price"];
    [dictionary bnc_addString:self.currency forKey:@"$currency"];
    [dictionary bnc_addString:self.sku forKey:@"$sku"];
    [dictionary bnc_addString:self.productName forKey:@"$product_name"];
    [dictionary bnc_addString:self.productBrand forKey:@"$product_brand"];
    [dictionary bnc_addString:self.productCategory forKey:@"$product_category"];
    [dictionary bnc_addString:self.productVariant forKey:@"$product_variant"];
    [dictionary bnc_addString:self.condition forKey:@"$condition"];
    [dictionary bnc_addDouble:self.ratingAverage forKey:@"$rating_average"];
    [dictionary bnc_addInteger:self.ratingCount forKey:@"$rating_count"];
    [dictionary bnc_addDouble:self.ratingMax forKey:@"$rating_max"];
    [dictionary bnc_addDouble:self.rating forKey:@"$rating"];
    [dictionary bnc_addString:self.addressStreet forKey:@"$address_street"];
    [dictionary bnc_addString:self.addressCity forKey:@"$address_city"];
    [dictionary bnc_addString:self.addressRegion forKey:@"$address_region"];
    [dictionary bnc_addString:self.addressCountry forKey:@"$address_country"];
    [dictionary bnc_addString:self.addressPostalCode forKey:@"$address_postal_code"];
    [dictionary bnc_addDouble:self.latitude forKey:@"$latitude"];
    [dictionary bnc_addDouble:self.longitude forKey:@"$longitude"];
    [dictionary bnc_addStringArray:self.imageCaptions forKey:@"$image_captions"];
    
    return dictionary;
}

+ (BranchContentMetadata*_Nonnull) contentMetadataWithDictionary:(NSDictionary*_Nullable)dictionary {
    BranchContentMetadata *object = [BranchContentMetadata new];
    if (!dictionary) return object;
    
    // category is on NSMutableDictionary. If dictionary is already mutable, it just returns. Otherwise it does a shallow copy.
    NSMutableDictionary *dict = [dictionary mutableCopy];

    object.contentSchema = [dict bnc_getStringForKey:@"$content_schema"];
    object.quantity = [dict bnc_getDoubleForKey:@"$quantity"];
    object.price = [dict bnc_getDecimalForKey:@"$price"];
    object.currency = [dict bnc_getStringForKey:@"$currency"];
    object.sku = [dict bnc_getStringForKey:@"$sku"];
    object.productName = [dict bnc_getStringForKey:@"$product_name"];
    object.productBrand = [dict bnc_getStringForKey:@"$product_brand"];
    object.productCategory = [dict bnc_getStringForKey:@"$product_category"];
    object.productVariant = [dict bnc_getStringForKey:@"$product_variant"];
    object.condition = [dict bnc_getStringForKey:@"$condition"];
    object.ratingAverage = [dict bnc_getDoubleForKey:@"$rating_average"];
    object.ratingCount = [dict bnc_getIntForKey:@"$rating_count"];
    object.ratingMax = [dict bnc_getDoubleForKey:@"$rating_max"];
    object.rating = [dict bnc_getDoubleForKey:@"$rating"];
    object.addressStreet = [dict bnc_getStringForKey:@"$address_street"];
    object.addressCity = [dict bnc_getStringForKey:@"$address_city"];
    object.addressRegion = [dict bnc_getStringForKey:@"$address_region"];
    object.addressCountry = [dict bnc_getStringForKey:@"$address_country"];
    object.addressPostalCode = [dict bnc_getStringForKey:@"$address_postal_code"];
    object.latitude = [dict bnc_getDoubleForKey:@"$latitude"];
    object.longitude = [dict bnc_getDoubleForKey:@"$longitude"];
    object.imageCaptions = [dict bnc_getArrayForKey:@"$image_captions"];
    
    NSSet *fieldsAdded = [NSSet setWithArray:@[
        @"$canonical_identifier",
        @"$canonical_url",
        @"$creation_timestamp",
        @"$exp_date",
        @"$keywords",
        @"$locally_indexable",
        @"$og_description",
        @"$og_image_url",
        @"$og_title",
        @"$publicly_indexable",
        @"$content_schema",
        @"$quantity",
        @"$price",
        @"$currency",
        @"$sku",
        @"$product_name",
        @"$product_brand",
        @"$product_category",
        @"$product_variant",
        @"$condition",
        @"$rating_average",
        @"$rating_count",
        @"$rating_max",
        @"$rating",
        @"$address_street",
        @"$address_city",
        @"$address_region",
        @"$address_country",
        @"$address_postal_code",
        @"$latitude",
        @"$longitude",
        @"$image_captions",
        @"$custom_fields",
    ]];

    // Add any extra fields to the content object.contentMetadata.customMetadata
    for (NSString *key in dictionary.keyEnumerator) {
        if (![fieldsAdded containsObject:key]) {
            object.customMetadata[key] = dictionary[key];
        }
    }

    return object;
}

- (NSMutableDictionary*) customMetadata {
    if (!_customMetadata) _customMetadata = [NSMutableDictionary new];
    return _customMetadata;
}

- (void) setCustomMetadata:(NSMutableDictionary*)dictionary {
    _customMetadata = [dictionary mutableCopy];
}

- (void) setImageCaptions:(NSMutableArray<NSString *> *)imageCaptions {
    _imageCaptions = [imageCaptions mutableCopy];
}

- (NSMutableArray<NSString *> *) imageCaptions {
    if (!_imageCaptions) _imageCaptions = [NSMutableArray new];
    return _imageCaptions;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"<%@ 0x%016llx schema: %@ userData: %ld items>",
        NSStringFromClass(self.class),
        (uint64_t) self,
        _contentSchema,
        (long) _customMetadata.count
    ];
}

@end

#pragma mark - BranchUniversalObject

@implementation BranchUniversalObject

- (instancetype)initWithCanonicalIdentifier:(NSString *)canonicalIdentifier {
    if ((self = [super init])) {
        self.canonicalIdentifier = canonicalIdentifier;
        self.creationDate = [NSDate date];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    if ((self = [super init])) {
        self.title = title;
        self.creationDate = [NSDate date];
    }
    return self;
}

#pragma mark - Deprecated Fields

- (NSDictionary *)metadata {
    return self.contentMetadata.customMetadata;
}

- (void) setMetadata:(NSDictionary *)metadata {
    self.contentMetadata.customMetadata = (NSMutableDictionary*) metadata;
}

- (void)addMetadataKey:(NSString *)key value:(NSString *)value {
    if (key) [self.contentMetadata.customMetadata setValue:value forKey:key];
}

- (CGFloat) price {
    return [self.contentMetadata.price floatValue];
}

- (void) setPrice:(CGFloat)price {
    NSString *string = [NSString stringWithFormat:@"%f", price];
    self.contentMetadata.price = [NSDecimalNumber decimalNumberWithString:string];
}

- (NSString*) currency {
    return self.contentMetadata.currency;
}

- (void) setCurrency:(NSString *)currency {
    self.contentMetadata.currency = currency;
}

- (NSString*) type {
    return self.contentMetadata.contentSchema;
}

- (void) setType:(NSString*)type {
    self.contentMetadata.contentSchema = type;
}

- (BranchContentIndexMode) contentIndexMode {
    if (self.publiclyIndex)
        return BranchContentIndexModePublic;
    else
        return BranchContentIndexModePrivate;
}

- (void) setContentIndexMode:(BranchContentIndexMode)contentIndexMode {
    if (contentIndexMode == BranchContentIndexModePublic)
        self.publiclyIndex = YES;
    else
        self.locallyIndex = YES;
}

- (BOOL) automaticallyListOnSpotlight {
    return self.locallyIndex;
}

- (void) setAutomaticallyListOnSpotlight:(BOOL)automaticallyListOnSpotlight {
    self.locallyIndex = automaticallyListOnSpotlight;
}

#pragma mark - Setters / Getters / Standard Methods

- (BranchContentMetadata*) contentMetadata {
    if (!_contentMetadata) _contentMetadata = [BranchContentMetadata new];
    return _contentMetadata;
}

- (NSString *)description {
    return [NSString stringWithFormat:
        @"<%@ 0x%016llx"
         "\n canonicalIdentifier: %@"
         "\n title: %@"
         "\n contentDescription: %@"
         "\n imageUrl: %@"
         "\n metadata: %@"
         "\n type: %@"
         "\n locallyIndex: %d"
         "\n publiclyIndex: %d"
         "\n keywords: %@"
         "\n expirationDate: %@"
         "\n>",
         NSStringFromClass(self.class), (uint64_t) self,
        self.canonicalIdentifier,
        self.title,
        self.contentDescription,
        self.imageUrl,
        self.contentMetadata.customMetadata,
        self.contentMetadata.contentSchema,
        self.locallyIndex,
        self.publiclyIndex,
        self.keywords,
        self.expirationDate];
}

#pragma mark - User Event Logging

- (void)registerView {
    [self registerViewWithCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = @"Could not register view.";
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        [[BranchLogger shared] logWarning:@"TODO: replace this error" error:error];
        if (callback) callback([[NSDictionary alloc] init], error);
        return;
    }
    
    #if !TARGET_OS_TV
    if (self.locallyIndex) {
        [self listOnSpotlight];
    }
    #endif
    
    [[BranchEvent standardEvent:BranchStandardEventViewItem withContentItem:self] logEvent];
    if (callback) callback(@{}, nil);
}

#pragma mark - Link Creation Methods

- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        [[BranchLogger shared] logWarning:@"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL." error:nil];

        return nil;
    }
    
    return [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                               andTags:linkProperties.tags
                                              andAlias:linkProperties.alias
                                            andChannel:linkProperties.channel
                                            andFeature:linkProperties.feature
                                              andStage:linkProperties.stage
                                           andCampaign:linkProperties.campaign
                                      andMatchDuration:linkProperties.matchDuration];
}

- (void)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties andCallback:(callbackWithUrl)callback {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = @"Could not generate a URL.";
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        [[BranchLogger shared] logWarning:@"TODO: replace this error" error:error];
        if (callback) callback([BNCPreferenceHelper sharedInstance].userUrl, error);
        return;
    }
    
    [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                        andTags:linkProperties.tags
                                       andAlias:linkProperties.alias
                               andMatchDuration:linkProperties.matchDuration
                                     andChannel:linkProperties.channel
                                     andFeature:linkProperties.feature
                                       andStage:linkProperties.stage
                                    andCampaign:linkProperties.campaign
                                    andCallback:callback];
}

- (NSString *)getShortUrlWithLinkPropertiesAndIgnoreFirstClick:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = @"Could not generate a URL.";
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        [[BranchLogger shared] logWarning:@"TODO: replace this error" error:error];
        return nil;
    }
    
    // user agent should be cached on startup
    NSString *UAString = nil;
    #if !TARGET_OS_TV
    UAString = [BNCUserAgentCollector instance].userAgent;
    #endif
    
    return [[Branch getInstance] getShortURLWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                        andTags:linkProperties.tags
                                     andChannel:linkProperties.channel
                                     andFeature:linkProperties.feature
                                       andStage:linkProperties.stage
                                    andCampaign:linkProperties.campaign
                                       andAlias:linkProperties.alias
                                 ignoreUAString:UAString
                              forceLinkCreation:YES];
}

- (NSString *)getLongUrlWithChannel:(NSString *)channel
                            andTags:(NSArray *)tags
                         andFeature:(NSString *)feature
                           andStage:(NSString *)stage
                           andAlias:(NSString *)alias {
    NSString *urlString =
        [[Branch getInstance]
            getLongURLWithParams:self.dictionary
            andChannel:channel
            andTags:tags
            andFeature:feature
            andStage:stage
            andAlias:alias];
    return urlString;
}

#pragma mark - Share Sheets
#if !TARGET_OS_TV

- (void)showShareSheetWithShareText:(NSString *)shareText
                         completion:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completion {
    [self showShareSheetWithLinkProperties:nil andShareText:shareText fromViewController:nil completionWithError:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties
                            andShareText:(NSString *)shareText
                      fromViewController:(UIViewController *)viewController
                     completionWithError:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:viewController anchor:nil completionWithError:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties
                            andShareText:(NSString *)shareText
                      fromViewController:(UIViewController *)viewController
                                  anchor:(nullable id)anchorViewOrButtonItem
                   completionWithError:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completion {
    
    BranchShareLink *shareLink = [[BranchShareLink alloc] initWithUniversalObject:self linkProperties:linkProperties];
    shareLink.shareText = shareText;
    shareLink.completionError = completion;
    [shareLink presentActivityViewControllerFromViewController:viewController anchor:anchorViewOrButtonItem];
}

#pragma mark - Spotlight

- (void)listOnSpotlight {
    [self listOnSpotlightWithCallback:nil];
}

- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback {
    [[Branch getInstance]
        indexOnSpotlightWithBranchUniversalObject:self
        linkProperties:nil
        completion:^(BranchUniversalObject *universalObject, NSString *url, NSError *error) {
            if (callback) callback(url,error);
        }];
}

//This one uses a callback that returns the SpotlightIdentifier
- (void)listOnSpotlightWithIdentifierCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    BOOL publiclyIndexable;
    if (self.contentIndexMode == BranchContentIndexModePrivate) {
        publiclyIndexable = NO;
    } else {
        publiclyIndexable = YES;
    }
    
    NSMutableDictionary *metadataAndProperties = [self.metadata mutableCopy];
    if (self.canonicalIdentifier) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = self.canonicalIdentifier;
    }
    if (self.canonicalUrl) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_URL] = self.canonicalUrl;
    }
    
    [[Branch getInstance] createDiscoverableContentWithTitle:self.title
                                                 description:self.contentDescription
                                                thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                                 canonicalId:self.canonicalIdentifier
                                                  linkParams:metadataAndProperties.copy
                                                        type:self.type
                                           publiclyIndexable:publiclyIndexable
                                                    keywords:[NSSet setWithArray:self.keywords]
                                              expirationDate:self.expirationDate
                                           spotlightCallback:spotlightCallback];
}

- (void)listOnSpotlightWithLinkProperties:(BranchLinkProperties*_Nullable)linkproperties
                                callback:(void (^_Nullable)(NSString * _Nullable url,
                                                            NSError * _Nullable error))completion {
    [[Branch getInstance]
        indexOnSpotlightWithBranchUniversalObject:self
        linkProperties:linkproperties
        completion:^(BranchUniversalObject *universalObject, NSString *url, NSError *error) {
            if (completion) completion(url,error);
        }];
}

- (void)removeFromSpotlightWithCallback:(void (^_Nullable)(NSError * _Nullable error))completion {
    if (self.locallyIndex) {
        [[Branch getInstance] removeSearchableItemWithBranchUniversalObject:self callback:^(NSError *error) {
            if (completion) {
                completion(error);
            }
        }];
    } else {
        NSError *error = [NSError branchErrorWithCode:BNCSpotlightPublicIndexError localizedMessage:@"Publically indexed cannot be removed from Spotlight"];
        if (completion) completion(error);
    }
}
#endif

#pragma mark - Dictionary Methods

- (NSDictionary *)getParamsForServerRequestWithAddedLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = self.dictionary;
    [temp addEntriesFromDictionary:[linkProperties.controlParams copy]];
    return temp;
}

- (NSDictionary *)getDictionaryWithCompleteLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    
    [self safeSetValue:linkProperties.tags forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_TAGS] onDict:temp];
    [self safeSetValue:linkProperties.feature forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_FEATURE] onDict:temp];
    [self safeSetValue:linkProperties.alias forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_ALIAS] onDict:temp];
    [self safeSetValue:linkProperties.channel forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_CHANNEL] onDict:temp];
    [self safeSetValue:linkProperties.stage forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_STAGE] onDict:temp];
    [self safeSetValue:linkProperties.campaign forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_CAMPAIGN] onDict:temp];
    [self safeSetValue:@(linkProperties.matchDuration) forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_DURATION] onDict:temp];

    return [temp copy];
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

+ (BranchUniversalObject*_Nonnull) objectWithDictionary:(NSDictionary*_Null_unspecified)dictionary {
    BranchUniversalObject *object = [BranchUniversalObject new];
    
    // category is on NSMutableDictionary. If dictionary is already mutable, it just returns. Otherwise it does a shallow copy.
    NSMutableDictionary *dict = [dictionary mutableCopy];
    
    object.canonicalIdentifier = [dict bnc_getStringForKey:@"$canonical_identifier"];
    object.canonicalUrl = [dict bnc_getStringForKey:@"$canonical_url"];
    object.creationDate = [dict bnc_getDateForKey:@"$creation_timestamp"];
    object.expirationDate = [dict bnc_getDateForKey:@"$exp_date"];
    object.keywords = [dict bnc_getArrayForKey:@"$keywords"];
    object.locallyIndex = [dict bnc_getBooleanForKey:@"$locally_indexable"];
    object.contentDescription = [dict bnc_getStringForKey:@"$og_description"];
    object.imageUrl = [dict bnc_getStringForKey:@"$og_image_url"];
    object.title = [dict bnc_getStringForKey:@"$og_title"];
    object.publiclyIndex = [dict bnc_getBooleanForKey:@"$publicly_indexable"];

    BranchContentMetadata *data = [BranchContentMetadata contentMetadataWithDictionary:dictionary];
    object.contentMetadata = data;

    return object;
}

- (NSDictionary*_Nonnull) dictionary {

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    NSDictionary *contentDictionary = [self.contentMetadata dictionary];
    if (contentDictionary.count) [dictionary addEntriesFromDictionary:contentDictionary];
    
    [dictionary bnc_addString:self.canonicalIdentifier forKey:@"$canonical_identifier"];
    [dictionary bnc_addString:self.canonicalUrl forKey:@"$canonical_url"];
    [dictionary bnc_addDate:self.creationDate forKey:@"$creation_timestamp"];
    [dictionary bnc_addDate:self.expirationDate forKey:@"$exp_date"];
    [dictionary bnc_addStringArray:self.keywords forKey:@"$keywords"];
    [dictionary bnc_addBoolean:self.locallyIndex forKey:@"$locally_indexable"];
    [dictionary bnc_addString:self.contentDescription forKey:@"$og_description"];
    [dictionary bnc_addString:self.imageUrl forKey:@"$og_image_url"];
    [dictionary bnc_addString:self.title forKey:@"$og_title"];
    [dictionary bnc_addBoolean:self.publiclyIndex forKey:@"$publicly_indexable"];

    return dictionary;
}

@end

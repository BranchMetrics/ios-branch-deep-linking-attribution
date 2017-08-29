//
//  BranchUniversalObject.m
//  Branch-SDK
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BranchUniversalObject.h"
#import "BNCError.h"
#import "BranchConstants.h"
#import "BNCFabricAnswers.h"
#import "BNCDeviceInfo.h"
#import "BNCLog.h"
#import "BNCLocalization.h"
#import "BNCEncodingUtils.h"
#import "Branch.h"

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

#pragma mark - BranchProductCondition

BranchProductCondition _Nonnull BranchProductConditionOther         = @"OTHER";
BranchProductCondition _Nonnull BranchProductConditionNew           = @"NEW";
BranchProductCondition _Nonnull BranchProductConditionGood          = @"GOOD";
BranchProductCondition _Nonnull BranchProductConditionFair          = @"FAIR";
BranchProductCondition _Nonnull BranchProductConditionPoor          = @"POOR";
BranchProductCondition _Nonnull BranchProductConditionUsed          = @"USED";
BranchProductCondition _Nonnull BranchProductConditionRefurbished   = @"REFURBISHED";

#pragma mark - BranchSchemaData

@interface BranchSchemaData () {
    NSMutableArray      *_imageCaptions;
    NSMutableDictionary *_userInfo;
}
@end

@implementation BranchSchemaData

- (NSDictionary*_Nonnull) dictionary {
    NSMutableDictionary*dictionary = [NSMutableDictionary new];

    #define BNCFieldDefinesDictionaryFromSelf
    #include "BNCFieldDefines.h"

    addString(contentSchema,    $content_schema);
    addDouble(quantity,         $quantity);
    addDecimal(price,           $price);
    addString(currency,         $currency);
    addString(sku,              $sku);
    addString(productName,      $product_name);
    addString(productBrand,     $product_brand);
    addString(productCategory,  $product_category);
    addString(productVariant,   $product_variant);
    addDouble(ratingAverage,    $rating_average);
    addInteger(ratingCount,     $rating_count);
    addDouble(ratingMaximum,    $rating_max);
    addString(addressStreet,    $address_street);
    addString(addressCity,      $address_city);
    addString(addressRegion,    $address_region);
    addString(addressCountry,   $address_country);
    addString(addressPostalCode,$address_postal_code);
    addDouble(latitude,         $latitude);
    addDouble(longitude,        $longitude);
    addStringArray(imageCaptions,$image_captions);
    addStringifiedDictionary(userInfo, $custom_fields);

    #include "BNCFieldDefines.h"

    return dictionary;
}

+ (BranchSchemaData*_Nonnull) schemaDataWithDictionary:(NSDictionary*_Nullable)dictionary {
    BranchSchemaData*object = [BranchSchemaData new];
    if (!dictionary) return object;

    #define BNCFieldDefinesObjectFromDictionary
    #include "BNCFieldDefines.h"

    addString(contentSchema,    $content_schema);
    addDouble(quantity,         $quantity);
    addDecimal(price,           $price);
    addString(currency,         $currency);
    addString(sku,              $sku);
    addString(productName,      $product_name);
    addString(productBrand,     $product_brand);
    addString(productCategory,  $product_category);
    addString(productVariant,   $product_variant);
    addDouble(ratingAverage,    $rating_average);
    addInteger(ratingCount,     $rating_count);
    addDouble(ratingMaximum,    $rating_max);
    addString(addressStreet,    $address_street);
    addString(addressCity,      $address_city);
    addString(addressRegion,    $address_region);
    addString(addressCountry,   $address_country);
    addString(addressPostalCode,$address_postal_code);
    addDouble(latitude,         $latitude);
    addDouble(longitude,        $longitude);
    addStringArray(imageCaptions,$image_captions);
    addStringifiedDictionary(userInfo, $custom_fields);

    #include "BNCFieldDefines.h"

    return object;
}

- (NSMutableDictionary*) userInfo {
    if (!_userInfo) _userInfo = [NSMutableDictionary new];
    return _userInfo;
}

- (void) setUserInfo:(NSMutableDictionary*)dictionary {
    _userInfo = [dictionary mutableCopy];
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
        (long) _userInfo.count
    ];
}

@end

#pragma mark - BranchUniversalObject

@implementation BranchUniversalObject

- (instancetype)initWithCanonicalIdentifier:(NSString *)canonicalIdentifier {
    if (self = [super init]) {
        self.canonicalIdentifier = canonicalIdentifier;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        self.title = title;
    }
    return self;
}

#pragma mark - Deprecated Fields

- (NSDictionary *)metadata {
    return self.schemaData.userInfo;
}

- (void) setMetadata:(NSDictionary *)metadata {
    self.schemaData.userInfo = (NSMutableDictionary*) metadata;
}

- (void)addMetadataKey:(NSString *)key value:(NSString *)value {
    if (key) [self.schemaData.userInfo setValue:value forKey:key];
}

- (CGFloat) price {
    return [self.schemaData.price floatValue];
}

- (void) setPrice:(CGFloat)price {
    NSString *string = [NSString stringWithFormat:@"%f", price];
    self.schemaData.price = [NSDecimalNumber decimalNumberWithString:string];
}

- (NSString*) currency {
    return self.schemaData.currency;
}

- (void) setCurrency:(NSString *)currency {
    self.schemaData.currency = currency;
}

- (NSString*) type {
    return self.schemaData.contentSchema;
}

- (void) setType:(NSString*)type {
    self.schemaData.contentSchema = type;
}

- (BranchContentIndexMode) contentIndexMode {
    if (self.indexPublicly)
        return BranchContentIndexModePublic;
    else
        return BranchContentIndexModePrivate;
}

- (void) setContentIndexMode:(BranchContentIndexMode)contentIndexMode {
    if (contentIndexMode == BranchContentIndexModePublic)
        self.indexPublicly = YES;
    else
        self.indexLocally = YES;
}

- (BOOL) automaticallyListOnSpotlight {
    return self.indexLocally;
}

- (void) setAutomaticallyListOnSpotlight:(BOOL)automaticallyListOnSpotlight {
    self.indexLocally = automaticallyListOnSpotlight;
}

#pragma mark - Setters / Getters / Standard Methods

- (BranchSchemaData*) schemaData {
    if (!_schemaData) _schemaData = [BranchSchemaData new];
    return _schemaData;
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
         "\n indexLocally: %d"
         "\n indexPublically: %d"
         "\n keywords: %@"
         "\n expirationDate: %@"
         "\n>",
         NSStringFromClass(self.class), (uint64_t) self,
        self.canonicalIdentifier,
        self.title,
        self.contentDescription,
        self.imageUrl,
        self.schemaData.userInfo,
        self.schemaData.contentSchema,
        self.indexLocally,
        self.indexPublicly,
        self.keywords,
        self.expirationDate];
}

#pragma mark - User Event Logging

- (void)registerView {
    [self registerViewWithCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = BNCLocalizedString(@"Could not register view.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        if (callback) callback([[NSDictionary alloc] init], error);
        return;
    }
    if (self.indexLocally) {
        [self listOnSpotlight];
    }
    [[Branch getInstance] registerViewWithParams:[self getParamsForServerRequest] andCallback:callback];
}

- (void)userCompletedAction:(NSString *)action {
    [self userCompletedAction:action withState:nil];
}

- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state {
    if (state) [self.schemaData.userInfo addEntriesFromDictionary:state];
    [[BranchEvent customEventWithName:action contentItem:self] logEvent];

    // Maybe list on spotlight --
    NSDictionary *linkParams = [self getParamsForServerRequest];
    if (self.indexLocally && self.canonicalIdentifier && linkParams) {

        NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] init];
        actionPayload[BNCCanonicalIdList] = @[self.canonicalIdentifier];
        actionPayload[self.canonicalIdentifier] = linkParams;
        if (state) [actionPayload addEntriesFromDictionary:state];

        if ([action isEqualToString:BNCRegisterViewEvent])
            [self listOnSpotlight];
    }
}

#pragma mark - Link Creation Methods

- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        BNCLogWarning(@"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
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
        NSString *message = BNCLocalizedString(@"Could not generate a URL.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        if (callback) callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
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
        NSString *message = BNCLocalizedString(@"Could not generate a URL.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        return nil;
    }
    // keep this operation outside of sync operation below.
    NSString *UAString = [BNCDeviceInfo userAgentString];

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

#pragma mark - Share Sheets

- (UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.canonicalUrl && !self.title) {
        BNCLogWarning(@"A canonicalIdentifier, canonicalURL, or title are required to uniquely identify content. "
            "In order to not break the end user experience with sharing, Branch SDK will proceed to create a URL, "
            "but content analytics may not properly include this URL.");
    }
    
    NSMutableDictionary *params = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    if (linkProperties.matchDuration) {
        [params setObject:@(linkProperties.matchDuration) forKey:BRANCH_REQUEST_KEY_URL_DURATION];
    }

    return [Branch getBranchActivityItemWithParams:params
                                           feature:linkProperties.feature
                                             stage:linkProperties.stage
                                          campaign:linkProperties.campaign
                                              tags:linkProperties.tags
                                             alias:linkProperties.alias];
}

- (void)showShareSheetWithShareText:(NSString *)shareText
                         completion:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed))completion {
    [self showShareSheetWithLinkProperties:nil andShareText:shareText fromViewController:nil completion:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties
                            andShareText:(NSString *)shareText
                      fromViewController:(UIViewController *)viewController
                              completion:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed))completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText
        fromViewController:viewController anchor:nil completion:completion orCompletionWithError:nil];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties
                            andShareText:(NSString *)shareText
                      fromViewController:(UIViewController *)viewController
                     completionWithError:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText
        fromViewController:viewController anchor:nil completion:nil orCompletionWithError:completion];
}

- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                            andShareText:(nullable NSString *)shareText
                      fromViewController:(nullable UIViewController *)viewController
                                  anchor:(nullable UIBarButtonItem *)anchor
                              completion:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed))completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText
        fromViewController:viewController anchor:anchor completion:completion orCompletionWithError:nil];
}

- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties
                            andShareText:(nullable NSString *)shareText
                      fromViewController:(nullable UIViewController *)viewController
                                  anchor:(nullable UIBarButtonItem *)anchor
                     completionWithError:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText
        fromViewController:viewController anchor:anchor completion:nil orCompletionWithError:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties
                            andShareText:(NSString *)shareText
                      fromViewController:(UIViewController *)viewController
                                  anchor:(UIBarButtonItem *)anchor
                              completion:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed))completion
                   orCompletionWithError:(void (^ _Nullable)(NSString * _Nullable activityType, BOOL completed, NSError*_Nullable error))completionError {

    // Log share initiated event
    [[BranchEvent customEventWithName:BNCShareInitiatedEvent contentItem:self] logEvent];
    UIActivityItemProvider *itemProvider = [self getBranchActivityItemWithLinkProperties:linkProperties];
    NSMutableArray *items = [NSMutableArray arrayWithObject:itemProvider];
    if (shareText) {
        [items insertObject:shareText atIndex:0];
    }
    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    if ([shareViewController respondsToSelector:@selector(completionWithItemsHandler)]) {
        shareViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            // Log share completed event
            [[BranchEvent customEventWithName:BNCShareCompletedEvent contentItem:self] logEvent];
            if (completion || completionError) {
                if (completion) { completion(activityType, completed); }
                else if (completionError) { completionError(activityType, completed, activityError); }
                [BNCFabricAnswers sendEventWithName:@"Branch Share" andAttributes:[self getDictionaryWithCompleteLinkProperties:linkProperties]];
            }
        };
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Deprecated in iOS 8.  Safe to hide deprecation warnings as the new completion handler is checked for above
        shareViewController.completionHandler = completion;
        #pragma clang diagnostic pop
    }
    
    UIViewController *presentingViewController;
    if (viewController && [viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        presentingViewController = viewController;
    }
    else {
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        if ([[[[UIApplicationClass sharedApplication].delegate window] rootViewController] respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            presentingViewController = [[[UIApplicationClass sharedApplication].delegate window] rootViewController];
        }
    }
    
    if (linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT]) {
        @try {
            [shareViewController setValue:linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT] forKey:@"subject"];
        }
        @catch (NSException *exception) {
            BNCLogWarning(@"Unable to setValue 'emailSubject' forKey 'subject' on UIActivityViewController.");
        }
    }
    
    if (presentingViewController) {
        // Required for iPad/Universal apps on iOS 8+
        if ([presentingViewController respondsToSelector:@selector(popoverPresentationController)]) {
            shareViewController.popoverPresentationController.sourceView = presentingViewController.view;
            if (anchor) {
                shareViewController.popoverPresentationController.barButtonItem = anchor;
            }
        }
        [presentingViewController presentViewController:shareViewController animated:YES completion:nil];
    }
    else {
        BNCLogWarning(@"Unable to show the share sheet since no view controller is present.");
    }
}

#pragma mark - Spotlight

- (void)listOnSpotlight {
    [self listOnSpotlightWithCallback:nil];
}

- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback {
    NSMutableDictionary *metadataAndProperties = [self.schemaData.userInfo mutableCopy];
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
                                                        type:self.schemaData.contentSchema
                                           publiclyIndexable:self.indexPublicly
                                                    keywords:[NSSet setWithArray:self.keywords]
                                              expirationDate:self.expirationDate
                                                    callback:callback];
}


//This one uses a callback that returns the SpotlightIdentifier
- (void)listOnSpotlightWithIdentifierCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    BOOL publiclyIndexable;
    if (self.contentIndexMode == BranchContentIndexModePrivate) {
        publiclyIndexable = NO;
    }
    else {
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

#pragma mark - Dictionary Methods

+ (BranchUniversalObject *)getBranchUniversalObjectFromDictionary:(NSDictionary *)dictionary {
    BranchUniversalObject *universalObject = [[BranchUniversalObject alloc] init];
    
    // Build BranchUniversalObject base properties
    universalObject.schemaData.userInfo = [dictionary copy];
    if (dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER]) {
        universalObject.canonicalIdentifier = dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_URL]) {
        universalObject.canonicalUrl = dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_URL];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_TITLE]) {
        universalObject.title = dictionary[BRANCH_LINK_DATA_KEY_OG_TITLE];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION]) {
        universalObject.contentDescription = dictionary[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL]) {
        universalObject.imageUrl = dictionary[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL];
    }
    universalObject.indexPublicly = [dictionary[BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE] boolValue];
    universalObject.indexLocally  = [dictionary[BRANCH_LINK_DATA_KEY_LOCALLY_INDEXABLE] boolValue];

    NSNumber *number = dictionary[BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE];
    if ([number isKindOfClass:[NSNumber class]]) {
        // Number is millisecondsSince1970
        universalObject.expirationDate = [NSDate dateWithTimeIntervalSince1970:number.integerValue/1000];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_KEYWORDS]) {
        universalObject.keywords = dictionary[BRANCH_LINK_DATA_KEY_KEYWORDS];
    }
    if (dictionary[BNCPurchaseAmount]) {
        universalObject.schemaData.price = [NSDecimalNumber decimalNumberWithString:dictionary[BNCPurchaseAmount]];
    }
    if (dictionary[BNCPurchaseCurrency]) {
        universalObject.schemaData.currency = dictionary[BNCPurchaseCurrency];
    }
    
    if (dictionary[BRANCH_LINK_DATA_KEY_CONTENT_TYPE]) {
        universalObject.schemaData.contentSchema = dictionary[BRANCH_LINK_DATA_KEY_CONTENT_TYPE];
    }
    return universalObject;
}

- (NSDictionary*_Nonnull) getParamsForServerRequest {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    [self safeSetValue:self.canonicalIdentifier forKey:BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER onDict:temp];
    [self safeSetValue:self.canonicalUrl forKey:BRANCH_LINK_DATA_KEY_CANONICAL_URL onDict:temp];
    [self safeSetValue:self.title forKey:BRANCH_LINK_DATA_KEY_OG_TITLE onDict:temp];
    [self safeSetValue:self.contentDescription forKey:BRANCH_LINK_DATA_KEY_OG_DESCRIPTION onDict:temp];
    [self safeSetValue:self.imageUrl forKey:BRANCH_LINK_DATA_KEY_OG_IMAGE_URL onDict:temp];
    temp[BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE]  = [NSNumber numberWithBool:self.indexPublicly];
    temp[BRANCH_LINK_DATA_KEY_LOCALLY_INDEXABLE]   = [NSNumber numberWithBool:self.indexLocally];
    [self safeSetValue:self.keywords forKey:BRANCH_LINK_DATA_KEY_KEYWORDS onDict:temp];
    [self safeSetValue:@(1000 * [self.expirationDate timeIntervalSince1970]) forKey:BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE onDict:temp];
    [self safeSetValue:self.schemaData.contentSchema forKey:BRANCH_LINK_DATA_KEY_CONTENT_TYPE onDict:temp];
    [self safeSetValue:self.schemaData.currency forKey:BNCPurchaseCurrency onDict:temp];
    temp[BNCPurchaseAmount] = self.schemaData.price;
    [temp addEntriesFromDictionary:[self.schemaData.userInfo copy]];
    return [temp copy];
}

- (NSDictionary *)getParamsForServerRequestWithAddedLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = [[self getParamsForServerRequest] mutableCopy];
    [temp addEntriesFromDictionary:[linkProperties.controlParams copy]]; // TODO: Add warnings if controlParams contains non-control params
    return [temp copy];
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

    #define BNCFieldDefinesObjectFromDictionary
    #include "BNCFieldDefines.h"

    addString(canonicalIdentifier,          $canonical_identifier);
    addString(canonicalUrl,                 $canonical_url);
    addDate(creationDate,                   $creation_timestamp);
    addDate(expirationDate,                 $exp_date);
    addStringArray(keywords,                $keywords);
    addBoolean(indexLocally,                $locally_indexable);
    addString(contentDescription,           $og_description);
    addString(imageUrl,                     $og_image_url);
    addString(title,                        $og_title);
    addBoolean(indexPublicly,               $publicly_indexable);

    #include "BNCFieldDefines.h"

    BranchSchemaData *data = [BranchSchemaData schemaDataWithDictionary:dictionary];
    object.schemaData = data;
    
    return object;
}

- (NSDictionary*_Nonnull) dictionary {

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    #define BNCFieldDefinesDictionaryFromSelf
    #include "BNCFieldDefines.h"

    addString(canonicalIdentifier,          $canonical_identifier);
    addString(canonicalUrl,                 $canonical_url);
    addDate(creationDate,                   $creation_timestamp);
    addDate(expirationDate,                 $exp_date);
    addStringArray(keywords,                $keywords);
    addBoolean(indexLocally,                $locally_indexable);
    addString(contentDescription,           $og_description);
    addString(imageUrl,                     $og_image_url);
    addString(title,                        $og_title);
    addBoolean(indexPublicly,               $publicly_indexable);

    #include "BNCFieldDefines.h"

    NSDictionary *schemaDictionary = [self.schemaData dictionary];
    if (schemaDictionary) [dictionary addEntriesFromDictionary:schemaDictionary];

    return dictionary;
}

@end

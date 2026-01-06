//
//  BranchEvent.m
//  Branch-SDK
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BranchEvent.h"
#import "BranchConstants.h"
#import "NSError+Branch.h"
#import "BranchLogger.h"
#import "BNCCallbackMap.h"
#import "BNCReachability.h"
#import "BNCSKAdNetwork.h"
#import "BNCPartnerParameters.h"
#import "BNCPreferenceHelper.h"
#import "BNCEventUtils.h"
#import "BNCRequestFactory.h"
#import "BNCServerAPI.h"
#import "NSMutableDictionary+Branch.h"

#pragma mark BranchStandardEvents

// Commerce events

BranchStandardEvent BranchStandardEventAddToCart          = @"ADD_TO_CART";
BranchStandardEvent BranchStandardEventAddToWishlist      = @"ADD_TO_WISHLIST";
BranchStandardEvent BranchStandardEventViewCart           = @"VIEW_CART";
BranchStandardEvent BranchStandardEventInitiatePurchase   = @"INITIATE_PURCHASE";
BranchStandardEvent BranchStandardEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BranchStandardEvent BranchStandardEventPurchase           = @"PURCHASE";
BranchStandardEvent BranchStandardEventSpendCredits       = @"SPEND_CREDITS";
BranchStandardEvent BranchStandardEventSubscribe          = @"SUBSCRIBE";
BranchStandardEvent BranchStandardEventStartTrial         = @"START_TRIAL";
BranchStandardEvent BranchStandardEventClickAd            = @"CLICK_AD";
BranchStandardEvent BranchStandardEventViewAd             = @"VIEW_AD";

// Content Events

BranchStandardEvent BranchStandardEventSearch             = @"SEARCH";
BranchStandardEvent BranchStandardEventViewItem           = @"VIEW_ITEM";
BranchStandardEvent BranchStandardEventViewItems          = @"VIEW_ITEMS";
BranchStandardEvent BranchStandardEventRate               = @"RATE";
BranchStandardEvent BranchStandardEventShare              = @"SHARE";
BranchStandardEvent BranchStandardEventInitiateStream     = @"INITIATE_STREAM";
BranchStandardEvent BranchStandardEventCompleteStream     = @"COMPLETE_STREAM";

// User Lifecycle Events

BranchStandardEvent BranchStandardEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BranchStandardEvent BranchStandardEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BranchStandardEvent BranchStandardEventAchieveLevel           = @"ACHIEVE_LEVEL";
BranchStandardEvent BranchStandardEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";
BranchStandardEvent BranchStandardEventInvite                 = @"INVITE";
BranchStandardEvent BranchStandardEventLogin                  = @"LOGIN";
BranchStandardEvent BranchStandardEventReserve                = @"RESERVE";
BranchStandardEvent BranchStandardEventOptIn                  = @"OPT_IN";
BranchStandardEvent BranchStandardEventOptOut                 = @"OPT_OUT";

@implementation BranchEventRequest

- (instancetype) initWithServerURL:(NSURL*)serverURL
                   eventDictionary:(NSDictionary*)eventDictionary
                        completion:(void (^)(NSDictionary* response, NSError* error))completion {

	self = [super init];
	if (!self) return self;

	self.serverURL = serverURL;
	self.eventDictionary = eventDictionary;
	self.completion = completion;
	return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface
			    key:(NSString *)key
           callback:(BNCServerCallback)callback {
    
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForEventWithEventDictionary:[self.eventDictionary mutableCopy]];
    
    [serverInterface postRequest:json url:[self.serverURL absoluteString] key:key callback:callback];
}

- (void)processResponse:(BNCServerResponse*)response error:(NSError*)error {
	NSDictionary *dictionary = ([response.data isKindOfClass:[NSDictionary class]])
		? (NSDictionary*) response.data : nil;
    
#if !TARGET_OS_TV
    if (dictionary && [dictionary[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE] isKindOfClass:NSNumber.class]) {
        NSNumber *conversionValue = (NSNumber *)dictionary[BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE];
        // Regardless of SKAN opted-in in dashboard, we always get conversionValue, so adding check to find out if install/open response had "invoke_register_app" true
        if (conversionValue && [BNCPreferenceHelper sharedInstance].invokeRegisterApp) {
            if (@available(iOS 16.1, macCatalyst 16.1, *)){
                NSString * coarseConversionValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:dictionary] ;
                BOOL lockWin = [[BNCSKAdNetwork sharedInstance] getLockedStatusFromDataResponse:dictionary];
                BOOL shouldCallUpdatePostback = [[BNCSKAdNetwork sharedInstance] shouldCallPostbackForDataResponse:dictionary];
            
                [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"SKAN 4.0 params - conversionValue:%@ coarseValue:%@, locked:%d, shouldCallPostback:%d, currentWindow:%d, firstAppLaunchTime: %@", conversionValue, coarseConversionValue, lockWin, shouldCallUpdatePostback, (int)[BNCPreferenceHelper sharedInstance].skanCurrentWindow, [BNCPreferenceHelper sharedInstance].firstAppLaunchTime] error:nil];
                if(shouldCallUpdatePostback){
                    [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue: conversionValue.longValue coarseValue:coarseConversionValue lockWindow:lockWin completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                        } else {
                            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue] error:nil];
                        }
                    }];
                }
                
            } else if (@available(iOS 15.4, macCatalyst 15.4, *)) {
                [[BNCSKAdNetwork sharedInstance] updatePostbackConversionValue:conversionValue.intValue completionHandler: ^(NSError *error){
                    if (error) {
                        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Update conversion value failed with error - %@", [error description]] error:error];
                    } else {
                        [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Update conversion value was successful. Conversion Value - %@", conversionValue] error:nil];
                    }
                }];
            } else {
                [[BNCSKAdNetwork sharedInstance] updateConversionValue:conversionValue.integerValue];
            }
        }
    }
#endif
    
    if (self.completion) {
		self.completion(dictionary, error);
    }
}

#pragma mark BranchEventRequest NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (!self) return self;

    self.serverURL = [decoder decodeObjectOfClass:NSURL.class forKey:@"serverURL"];
    
    NSSet *classes = [NSSet setWithArray:@[NSDictionary.class, NSArray.class, NSString.class, NSNumber.class]];
    self.eventDictionary = [decoder decodeObjectOfClasses:classes forKey:@"eventDictionary"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.serverURL forKey:@"serverURL"];
    [coder encodeObject:self.eventDictionary forKey:@"eventDictionary"];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

#pragma mark - BranchEvent

@interface BranchEvent ()<SKRequestDelegate, SKProductsRequestDelegate>
@property (nonatomic, copy) NSString*  eventName;
@property (strong, nonatomic) SKProductsRequest *request;
@end

@implementation BranchEvent : NSObject

- (instancetype) initWithName:(NSString *)name {
    self = [super init];
    if (!self) return self;
    _eventName = name;
    _contentItems = [NSArray new];
    _customData = [NSDictionary new];
    _adType = BranchEventAdTypeNone;
    return self;
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent {
    return [[BranchEvent alloc] initWithName:standardEvent];
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent
               withContentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [BranchEvent standardEvent:standardEvent];
    if (contentItem) {
        e.contentItems = @[ contentItem ];
    }
    return e;
}

+ (instancetype) customEventWithName:(NSString*)name {
    return [[BranchEvent alloc] initWithName:name];
}

+ (instancetype) customEventWithName:(NSString*)name
                         contentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [BranchEvent customEventWithName:name];
    if (contentItem) {
        e.contentItems = @[ contentItem ];
    }
    return e;
}

- (NSString *)jsonStringForAdType:(BranchEventAdType)adType {
    switch (adType) {
        case BranchEventAdTypeBanner:
            return @"BANNER";
            
        case BranchEventAdTypeInterstitial:
            return @"INTERSTITIAL";
            
        case BranchEventAdTypeRewardedVideo:
            return @"REWARDED_VIDEO";
            
        case BranchEventAdTypeNative:
            return @"NATIVE";
            
        case BranchEventAdTypeNone:
        default:
            return nil;
    }
}

- (NSDictionary*) dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    
    [dictionary bnc_addString:self.transactionID forKey:@"transaction_id"];
    [dictionary bnc_addString:self.currency forKey:@"currency"];
    [dictionary bnc_addDecimal:self.revenue forKey:@"revenue"];
    [dictionary bnc_addDecimal:self.shipping forKey:@"shipping"];
    [dictionary bnc_addDecimal:self.tax forKey:@"tax"];
    [dictionary bnc_addString:self.coupon forKey:@"coupon"];
    [dictionary bnc_addString:self.affiliation forKey:@"affiliation"];
    [dictionary bnc_addString:self.eventDescription forKey:@"description"];
    [dictionary bnc_addString:self.searchQuery forKey:@"search_query"];
    [dictionary bnc_addDictionary:self.customData forKey:@"custom_data"];
    
    NSString *adTypeString = [self jsonStringForAdType:self.adType];
    if (adTypeString.length > 0) {
        [dictionary setObject:adTypeString forKey:@"ad_type"];
    }
    
    return dictionary;
}

+ (NSArray<BranchStandardEvent>*) standardEvents {
    return @[
        BranchStandardEventAddToCart,
        BranchStandardEventAddToWishlist,
        BranchStandardEventViewCart,
        BranchStandardEventInitiatePurchase,
        BranchStandardEventAddPaymentInfo,
        BranchStandardEventPurchase,
        BranchStandardEventSpendCredits,
        BranchStandardEventSearch,
        BranchStandardEventViewItem,
        BranchStandardEventViewItems,
        BranchStandardEventRate,
        BranchStandardEventShare,
        BranchStandardEventInitiateStream,
        BranchStandardEventCompleteStream,
        BranchStandardEventCompleteRegistration,
        BranchStandardEventCompleteTutorial,
        BranchStandardEventAchieveLevel,
        BranchStandardEventUnlockAchievement,
        BranchStandardEventInvite,
        BranchStandardEventLogin,
        BranchStandardEventReserve,
        BranchStandardEventSubscribe,
        BranchStandardEventStartTrial,
        BranchStandardEventClickAd,
        BranchStandardEventViewAd,
        BranchStandardEventOptOut,
        BranchStandardEventOptIn,
    ];
}

- (void)logEventWithCompletion:(void (^_Nullable)(BOOL success, NSError * _Nullable error))completion {
    if (![_eventName isKindOfClass:[NSString class]] || _eventName.length == 0) {
        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Invalid event type '%@' or empty string.", NSStringFromClass(_eventName.class)] error:nil];

        if (completion) {
            NSError *error = [NSError branchErrorWithCode:BNCGeneralError localizedMessage: @"Invalid event type"];
            completion(NO, error);
        }
        return;
    }
    
    // logEvent requests without a completion are automatically retried later
    if (completion != nil && [[BNCReachability shared] reachabilityStatus] == nil) {
        if (completion) {
            NSError *error = [NSError branchErrorWithCode:BNCGeneralError localizedMessage: @"No connectivity"];
            completion(NO, error);
        }
        return;
    }

    NSDictionary *eventDictionary = [self buildEventDictionary];
    BranchEventRequest *request = [self buildRequestWithEventDictionary:eventDictionary];
    [[BNCCallbackMap shared] storeRequest:request withCompletion:completion];
    
    [[Branch getInstance] sendServerRequest:request];
}

- (void) logEvent {
    [self logEventWithCompletion:nil];
}

- (BranchEventRequest *)buildRequestWithEventDictionary:(NSDictionary *)eventDictionary {    
    NSString *serverURL =
    ([self.class.standardEvents containsObject:self.eventName])
    ? [[BNCServerAPI sharedInstance] standardEventServiceURL]
    : [[BNCServerAPI sharedInstance] customEventServiceURL];

    BranchEventRequest *request =
    [[BranchEventRequest alloc]
     initWithServerURL:[NSURL URLWithString:serverURL]
     eventDictionary:eventDictionary
     completion:nil];
    
    return request;
}

- (NSDictionary *)buildEventDictionary {
    NSMutableDictionary *eventDictionary = [NSMutableDictionary new];
    eventDictionary[@"name"] = _eventName;
    
    if (self.alias.length > 0) {
        eventDictionary[@"customer_event_alias"] = self.alias;
    }
    
    NSDictionary *propertyDictionary = [self dictionary];
    if (propertyDictionary.count) {
        eventDictionary[@"event_data"] = propertyDictionary;
    }
    eventDictionary[@"custom_data"] = eventDictionary[@"event_data"][@"custom_data"];
    eventDictionary[@"event_data"][@"custom_data"] = nil;
    
    NSMutableArray *contentItemDictionaries = [NSMutableArray new];
    for (BranchUniversalObject *contentItem in self.contentItems) {
        NSDictionary *dictionary = [contentItem dictionary];
        if (dictionary.count) {
            [contentItemDictionaries addObject:dictionary];
        }
    }
    
    if (contentItemDictionaries.count) {
        eventDictionary[@"content_items"] = contentItemDictionaries;
    }
    
    NSDictionary *partnerParameters = [[BNCPartnerParameters shared] parameterJson];
    if (partnerParameters.count > 0) {
        eventDictionary[BRANCH_REQUEST_KEY_PARTNER_PARAMETERS] = partnerParameters;
    }
    
    return eventDictionary;
}

- (NSString*_Nonnull) description {
    return [NSString stringWithFormat:
        @"<%@ 0x%016llx %@ txID: %@ Amt: %@ %@ desc: %@ items: %ld customData: %@>",
        NSStringFromClass(self.class),
        (uint64_t) self,
        self.eventName,
        self.transactionID,
        self.currency,
        self.revenue,
        self.eventDescription,
        (long) self.contentItems.count,
        self.customData
    ];
}

#pragma mark - IAP Methods

- (void) logEventWithTransaction:(SKPaymentTransaction *)transaction {
    self.transactionID = transaction.transactionIdentifier;
    [[BNCEventUtils shared] storeEvent:self];
    
    NSString *productId = transaction.payment.productIdentifier;
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productId]];
    
    _request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [[BNCEventUtils shared] removeEvent:self];
        
        if (response.products.count > 0) {
            SKProduct *product = response.products.firstObject;
            
            BranchUniversalObject *buo = [BranchUniversalObject new];
            buo.canonicalIdentifier = product.productIdentifier;
            buo.title = product.localizedTitle;
            buo.contentMetadata.price = product.price;
            buo.contentMetadata.currency = product.priceLocale.currencyCode;
            buo.contentMetadata.productName = product.localizedTitle;
            buo.contentDescription = product.localizedDescription;
            buo.contentMetadata.quantity = 1;
            buo.contentMetadata.customMetadata =  (NSMutableDictionary*) @{
                @"content_version": product.contentVersion,
                @"is_downloadable": @(product.isDownloadable),
            };
            
            if (@available(iOS 14.0, tvOS 14.0, macCatalyst 14.0, *)) {
                [buo.contentMetadata.customMetadata setObject:[@(product.isFamilyShareable) stringValue] forKey:@"is_family_shareable"];
            }
            
            if (product.subscriptionPeriod != nil) {
                NSString *unitString;
                switch (product.subscriptionPeriod.unit) {
                    case SKProductPeriodUnitDay:
                        unitString = @"day";
                        break;
                    case SKProductPeriodUnitWeek:
                        unitString = @"week";
                        break;
                    case SKProductPeriodUnitMonth:
                        unitString = @"month";
                        break;
                    case SKProductPeriodUnitYear:
                        unitString = @"year";
                        break;
                    default:
                        unitString = @"unknown";
                        break;
                }
                NSString *subscriptionPeriodString = [NSString stringWithFormat:@"%ld %@", (long)product.subscriptionPeriod.numberOfUnits, unitString];
                [buo.contentMetadata.customMetadata setObject:subscriptionPeriodString forKey:@"subscription_period"];
            }
            
            if (product.subscriptionGroupIdentifier != nil) {
                [buo.contentMetadata.customMetadata setObject:product.subscriptionGroupIdentifier forKey:@"subscription_group_identifier"];
            }
            
            self.contentItems = [NSArray arrayWithObject:buo];
            self.eventName = BranchStandardEventPurchase;
            self.eventDescription = self.transactionID;
            self.currency = product.priceLocale.currencyCode;
            self.revenue = product.price;
            self.customData = (NSMutableDictionary*) @{
                @"transaction_identifier": self.transactionID,
                @"logged_from_IAP": @true
            };
            
            if (product.subscriptionPeriod != nil) {
                self.alias = @"Subscription";
            } else {
                self.alias = @"IAP";
            }
            
            [self logEvent];
            [[BranchLogger shared] logDebug:[NSString stringWithFormat:@"Created and logged event from transaction: %@", self.description] error:nil];
        } else {
            [[BranchLogger shared] logError:[NSString stringWithFormat:@"Unable to log Branch event from transaction. No products were found with the product ID."] error:nil];
        }
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [[BranchLogger shared] logError:[NSString stringWithFormat:@"Product request failed: %@", error] error:error];
    [[BNCEventUtils shared] removeEvent:self];
}

@end

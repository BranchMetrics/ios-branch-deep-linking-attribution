//
//  BNCEvent.m
//  Branch-TestBed
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCEvent.h"
#import "BNCLog.h"

#pragma mark BNCStandardEvents

// Commerce events

BNCStandardEvent BNCStandardEventAddToCart          = @"ADD_TO_CART";
BNCStandardEvent BNCStandardEventAddToWishlist      = @"ADD_TO_WISHLIST";
BNCStandardEvent BNCStandardEventViewCart           = @"VIEW_CART";
BNCStandardEvent BNCStandardEventInitiatePurchase   = @"INITIATE_PURCHASE";
BNCStandardEvent BNCStandardEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BNCStandardEvent BNCStandardEventPurchase           = @"PURCHASE";
BNCStandardEvent BNCStandardEventSpendCredits       = @"SPEND_CREDITS";

// Content Events

BNCStandardEvent BNCStandardEventSearch             = @"SEARCH";
BNCStandardEvent BNCStandardEventViewContent        = @"VIEW_CONTENT";
BNCStandardEvent BNCStandardEventViewContentList    = @"VIEW_CONTENT_LIST";
BNCStandardEvent BNCStandardEventRate               = @"RATE";
BNCStandardEvent BNCStandardEventShareContent       = @"SHARE_CONTENT";

// User Lifecycle Events

BNCStandardEvent BNCStandardEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BNCStandardEvent BNCStandardEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BNCStandardEvent BNCStandardEventAchieveLevel           = @"ACHIEVE_LEVEL";
BNCStandardEvent BNCStandardEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";

#pragma mark - BNCEventProperties

/*
@property (nonatomic, strong) NSString *transactionID;
@property (nonatomic, strong) BNCCurrency currency;
@property (nonatomic, strong) NSDecimalNumber *revenue;
@property (nonatomic, strong) NSDecimalNumber *shipping;
@property (nonatomic, strong) NSDecimalNumber *tax;
@property (nonatomic, strong) NSString *coupon;
@property (nonatomic, strong) NSString *affiliation;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) NSDictionary<NSString*, id<NSObject>> *customData;
*/

@implementation BNCEventProperties : NSObject

- (NSDictionary*) dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define addProperty(name) { \
        if (_##name) dictionary[@#name] = _##name; \
    }

    if (_transactionID.length) dictionary[@"transaction_id"] = _transactionID;
    addProperty(currency);
    addProperty(revenue);
    addProperty(shipping);
    addProperty(tax);
    addProperty(coupon);
    addProperty(affiliation);
    addProperty(detail);

    if (_customData.count) {
        dictionary[@"custom_data"] = [_customData copy];
    }

    #undef addProperty

    return dictionary;
}

@end

#pragma mark - BranchEventRequest

@interface BranchEventRequest : BNCServerRequest <NSCoding>

- (instancetype) initWithServerURL:(NSURL*)serverURL
                   eventDictionary:(NSDictionary*)eventDictionary
                        completion:(void (^)(NSDictionary* response, NSError* error))completion;

@property (strong) NSDictionary *eventDictionary;
@property (strong) NSURL *serverURL;
@property (copy)   void (^completion)(NSDictionary* response, NSError* error);
@end


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

    [serverInterface postRequest:self.eventDictionary
							 url:[self.serverURL absoluteString]
							 key:key
						callback:callback];
}

- (void)processResponse:(BNCServerResponse*)response
				  error:(NSError*)error {

	NSDictionary *dictionary =
		([response.data isKindOfClass:[NSDictionary class]])
		? (NSDictionary*) response.data
		: nil;
		
	if (self.completion)
		self.completion(dictionary, error);
}


#pragma mark BranchEventRequest NSCoding


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (!self) return self;

	self.serverURL = [decoder decodeObjectForKey:@"serverURL"];
	self.eventDictionary = [decoder decodeObjectForKey:@"eventDictionary"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.serverURL forKey:@"serverURL"];
    [coder encodeObject:self.eventDictionary forKey:@"eventDictionary"];
}

@end

#pragma mark - Branch (BNCStandardEvents)

@implementation Branch (BNCStandardEvents)

+ (NSArray<BNCStandardEvent>*) standardEvents {
    return @[
        BNCStandardEventAddToCart,
        BNCStandardEventAddToWishlist,
        BNCStandardEventViewCart,
        BNCStandardEventInitiatePurchase,
        BNCStandardEventAddPaymentInfo,
        BNCStandardEventPurchase,
        BNCStandardEventSpendCredits,
        BNCStandardEventSearch,
        BNCStandardEventViewContent,
        BNCStandardEventViewContentList,
        BNCStandardEventRate,
        BNCStandardEventShareContent,
        BNCStandardEventCompleteRegistration,
        BNCStandardEventCompleteTutorial,
        BNCStandardEventAchieveLevel,
        BNCStandardEventUnlockAchievement,
    ];
}

/*
{
	"name": "PURCHASE",
	"custom_data": {
		"Custom_Event_Property_Key1": "Custom_Event_Property_val1",
		"Custom_Event_Property_Key2": "Custom_Event_Property_val2"
	},
	"event_data": {
		"affiliation": "test_affiliation",
		"coupon": "test_coupon",
		"currency": "USD",
		"description": "Event_description",
		"shipping": 10.2,
		"tax": 12.3,
		"revenue": 1.5,
		"transaction_id": "12344555"
	},
	"content_items": [{
			"$quantity": 5,
			"$sku": "1994320302",
			"$product_name": "my_product_name1",
			"$product_brand": "my_prod_Brand1",
			"$product_category": "Baby & Toddler",
			"$product_variant": "my_prod_variant1",
			"$rating_average": 5,
			"$rating_count": 3,
			"$rating_max": 6,
			"$address_street": "Street_name1",
			"$address_region": "Region1",
			"$address_country": "Country1",
			"$latitude": 12.07,
			"$longitude": -97.5,
			"$image_captions": [
				"my_img_caption1",
				"My_img_caption_2"
			],
			"$custom_fields": 
                "{\"Custom_Content_metadata_key2\":\"Custom_Content_metadata_val2\",\"Custom_Content_metadata_key1\":\"Custom_Content_metadata_val1\"}",
			"$og_title": "my_product_title1",
			"$canonical_identifier": "canonicalID\/1234",
			"$og_description": "my_product_description1",
			"$publicly_indexable": false,
			"$locally_indexable": true,
			"$price": 101.2,
			"$creation_timestamp": 1501095677394
		},
		{
			"$product_name": "my_product_name1",
			"$product_brand": "my_prod_Brand1",
			"$product_category": "Baby & Toddler",
			"$product_variant": "my_prod_variant1",
			"$address_street": "Street_name1",
			"$address_region": "Region1",
			"$image_captions": [
				"my_img_caption11",
				"my_img_caption_22"
			],
			"$custom_fields": "{\"Custom_Content_metadata_key11\":\"Custom_Content_metadata_val11\"}",
			"$og_title": "my_product_title2",
			"$canonical_identifier": "canonicalID\/5324",
			"$og_description": "my_product_description2",
			"$publicly_indexable": false,
			"$locally_indexable": true,
			"$price": 80.2,
			"$creation_timestamp": 1501095677394
		}
	],

	"hardware_id": "6773e6ed-4ac5-41b0-9651-efa97da32a24",
	"is_hardware_id_real": false,
	"brand": "LGE",
	"model": "Nexus 5X",
	"screen_dpi": 420,
	"screen_height": 1794,
	"screen_width": 1080,
	"wifi": true,
	"os": "Android",
	"os_version": 25,
	"country": "US",
	"language": "en",
	"local_ip": "192.168.3.209",
	"sdk": "android2.10.3",
	"branch_key": "key_test_hdcBLUy1xZ1JD0tKg7qrLcgirFmPPVJc"
}

*/

- (void) logEventInternal:(NSString*)event
           withProperties:(BNCEventProperties*)properties
             contentItems:(NSArray<BranchUniversalObject*>*)universalObjects {

    if (![event isKindOfClass:[NSString class]] || event.length == 0) {
        BNCLogError(@"Invalid event type '%@' or empty string.", NSStringFromClass(event.class));
        return;
    }

    NSMutableDictionary *eventDictionary = [NSMutableDictionary new];
    eventDictionary[@"name"] = event;

    NSDictionary *propertyDictionary = [properties dictionary];
    if (propertyDictionary.count) {
        eventDictionary[@"event_data"] = propertyDictionary;
    }

    NSMutableArray *contentItemDictionaries = [NSMutableArray new];
    for (BranchUniversalObject *contentItem in universalObjects) {
        NSDictionary *dictionary = [contentItem getParamsForServerRequest];
        if (dictionary.count) {
            [contentItemDictionaries addObject:dictionary];
        }
    }

    if (contentItemDictionaries.count) {
        eventDictionary[@"content_items"] = contentItemDictionaries;
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *serverURL =
        ([self.class.standardEvents containsObject:event])
        ? [preferenceHelper getAPIURL:@"v2/event/standard"]
        : [preferenceHelper getAPIURL:@"v2/event/custom"];


    BranchEventRequest *request =
		[[BranchEventRequest alloc]
			initWithServerURL:[NSURL URLWithString:serverURL]
			eventDictionary:eventDictionary
			completion:nil];
    [self sendServerRequest:request];
}

- (void) logStandardEvent:(BNCStandardEvent)event
           withProperties:(BNCEventProperties*)properties
             contentItems:(NSArray<BranchUniversalObject*>*)universalObjects {
    [self logEventInternal:event withProperties:properties contentItems:universalObjects];
}

- (void) logCustomEvent:(NSString*)event
         withProperties:(BNCEventProperties*)properties
           contentItems:(NSArray<BranchUniversalObject*>*)universalObjects {
    [self logEventInternal:event withProperties:properties contentItems:universalObjects];
}

@end


//
//  BNCCommerceEvent.h
//  BranchSDK-iOS
//
//  Created by Edward Smith on 12/14/16.
//  Copyright (c) 2016 Branch Metrics. All rights reserved.
//


#import "BNCCommerceEvent.h"
#import "BranchConstants.h"


#pragma mark BNCProductCategory

BNCProductCategory BNCProductCategoryAnimalSupplies     = @"Animals & Pet Supplies";
BNCProductCategory BNCProductCategoryApparel            = @"Apparel & Accessories";
BNCProductCategory BNCProductCategoryArtsEntertainment  = @"Arts & Entertainment";
BNCProductCategory BNCProductCategoryBabyToddler        = @"Baby & Toddler";
BNCProductCategory BNCProductCategoryBusinessIndustrial = @"Business & Industrial";
BNCProductCategory BNCProductCategoryCamerasOptics      = @"Cameras & Optics";
BNCProductCategory BNCProductCategoryElectronics        = @"Electronics";
BNCProductCategory BNCProductCategoryFoodBeverageTobacco = @"Food, Beverages & Tobacco";
BNCProductCategory BNCProductCategoryFurniture          = @"Furniture";
BNCProductCategory BNCProductCategoryHardware           = @"Hardware";
BNCProductCategory BNCProductCategoryHealthBeauty       = @"Health & Beauty";
BNCProductCategory BNCProductCategoryHomeGarden         = @"Home & Garden";
BNCProductCategory BNCProductCategoryLuggageBags        = @"Luggage & Bags";
BNCProductCategory BNCProductCategoryMature             = @"Mature";
BNCProductCategory BNCProductCategoryMedia              = @"Media";
BNCProductCategory BNCProductCategoryOfficeSupplies     = @"Office Supplies";
BNCProductCategory BNCProductCategoryReligious          = @"Religious & Ceremonial";
BNCProductCategory BNCProductCategorySoftware           = @"Software";
BNCProductCategory BNCProductCategorySportingGoods      = @"Sporting Goods";
BNCProductCategory BNCProductCategoryToysGames          = @"Toys & Games";
BNCProductCategory BNCProductCategoryVehiclesParts      = @"Vehicles & Parts";

#pragma mark - BNCProduct

@implementation BNCProduct

- (NSMutableDictionary*) dictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

	#define assign(x) \
		do { if (self.x) { dictionary[@#x] = self.x; } } while (0)

	assign(sku);
	assign(name);
	assign(price);
	assign(quantity);
	assign(brand);
	assign(category);
	assign(variant);

	#undef assign

	return dictionary;
}

- (NSString*) description {
    return [NSString stringWithFormat:
        @"Name: %@ Sku: %@ Price: %@ Quantity: %@ Brand: %@ Category: %@ Variant: %@",
        self.name,
        self.sku,
        self.price,
        self.quantity,
        self.brand,
        self.category,
        self.variant];
}

@end

#pragma mark - BNCCommerceEvent

@implementation BNCCommerceEvent : NSObject

- (NSDictionary*) dictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

	#define assign(x) \
		do { if (self.x) { dictionary[@#x] = self.x; } } while (0)

	assign(revenue);
	assign(currency);
    if (self.transactionID) {
        dictionary[@"transaction_id"] = self.transactionID;
    }
	assign(shipping);
	assign(tax);
	assign(coupon);
	assign(affiliation);

	NSMutableArray *products = [NSMutableArray arrayWithCapacity:self.products.count];
	for (BNCProduct *product in self.products) {
		NSDictionary * d = [product dictionary];
		if (d) [products addObject:d];
	}
    dictionary[@"products"] = products;
	
	#undef assign
	
	return dictionary;
}

- (NSString*) description {
    return [NSString stringWithFormat:
        @"Revenue: %@ Currency: %@ TxID: %@ Shipping: %@ Tax: %@ Coupon: %@ Affl: %@ Products: %lu",
        self.revenue,
        self.currency,
        self.transactionID,
        self.shipping,
        self.tax,
        self.coupon,
        self.affiliation,
        (unsigned long) self.products.count];
}

@end


#pragma mark - BranchCommerceEventRequest


@interface BranchCommerceEventRequest ()
@property (strong) NSDictionary *commerceDictionary;
@property (strong) NSDictionary *metadata;
@property (copy)   void (^completion)(NSDictionary* response, NSError* error);
@end


@implementation BranchCommerceEventRequest

- (instancetype) initWithCommerceEvent:(BNCCommerceEvent*)commerceEvent
							  metadata:(NSDictionary*)metadata
							completion:(void (^)(NSDictionary* response, NSError* error))completion {
	self = [super init];
	if (!self) return self;

    if ([commerceEvent.revenue isEqualToNumber:[NSDecimalNumber numberWithDouble:0.0]]) {
        NSLog(@"[Branch] Warning: Sending a commerce event with zero value!!");
    }

	self.commerceDictionary = [commerceEvent dictionary];
	self.metadata = metadata;
	self.completion = completion;
	return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface
			    key:(NSString *)key callback:(BNCServerCallback)callback {

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[BRANCH_REQUEST_KEY_ACTION] = @"purchase";
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

	if (self.metadata)
		params[@"metadata"] = self.metadata;
	if (self.commerceDictionary)
		params[@"commerce_data"] = self.commerceDictionary;

	NSString *URL = [preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_USER_COMPLETED_ACTION];
    [serverInterface postRequest:params
							 url:URL
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


#pragma mark BranchCommerceEventRequest NSCoding


- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (!self) return self;

	self.commerceDictionary = [decoder decodeObjectForKey:@"commerceDictionary"];
	self.metadata = [decoder decodeObjectForKey:@"metaData"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.commerceDictionary forKey:@"commerceDictionary"];
    [coder encodeObject:self.metadata forKey:@"metadata"];
}

@end

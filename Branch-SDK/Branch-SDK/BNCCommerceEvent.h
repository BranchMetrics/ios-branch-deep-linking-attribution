//
//  BNCCommerceEvent.h
//  BranchSDK-iOS
//
//  Created by Edward Smith on 12/14/16.
//  Copyright (c) 2016 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BNCServerRequest.h"


#pragma mark BNCProductCategory

typedef NSString*const BNCProductCategory;

extern BNCProductCategory BNCProductCategoryAnimalSupplies;
extern BNCProductCategory BNCProductCategoryApparel;
extern BNCProductCategory BNCProductCategoryArtsEntertainment;
extern BNCProductCategory BNCProductCategoryBabyToddler;
extern BNCProductCategory BNCProductCategoryBusinessIndustrial;
extern BNCProductCategory BNCProductCategoryCamerasOptics;
extern BNCProductCategory BNCProductCategoryElectronics;
extern BNCProductCategory BNCProductCategoryFoodBeverageTobacco;
extern BNCProductCategory BNCProductCategoryFurniture;
extern BNCProductCategory BNCProductCategoryHardware;
extern BNCProductCategory BNCProductCategoryHealthBeauty;
extern BNCProductCategory BNCProductCategoryHomeGarden;
extern BNCProductCategory BNCProductCategoryLuggageBags;
extern BNCProductCategory BNCProductCategoryMature;
extern BNCProductCategory BNCProductCategoryMedia;
extern BNCProductCategory BNCProductCategoryOfficeSupplies;
extern BNCProductCategory BNCProductCategoryReligious;
extern BNCProductCategory BNCProductCategorySoftware;
extern BNCProductCategory BNCProductCategorySportingGoods;
extern BNCProductCategory BNCProductCategoryToysGames;
extern BNCProductCategory BNCProductCategoryVehiclesParts;

#pragma mark - BNCProduct

@interface BNCProduct : NSObject
@property (nonatomic, strong) NSString *sku;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, strong) NSNumber *quantity;
@property (nonatomic, strong) NSString *brand;
@property (nonatomic, strong) BNCProductCategory category;
@property (nonatomic, strong) NSString *variant;
@end

#pragma mark - BNCCommerceEvent

@interface BNCCommerceEvent : NSObject
@property (nonatomic, strong) NSDecimalNumber *revenue;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *transactionID;
@property (nonatomic, strong) NSDecimalNumber *shipping;
@property (nonatomic, strong) NSDecimalNumber *tax;
@property (nonatomic, strong) NSString *coupon;
@property (nonatomic, strong) NSString *affiliation;
@property (nonatomic, strong) NSArray<BNCProduct*> *products;
@end


@interface BranchCommerceEventRequest : BNCServerRequest <NSCoding>

- (instancetype) initWithCommerceEvent:(BNCCommerceEvent*)commerceEvent
							  metadata:(NSDictionary*)dictionary
							completion:(void (^)(NSDictionary* response, NSError* error))callBack;

@end

//
//  BNCProductCategory.h
//  Branch
//
//  Created by Nipun Singh on 8/14/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString * const BNCProductCategory NS_STRING_ENUM;

FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryAnimalSupplies;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryApparel;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryArtsEntertainment;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryBabyToddler;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryBusinessIndustrial;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryCamerasOptics;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryElectronics;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryFoodBeverageTobacco;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryFurniture;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryHardware;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryHealthBeauty;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryHomeGarden;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryLuggageBags;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryMature;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryMedia;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryOfficeSupplies;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryReligious;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategorySoftware;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategorySportingGoods;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryToysGames;
FOUNDATION_EXPORT  BNCProductCategory _Nonnull BNCProductCategoryVehiclesParts;

NSArray<BNCProductCategory>*_Nonnull BNCProductCategoryAllCategories(void);

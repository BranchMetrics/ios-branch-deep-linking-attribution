//
//  BNCProductCategory.m
//  Branch
//
//  Created by Nipun Singh on 8/14/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import "BNCProductCategory.h"

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

NSArray<BNCProductCategory>* BNCProductCategoryAllCategories(void) {
    return @[
        BNCProductCategoryAnimalSupplies,
        BNCProductCategoryApparel,
        BNCProductCategoryArtsEntertainment,
        BNCProductCategoryBabyToddler,
        BNCProductCategoryBusinessIndustrial,
        BNCProductCategoryCamerasOptics,
        BNCProductCategoryElectronics,
        BNCProductCategoryFoodBeverageTobacco,
        BNCProductCategoryFurniture,
        BNCProductCategoryHardware,
        BNCProductCategoryHealthBeauty,
        BNCProductCategoryHomeGarden,
        BNCProductCategoryLuggageBags,
        BNCProductCategoryMature,
        BNCProductCategoryMedia,
        BNCProductCategoryOfficeSupplies,
        BNCProductCategoryReligious,
        BNCProductCategorySoftware,
        BNCProductCategorySportingGoods,
        BNCProductCategoryToysGames,
        BNCProductCategoryVehiclesParts,
    ];
}

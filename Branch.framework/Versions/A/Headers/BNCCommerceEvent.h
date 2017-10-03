//
//  BNCCommerceEvent.h
//  BranchSDK-iOS
//
//  Created by Edward Smith on 12/14/16.
//  Copyright (c) 2016 Branch Metrics. All rights reserved.
//


@import Foundation;
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

#pragma mark - BNCCurrency

typedef NSString*const BNCCurrency;

extern BNCCurrency BNCCurrencyAED;
extern BNCCurrency BNCCurrencyAFN;
extern BNCCurrency BNCCurrencyALL;
extern BNCCurrency BNCCurrencyAMD;
extern BNCCurrency BNCCurrencyANG;
extern BNCCurrency BNCCurrencyAOA;
extern BNCCurrency BNCCurrencyARS;
extern BNCCurrency BNCCurrencyAUD;
extern BNCCurrency BNCCurrencyAWG;
extern BNCCurrency BNCCurrencyAZN;
extern BNCCurrency BNCCurrencyBAM;
extern BNCCurrency BNCCurrencyBBD;

extern BNCCurrency BNCCurrencyBDT;
extern BNCCurrency BNCCurrencyBGN;
extern BNCCurrency BNCCurrencyBHD;
extern BNCCurrency BNCCurrencyBIF;
extern BNCCurrency BNCCurrencyBMD;
extern BNCCurrency BNCCurrencyBND;
extern BNCCurrency BNCCurrencyBOB;
extern BNCCurrency BNCCurrencyBOV;
extern BNCCurrency BNCCurrencyBRL;
extern BNCCurrency BNCCurrencyBSD;
extern BNCCurrency BNCCurrencyBTN;
extern BNCCurrency BNCCurrencyBWP;

extern BNCCurrency BNCCurrencyBYN;
extern BNCCurrency BNCCurrencyBYR;
extern BNCCurrency BNCCurrencyBZD;
extern BNCCurrency BNCCurrencyCAD;
extern BNCCurrency BNCCurrencyCDF;
extern BNCCurrency BNCCurrencyCHE;
extern BNCCurrency BNCCurrencyCHF;
extern BNCCurrency BNCCurrencyCHW;
extern BNCCurrency BNCCurrencyCLF;
extern BNCCurrency BNCCurrencyCLP;
extern BNCCurrency BNCCurrencyCNY;
extern BNCCurrency BNCCurrencyCOP;

extern BNCCurrency BNCCurrencyCOU;
extern BNCCurrency BNCCurrencyCRC;
extern BNCCurrency BNCCurrencyCUC;
extern BNCCurrency BNCCurrencyCUP;
extern BNCCurrency BNCCurrencyCVE;
extern BNCCurrency BNCCurrencyCZK;
extern BNCCurrency BNCCurrencyDJF;
extern BNCCurrency BNCCurrencyDKK;
extern BNCCurrency BNCCurrencyDOP;
extern BNCCurrency BNCCurrencyDZD;
extern BNCCurrency BNCCurrencyEGP;
extern BNCCurrency BNCCurrencyERN;

extern BNCCurrency BNCCurrencyETB;
extern BNCCurrency BNCCurrencyEUR;
extern BNCCurrency BNCCurrencyFJD;
extern BNCCurrency BNCCurrencyFKP;
extern BNCCurrency BNCCurrencyGBP;
extern BNCCurrency BNCCurrencyGEL;
extern BNCCurrency BNCCurrencyGHS;
extern BNCCurrency BNCCurrencyGIP;
extern BNCCurrency BNCCurrencyGMD;
extern BNCCurrency BNCCurrencyGNF;
extern BNCCurrency BNCCurrencyGTQ;
extern BNCCurrency BNCCurrencyGYD;

extern BNCCurrency BNCCurrencyHKD;
extern BNCCurrency BNCCurrencyHNL;
extern BNCCurrency BNCCurrencyHRK;
extern BNCCurrency BNCCurrencyHTG;
extern BNCCurrency BNCCurrencyHUF;
extern BNCCurrency BNCCurrencyIDR;
extern BNCCurrency BNCCurrencyILS;
extern BNCCurrency BNCCurrencyINR;
extern BNCCurrency BNCCurrencyIQD;
extern BNCCurrency BNCCurrencyIRR;
extern BNCCurrency BNCCurrencyISK;
extern BNCCurrency BNCCurrencyJMD;

extern BNCCurrency BNCCurrencyJOD;
extern BNCCurrency BNCCurrencyJPY;
extern BNCCurrency BNCCurrencyKES;
extern BNCCurrency BNCCurrencyKGS;
extern BNCCurrency BNCCurrencyKHR;
extern BNCCurrency BNCCurrencyKMF;
extern BNCCurrency BNCCurrencyKPW;
extern BNCCurrency BNCCurrencyKRW;
extern BNCCurrency BNCCurrencyKWD;
extern BNCCurrency BNCCurrencyKYD;
extern BNCCurrency BNCCurrencyKZT;
extern BNCCurrency BNCCurrencyLAK;

extern BNCCurrency BNCCurrencyLBP;
extern BNCCurrency BNCCurrencyLKR;
extern BNCCurrency BNCCurrencyLRD;
extern BNCCurrency BNCCurrencyLSL;
extern BNCCurrency BNCCurrencyLYD;
extern BNCCurrency BNCCurrencyMAD;
extern BNCCurrency BNCCurrencyMDL;
extern BNCCurrency BNCCurrencyMGA;
extern BNCCurrency BNCCurrencyMKD;
extern BNCCurrency BNCCurrencyMMK;
extern BNCCurrency BNCCurrencyMNT;
extern BNCCurrency BNCCurrencyMOP;

extern BNCCurrency BNCCurrencyMRO;
extern BNCCurrency BNCCurrencyMUR;
extern BNCCurrency BNCCurrencyMVR;
extern BNCCurrency BNCCurrencyMWK;
extern BNCCurrency BNCCurrencyMXN;
extern BNCCurrency BNCCurrencyMXV;
extern BNCCurrency BNCCurrencyMYR;
extern BNCCurrency BNCCurrencyMZN;
extern BNCCurrency BNCCurrencyNAD;
extern BNCCurrency BNCCurrencyNGN;
extern BNCCurrency BNCCurrencyNIO;
extern BNCCurrency BNCCurrencyNOK;

extern BNCCurrency BNCCurrencyNPR;
extern BNCCurrency BNCCurrencyNZD;
extern BNCCurrency BNCCurrencyOMR;
extern BNCCurrency BNCCurrencyPAB;
extern BNCCurrency BNCCurrencyPEN;
extern BNCCurrency BNCCurrencyPGK;
extern BNCCurrency BNCCurrencyPHP;
extern BNCCurrency BNCCurrencyPKR;
extern BNCCurrency BNCCurrencyPLN;
extern BNCCurrency BNCCurrencyPYG;
extern BNCCurrency BNCCurrencyQAR;
extern BNCCurrency BNCCurrencyRON;

extern BNCCurrency BNCCurrencyRSD;
extern BNCCurrency BNCCurrencyRUB;
extern BNCCurrency BNCCurrencyRWF;
extern BNCCurrency BNCCurrencySAR;
extern BNCCurrency BNCCurrencySBD;
extern BNCCurrency BNCCurrencySCR;
extern BNCCurrency BNCCurrencySDG;
extern BNCCurrency BNCCurrencySEK;
extern BNCCurrency BNCCurrencySGD;
extern BNCCurrency BNCCurrencySHP;
extern BNCCurrency BNCCurrencySLL;
extern BNCCurrency BNCCurrencySOS;

extern BNCCurrency BNCCurrencySRD;
extern BNCCurrency BNCCurrencySSP;
extern BNCCurrency BNCCurrencySTD;
extern BNCCurrency BNCCurrencySYP;
extern BNCCurrency BNCCurrencySZL;
extern BNCCurrency BNCCurrencyTHB;
extern BNCCurrency BNCCurrencyTJS;
extern BNCCurrency BNCCurrencyTMT;
extern BNCCurrency BNCCurrencyTND;
extern BNCCurrency BNCCurrencyTOP;
extern BNCCurrency BNCCurrencyTRY;
extern BNCCurrency BNCCurrencyTTD;

extern BNCCurrency BNCCurrencyTWD;
extern BNCCurrency BNCCurrencyTZS;
extern BNCCurrency BNCCurrencyUAH;
extern BNCCurrency BNCCurrencyUGX;
extern BNCCurrency BNCCurrencyUSD;
extern BNCCurrency BNCCurrencyUSN;
extern BNCCurrency BNCCurrencyUYI;
extern BNCCurrency BNCCurrencyUYU;
extern BNCCurrency BNCCurrencyUZS;
extern BNCCurrency BNCCurrencyVEF;
extern BNCCurrency BNCCurrencyVND;
extern BNCCurrency BNCCurrencyVUV;

extern BNCCurrency BNCCurrencyWST;
extern BNCCurrency BNCCurrencyXAF;
extern BNCCurrency BNCCurrencyXAG;
extern BNCCurrency BNCCurrencyXAU;
extern BNCCurrency BNCCurrencyXBA;
extern BNCCurrency BNCCurrencyXBB;
extern BNCCurrency BNCCurrencyXBC;
extern BNCCurrency BNCCurrencyXBD;
extern BNCCurrency BNCCurrencyXCD;
extern BNCCurrency BNCCurrencyXDR;
extern BNCCurrency BNCCurrencyXFU;
extern BNCCurrency BNCCurrencyXOF;

extern BNCCurrency BNCCurrencyXPD;
extern BNCCurrency BNCCurrencyXPF;
extern BNCCurrency BNCCurrencyXPT;
extern BNCCurrency BNCCurrencyXSU;
extern BNCCurrency BNCCurrencyXTS;
extern BNCCurrency BNCCurrencyXUA;
extern BNCCurrency BNCCurrencyXXX;
extern BNCCurrency BNCCurrencyYER;
extern BNCCurrency BNCCurrencyZAR;
extern BNCCurrency BNCCurrencyZMW;

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
@property (nonatomic, strong) BNCCurrency currency;
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

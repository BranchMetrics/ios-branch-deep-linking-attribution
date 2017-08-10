//
//  BNCEvent.h
//  Branch-TestBed
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Branch.h"
#import "BNCCommerceEvent.h"

///@functiongroup Branch Event Logging

typedef NSString*const BNCStandardEvent;

// Commerce Events

extern BNCStandardEvent BNCStandardEventAddToCart;
extern BNCStandardEvent BNCStandardEventAddToWishlist;
extern BNCStandardEvent BNCStandardEventViewCart;
extern BNCStandardEvent BNCStandardEventInitiatePurchase;
extern BNCStandardEvent BNCStandardEventAddPaymentInfo;
extern BNCStandardEvent BNCStandardEventPurchase;
extern BNCStandardEvent BNCStandardEventSpendCredits;

// Content Events

extern BNCStandardEvent BNCStandardEventSearch;
extern BNCStandardEvent BNCStandardEventViewContent;
extern BNCStandardEvent BNCStandardEventViewContentList;
extern BNCStandardEvent BNCStandardEventRate;
extern BNCStandardEvent BNCStandardEventShareContent;

// User Lifecycle Events

extern BNCStandardEvent BNCStandardEventCompleteRegistration;
extern BNCStandardEvent BNCStandardEventCompleteTutorial;
extern BNCStandardEvent BNCStandardEventAchieveLevel;
extern BNCStandardEvent BNCStandardEventUnlockAchievement;

// Event properties

@interface BNCEventProperties : NSObject
@property (nonatomic, strong) NSString *transactionID;
@property (nonatomic, strong) BNCCurrency currency;
@property (nonatomic, strong) NSDecimalNumber *revenue;
@property (nonatomic, strong) NSDecimalNumber *shipping;
@property (nonatomic, strong) NSDecimalNumber *tax;
@property (nonatomic, strong) NSString *coupon;
@property (nonatomic, strong) NSString *affiliation;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) NSDictionary<NSString*, id<NSObject>> *customData;
@end


// Extend the Branch class for standard events

@interface Branch (BNCStandardEvents)

- (void) logStandardEvent:(BNCStandardEvent)event
           withProperties:(BNCEventProperties*)properties
             contentItems:(NSArray<BranchUniversalObject*>*)universalObjects;

- (void) logCustomEvent:(NSString*)eventName
         withProperties:(BNCEventProperties*)properties
           contentItems:(NSArray<BranchUniversalObject*>*)universalObjects;

@end

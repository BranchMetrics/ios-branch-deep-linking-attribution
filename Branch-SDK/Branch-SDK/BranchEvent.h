//
//  BranchEvent.h
//  Branch-SDK
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Branch.h"
#import "BNCCommerceEvent.h"
#import "BranchUniversalObject.h"

///@functiongroup Branch Event Logging

typedef NSString*const BranchStandardEvent;

// Commerce Events

extern BranchStandardEvent BranchStandardEventAddToCart;
extern BranchStandardEvent BranchStandardEventAddToWishlist;
extern BranchStandardEvent BranchStandardEventViewCart;
extern BranchStandardEvent BranchStandardEventInitiatePurchase;
extern BranchStandardEvent BranchStandardEventAddPaymentInfo;
extern BranchStandardEvent BranchStandardEventPurchase;
extern BranchStandardEvent BranchStandardEventSpendCredits;

// Content Events

extern BranchStandardEvent BranchStandardEventSearch;
extern BranchStandardEvent BranchStandardEventViewContent;
extern BranchStandardEvent BranchStandardEventViewContentList;
extern BranchStandardEvent BranchStandardEventRate;
extern BranchStandardEvent BranchStandardEventShareContent; // TODO: Share start/complete/cancel?

// User Lifecycle Events

extern BranchStandardEvent BranchStandardEventCompleteRegistration;
extern BranchStandardEvent BranchStandardEventCompleteTutorial;
extern BranchStandardEvent BranchStandardEventAchieveLevel;
extern BranchStandardEvent BranchStandardEventUnlockAchievement;

#pragma mark - BranchEvent

@interface BranchEvent : NSObject

- (instancetype) initWithName:(NSString*)name NS_DESIGNATED_INITIALIZER;

+ (instancetype) standardEventWithType:(BranchStandardEvent)standardEvent;
+ (instancetype) standardEventWithType:(BranchStandardEvent)standardEvent contentItem:(BranchUniversalObject*)contentItem;

+ (instancetype) customEventWithName:(NSString*)name;
+ (instancetype) customEventWithName:(NSString*)name contentItem:(BranchUniversalObject*)contentItem;

- (instancetype) init __attribute((unavailable));
+ (instancetype) new __attribute((unavailable));

@property (nonatomic, strong) NSString              *transactionID;
@property (nonatomic, strong) BNCCurrency           currency;
@property (nonatomic, strong) NSDecimalNumber       *revenue;
@property (nonatomic, strong) NSDecimalNumber       *shipping;
@property (nonatomic, strong) NSDecimalNumber       *tax;
@property (nonatomic, strong) NSString              *coupon;
@property (nonatomic, strong) NSString              *affiliation;
@property (nonatomic, strong) NSString              *eventDescription;
@property (nonatomic, strong) BNCProductCondition   productCondition;
@property (nonatomic, strong) NSArray<BranchUniversalObject*> *contentItems;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *userInfo;

- (void) logEvent;              //!> Logs the event on the Branch server.
- (NSDictionary*) dictionary;   //!> Returns a dictionary representation of the event.
@end

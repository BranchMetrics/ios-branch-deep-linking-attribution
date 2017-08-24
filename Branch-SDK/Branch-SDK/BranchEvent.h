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

extern BranchStandardEvent _Nonnull BranchStandardEventAddToCart;
extern BranchStandardEvent _Nonnull BranchStandardEventAddToWishlist;
extern BranchStandardEvent _Nonnull BranchStandardEventViewCart;
extern BranchStandardEvent _Nonnull BranchStandardEventInitiatePurchase;
extern BranchStandardEvent _Nonnull BranchStandardEventAddPaymentInfo;
extern BranchStandardEvent _Nonnull BranchStandardEventPurchase;
extern BranchStandardEvent _Nonnull BranchStandardEventSpendCredits;

// Content Events

extern BranchStandardEvent _Nonnull BranchStandardEventSearch;
extern BranchStandardEvent _Nonnull BranchStandardEventViewContent;
extern BranchStandardEvent _Nonnull BranchStandardEventViewContentList;
extern BranchStandardEvent _Nonnull BranchStandardEventRate;
extern BranchStandardEvent _Nonnull BranchStandardEventShareContent; // TODO: Share start/complete/cancel?

// User Lifecycle Events

extern BranchStandardEvent _Nonnull BranchStandardEventCompleteRegistration;
extern BranchStandardEvent _Nonnull BranchStandardEventCompleteTutorial;
extern BranchStandardEvent _Nonnull BranchStandardEventAchieveLevel;
extern BranchStandardEvent _Nonnull BranchStandardEventUnlockAchievement;

#pragma mark - BranchEvent

@interface BranchEvent : NSObject

- (instancetype _Nonnull) initWithName:(NSString*_Nonnull)name NS_DESIGNATED_INITIALIZER;

+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent;
+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent
                        withContentItem:(BranchUniversalObject* _Nonnull)contentItem;

+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name;
+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name
                                  contentItem:(BranchUniversalObject*_Nonnull)contentItem;

- (instancetype _Nonnull) init __attribute((unavailable));
+ (instancetype _Nonnull) new __attribute((unavailable));

@property (nonatomic, strong) NSString*_Nullable                transactionID;
@property (nonatomic, strong) BNCCurrency _Nullable             currency;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         revenue;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         shipping;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         tax;
@property (nonatomic, strong) NSString*_Nullable                coupon;
@property (nonatomic, strong) NSString*_Nullable                affiliation;
@property (nonatomic, strong) NSString*_Nullable                eventDescription;
@property (nonatomic, strong) BranchProductCondition _Nullable          productCondition;
@property (nonatomic, strong) NSArray<BranchUniversalObject*>*_Nullable contentItems;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *_Nullable userInfo;

- (void) logEvent;                      //!> Logs the event on the Branch server.
- (NSDictionary*_Nonnull) dictionary;   //!> Returns a dictionary representation of the event.
@end

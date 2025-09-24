//
//  BranchEvent.h
//  Branch-SDK
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchUniversalObject.h"
#import <StoreKit/StoreKit.h>

///@group Branch Event Logging

typedef NSString*const BranchStandardEvent NS_STRING_ENUM;

///@name Commerce Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddToCart;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddToWishlist;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewCart;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventInitiatePurchase;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAddPaymentInfo;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventPurchase;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSpendCredits;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSubscribe;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventStartTrial;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventClickAd;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewAd;

///@name Content Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventSearch;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewItem;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventViewItems;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventRate;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventShare;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventInitiateStream;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventCompleteStream;

///@name User Lifecycle Events

FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventCompleteRegistration;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventCompleteTutorial;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventAchieveLevel;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventUnlockAchievement;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventInvite;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventLogin;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull BranchStandardEventReserve;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull  BranchStandardEventOptIn;
FOUNDATION_EXPORT BranchStandardEvent _Nonnull  BranchStandardEventOptOut;

typedef NS_ENUM(NSInteger, BranchEventAdType) {
    BranchEventAdTypeNone,
    BranchEventAdTypeBanner,
    BranchEventAdTypeInterstitial,
    BranchEventAdTypeRewardedVideo,
    BranchEventAdTypeNative
};

#pragma mark - BranchEvent


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface BranchEvent : NSObject <SKProductsRequestDelegate>

- (instancetype _Nonnull) initWithName:(NSString*_Nonnull)name NS_DESIGNATED_INITIALIZER;

+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent;
+ (instancetype _Nonnull) standardEvent:(BranchStandardEvent _Nonnull)standardEvent
                        withContentItem:(BranchUniversalObject* _Nonnull)contentItem;

+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name;
+ (instancetype _Nonnull) customEventWithName:(NSString*_Nonnull)name
                                  contentItem:(BranchUniversalObject*_Nonnull)contentItem;

- (instancetype _Nonnull) init __attribute((unavailable));
+ (instancetype _Nonnull) new __attribute((unavailable));

@property (nonatomic, copy) NSString*_Nullable                alias;
@property (nonatomic, copy) NSString*_Nullable                transactionID;
@property (nonatomic, copy) BNCCurrency _Nullable             currency;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         revenue;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         shipping;
@property (nonatomic, strong) NSDecimalNumber*_Nullable         tax;
@property (nonatomic, copy) NSString*_Nullable                coupon;
@property (nonatomic, copy) NSString*_Nullable                affiliation;
@property (nonatomic, copy) NSString*_Nullable                eventDescription;
@property (nonatomic, copy) NSString*_Nullable                searchQuery;

@property (nonatomic, assign) BranchEventAdType                 adType;

@property (nonatomic, strong) NSArray<BranchUniversalObject*>*_Nonnull       contentItems;
@property (nonatomic, strong) NSDictionary<NSString*, NSString*> *_Nonnull   customData;

/**
 Logs the event on the Branch server.
 This version will callback on success/failure.
  
 This method should only be invoked after initSession.
 If it is invoked before, then we will silently initialize the SDK before the callback has been set, in order to carry out this method's required task.
 As a result, you may experience issues where the initSession callback does not fire. Again, the solution to this issue is to only invoke this method after you have invoked initSession.
 */
- (void)logEventWithCompletion:(void (^_Nullable)(BOOL success, NSError * _Nullable error))completion;

/**
 Logs the event on the Branch server.
 This version automatically caches and retries as necessary.
 
 This method should only be invoked after initSession.
 If it is invoked before, then we will silently initialize the SDK before the callback has been set, in order to carry out this method's required task.
 As a result, you may experience issues where the initSession callback does not fire. Again, the solution to this issue is to only invoke this method after you have invoked initSession.
 */
- (void)logEvent;

- (NSDictionary*_Nonnull) dictionary;   //!< Returns a dictionary representation of the event.
- (NSString* _Nonnull) description;     //!< Returns a string description of the event.

- (void) logEventWithTransaction:(SKPaymentTransaction*_Nonnull)transaction;

@end

#pragma clang diagnostic pop

#pragma mark - BranchEventRequest

@interface BranchEventRequest : BNCServerRequest <NSSecureCoding>

- (instancetype _Nonnull) initWithServerURL:(NSURL*_Nonnull)serverURL
                   eventDictionary:(NSDictionary*_Nullable)eventDictionary
                        completion:(void (^_Nullable)(NSDictionary*_Nullable response, NSError*_Nullable error))completion;

@property (nonatomic, strong) NSDictionary*_Nullable eventDictionary;
@property (nonatomic, strong) NSURL*_Nullable serverURL;
@property (nonatomic, copy)   void (^_Nullable completion)(NSDictionary*_Nullable response, NSError*_Nullable error);
@end

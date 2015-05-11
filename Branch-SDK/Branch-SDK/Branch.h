//
//  Branch_SDK.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BranchActivityItemProvider.h"
#import "BNCLinkCache.h"

/**
 `Branch` is the primary interface of the Branch iOS SDK. Currently, all interactions you will make are funneled through this class. It is not meant to be instantiated or subclassed, usage should be limited to the global instance.

  Note, when `getInstance` is called, it assumes that you have already placed a Branch Key in your main `Info.plist` file for your project. For additional information on configuring the Branch SDK, check out the getting started guides in the Readme.
 */

typedef void (^callbackWithParams) (NSDictionary *params, NSError *error);
typedef void (^callbackWithUrl) (NSString *url, NSError *error);
typedef void (^callbackWithStatus) (BOOL changed, NSError *error);
typedef void (^callbackWithList) (NSArray *list, NSError *error);

extern NSString * const BRANCH_FEATURE_TAG_SHARE;
extern NSString * const BRANCH_FEATURE_TAG_REFERRAL;
extern NSString * const BRANCH_FEATURE_TAG_INVITE;
extern NSString * const BRANCH_FEATURE_TAG_DEAL;
extern NSString * const BRANCH_FEATURE_TAG_GIFT;

typedef NS_ENUM(NSUInteger, BranchCreditHistoryOrder) {
    BranchMostRecentFirst,
    BranchLeastRecentFirst
};

typedef NS_ENUM(NSUInteger, BranchReferralCodeLocation) {
    BranchReferreeUser = 0,
    BranchReferringUser = 2,
    BranchBothUsers = 3
};

typedef NS_ENUM(NSUInteger, BranchReferralCodeCalculation) {
    BranchUniqueRewards = 1,
    BranchUnlimitedRewards = 0
};

@interface Branch : NSObject

///--------------------------------
/// @name Global Instance Accessors
///--------------------------------

/**
 Gets the global, live Branch instance.
 */
+ (Branch *)getInstance;

/**
 Gets the global, test Branch instance.

 @warning This method is not meant to be used in production! 
 */
+ (Branch *)getTestInstance;

/**
 Gets the global Branch instance, configures using the specified key

 @param branchKey The Branch key to be used by the Branch instance. This can be any live or test key.
 @warning This method is not the recommended way of using Branch. Try using your project's `Info.plist` if possible.
 */
+ (Branch *)getInstance:(NSString *)branchKey;

///-----------------------------------------
/// @name BranchActivityItemProvider methods
///-----------------------------------------

/**
 
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

///---------------------
/// @name Initialization
///---------------------

- (void)initSession;
- (void)initSessionWithLaunchOptions:(NSDictionary *)options;
- (void)initSession:(BOOL)isReferrable;
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable;
- (void)initSessionAndRegisterDeepLinkHandler:(callbackWithParams)callback;
- (void)initSessionWithLaunchOptions:(NSDictionary *)options andRegisterDeepLinkHandler:(callbackWithParams)callback;
- (void)initSession:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback;
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback;
- (BOOL)handleDeepLink:(NSURL *)url;

///--------------------
/// @name Configuration
///--------------------

+ (void)setDebug;
- (void)setRetryInterval:(NSInteger)retryInterval;
- (void)setMaxRetries:(NSInteger)maxRetries;
- (void)setNetworkTimeout:(NSInteger)timeout;
- (void)setAppListCheckEnabled:(BOOL)appListCheckEnabled;

///--------------------
/// @name Session Items
///--------------------

- (NSDictionary *)getFirstReferringParams;
- (NSDictionary *)getLatestReferringParams;
- (void)resetUserSession;
- (void)setIdentity:(NSString *)userId;
- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback;
- (void)logout;

///--------------
/// @name Credits
///--------------

- (void)loadRewardsWithCallback:(callbackWithStatus)callback;
- (void)redeemRewards:(NSInteger)count;
- (void)redeemRewards:(NSInteger)count callback:(callbackWithStatus)callback;
- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket;
- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket callback:(callbackWithStatus)callback;
- (NSInteger)getCredits;
- (NSInteger)getCreditsForBucket:(NSString *)bucket;
- (void)getCreditHistoryWithCallback:(callbackWithList)callback;
- (void)getCreditHistoryForBucket:(NSString *)bucket andCallback:(callbackWithList)callback;
- (void)getCreditHistoryAfter:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback;
- (void)getCreditHistoryForBucket:(NSString *)bucket after:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback;

///--------------
/// @name Actions
///--------------

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback;
- (void)userCompletedAction:(NSString *)action;
- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state;
- (NSInteger)getTotalCountsForAction:(NSString *)action;
- (NSInteger)getUniqueCountsForAction:(NSString *)action;

///---------------------------------------
/// @name Synchronous Short Url Generation
///---------------------------------------

- (NSString *)getShortURL;
- (NSString *)getShortURLWithParams:(NSDictionary *)params;
- (NSString *)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel;
- (NSString *)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel;
- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel;
- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration;
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature;

///--------------------------
/// @name Long Url generation
///--------------------------

- (NSString *)getLongURLWithParams:(NSDictionary *)params;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

///----------------------------------------
/// @name Asynchronous Short Url Generation
///----------------------------------------

- (void)getShortURLWithCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback;
- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback;
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback;

///---------------------------------------
/// @name Referral code methods
///---------------------------------------

- (void)getReferralCodeWithCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket calculationType:(BranchReferralCodeCalculation)calcType location:(BranchReferralCodeLocation)location andCallback:(callbackWithParams)callback;
- (void)validateReferralCode:(NSString *)code andCallback:(callbackWithParams)callback;
- (void)applyReferralCode:(NSString *)code andCallback:(callbackWithParams)callback;

@end

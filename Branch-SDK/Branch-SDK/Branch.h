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

#pragma mark - Global Instance Accessors

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

#pragma mark - BranchActivityItemProvider methods

///-----------------------------------------
/// @name BranchActivityItemProvider methods
///-----------------------------------------

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 @param feature The feature the generated link will be associated with
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 @param feature The feature the generated link will be associated with
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 @param feature The feature the generated link will be associated with
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in
 @param tags An array of tag strings to be associated with the link
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 @param feature The feature the generated link will be associated with
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in
 @param alias The alias for a link. This will have a two character suffix appended to it.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link
 @param tags An array of tag strings to be associated with the link
 @param feature The feature the generated link will be associated with
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in
 @param alias The alias for a link. This will have a two character suffix appended to it.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

#pragma mark - Initialization methods

///---------------------
/// @name Initialization
///---------------------

/**
 Just initialize the Branch session.
 
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info, and any ability to do anything with the callback.
 */
- (void)initSession;

/**
 Just initialize the Branch session with the app launch options.
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @warning This is not the recommended method of initializing Branch. While Branch is able to properly attribute deep linking info with the launch options, you lose the ability to do anything with a callback.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options;

/**
 Just initialize the Branch session, specifying whether to allow it to be treated as a referral.
 
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info, and any ability to do anything with the callback.
 */
- (void)initSession:(BOOL)isReferrable;

/**
 Just initialize the Branch session with the app launch options, specifying whether to allow it to be treated as a referral.
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @warning This is not the recommended method of initializing Branch. While Branch is able to properly attribute deep linking info with the launch options, you lose the ability to do anything with a callback.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable;

/**
 Initialize the Branch session and handle the completion with a callback
 
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSessionAndRegisterDeepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session and handle the completion with a callback
 
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSession:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options andRegisterDeepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback;


/**
 Allow Branch to handle a link opening the app, returning whether it was from a Branch link or not.
 
 @param url The url that caused the app to be opened.
 */
- (BOOL)handleDeepLink:(NSURL *)url;

#pragma mark - Configuration methods

///--------------------
/// @name Configuration
///--------------------

/**
 Have Branch treat this device / session as a debug session, causing more information to be logged, and info to be available in the debug tab of the dashboard.
 
 @warning This should not be used in production.
 */
+ (void)setDebug;

/**
 Specify the time to wait in seconds between retries in the case of a Branch server error
 
 @param retryInterval Number of seconds to wait between retries
 */
- (void)setRetryInterval:(NSInteger)retryInterval;

/**
 Specify the max number of times to retry in the case of a Branch server error
 
 @param maxRetries Number of retries to make
 */
- (void)setMaxRetries:(NSInteger)maxRetries;

/**
 Specify the amount of time before a request should be considered "timed out"
 
 @param timeout Number of seconds to before a request is considered timed out.
 */
- (void)setNetworkTimeout:(NSInteger)timeout;

/**
 Whether or not Branch should attempt to the devices list of apps
 
 @param appListCheckEnabled Boolean indicating whether to perform the check.
 */
- (void)setAppListCheckEnabled:(BOOL)appListCheckEnabled;

#pragma mark - Session Item methods

///--------------------
/// @name Session Items
///--------------------

/**
 Get the parameters used the first time this user was referred.
 */
- (NSDictionary *)getFirstReferringParams;

/**
 Get the parameters used the most recent time this user was referred (can be empty).
 */
- (NSDictionary *)getLatestReferringParams;

/**
 Tells Branch to act as though initSession hadn't been called. Will require another open call (this is done automatically, internally).
 */
- (void)resetUserSession;

/**
 Set the user's identity to an ID used by your system, so that it is identifiable by you elsewhere.
 
 @param userId The ID Branch should use to identify this user.
 @warning If you use the same ID between users on different sessions / devices, their actions will be merged.
 @warning This request is not removed from the queue upon failure -- it will be retried until it succeeds.
 @warning You should call `logout` before calling `setIdentity:` a second time.
 */
- (void)setIdentity:(NSString *)userId;

/**
 Set the user's identity to an ID used by your system, so that it is identifiable by you elsewhere. Receive a completion callback, notifying you whether it succeeded or failed.
 
 @param userId The ID Branch should use to identify this user.
 @param callback The callback to be called once the request has completed (success or failure).
 @warning If you use the same ID between users on different sessions / devices, their actions will be merged.
 @warning This request is not removed from the queue upon failure -- it will be retried until it succeeds. The callback will only ever be called once, though.
 @warning You should call `logout` before calling `setIdentity:` a second time.
 */
- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback;

/**
 Clear all of the current user's session items.
 
 @warning If the request to logout fails, the items will not be cleared.
 */
- (void)logout;

#pragma mark - Credit methods

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

#pragma mark - Action methods

///--------------
/// @name Actions
///--------------

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback;
- (void)userCompletedAction:(NSString *)action;
- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state;
- (NSInteger)getTotalCountsForAction:(NSString *)action;
- (NSInteger)getUniqueCountsForAction:(NSString *)action;

#pragma mark - Short Url Sync methods

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

#pragma mark - Long Url generation

///--------------------------
/// @name Long Url generation
///--------------------------

- (NSString *)getLongURLWithParams:(NSDictionary *)params;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;
- (NSString *)getLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

#pragma mark - Short Url Async methods

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

#pragma mark - Referral Code methods

///----------------------------
/// @name Referral Code methods
///----------------------------

- (void)getReferralCodeWithCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket calculationType:(BranchReferralCodeCalculation)calcType location:(BranchReferralCodeLocation)location andCallback:(callbackWithParams)callback;
- (void)validateReferralCode:(NSString *)code andCallback:(callbackWithParams)callback;
- (void)applyReferralCode:(NSString *)code andCallback:(callbackWithParams)callback;

@end

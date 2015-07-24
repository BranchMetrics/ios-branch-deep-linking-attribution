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
#import "BNCServerInterface.h"
#import "BNCServerRequestQueue.h"
#import "BNCLinkCache.h"
#import "BranchDeepLinkingController.h"
#import "BNCPreferenceHelper.h"

/**
 `Branch` is the primary interface of the Branch iOS SDK. Currently, all interactions you will make are funneled through this class. It is not meant to be instantiated or subclassed, usage should be limited to the global instance.

  Note, when `getInstance` is called, it assumes that you have already placed a Branch Key in your main `Info.plist` file for your project. For additional information on configuring the Branch SDK, check out the getting started guides in the Readme.
 */

typedef void (^callbackWithParams) (NSDictionary *params, NSError *error);
typedef void (^callbackWithUrl) (NSString *url, NSError *error);
typedef void (^callbackWithStatus) (BOOL changed, NSError *error);
typedef void (^callbackWithList) (NSArray *list, NSError *error);

///----------------
/// @name Constants
///----------------

#pragma mark - Branch Link Features

/**
 ## Branch Link Features
 The following are constants used for specifying a feature parameter on a call that creates a Branch link.

 `BRANCH_FEATURE_SHARE`
 Indicates this link was used for sharing content. Used by the `getContentUrl` methods.

 `BRANCH_FEATURE_TAG_REFERRAL`
 Indicates this link was used to refer users to this app. Used by the `getReferralUrl` methods.

 `BRANCH_FEATURE_TAG_INVITE`
 Indicates this link is used as an invitation.

 `BRANCH_FEATURE_TAG_DEAL`
 Indicates this link is being used to trigger a deal, like a discounted rate.

 `BRANCH_FEATURE_TAG_GIFT`
 Indicates this link is being used to sned a gift to another user.
 */
extern NSString * const BRANCH_FEATURE_TAG_SHARE;
extern NSString * const BRANCH_FEATURE_TAG_REFERRAL;
extern NSString * const BRANCH_FEATURE_TAG_INVITE;
extern NSString * const BRANCH_FEATURE_TAG_DEAL;
extern NSString * const BRANCH_FEATURE_TAG_GIFT;

#pragma mark - Branch InitSession Dictionary Constants

/**
 ## Branch Link Features

 `BRANCH_INIT_KEY_CHANNEL`
 The channel on which the link was shared, specified at link creation time.
 
 `BRANCH_INIT_KEY_FEATURE`
 The feature, such as `invite` or `share`, specified at link creation time.

 `BRANCH_INIT_KEY_TAGS`
 Any tags, specified at link creation time.
 
 `BRANCH_INIT_KEY_CAMPAIGN`
 The campaign the link is associated with, specified at link creation time.
 
 `BRANCH_INIT_KEY_STAGE`
 The stage, specified at link creation time.
 
 `BRANCH_INIT_KEY_CREATION_SOURCE`
 Where the link was created ('API', 'Dashboard', 'SDK', 'iOS SDK', 'Android SDK', or 'Web SDK')
 
 `BRANCH_INIT_KEY_REFERRER`
 The referrer for the link click, if a link was clicked.
 
 `BRANCH_INIT_KEY_PHONE_NUMBER`
 The phone number of the user, if the user texted himself/herself the app.
 
 `BRANCH_INIT_KEY_IS_FIRST_SESSION`
 Denotes whether this is the first session (install) or any other session (open).
 
 `BRANCH_INIT_KEY_CLICKED_BRANCH_LINK`
 Denotes whether or not the user clicked a Branch link that triggered this session.
 */
extern NSString * const BRANCH_INIT_KEY_CHANNEL;
extern NSString * const BRANCH_INIT_KEY_FEATURE;
extern NSString * const BRANCH_INIT_KEY_TAGS;
extern NSString * const BRANCH_INIT_KEY_CAMPAIGN;
extern NSString * const BRANCH_INIT_KEY_STAGE;
extern NSString * const BRANCH_INIT_KEY_CREATION_SOURCE;
extern NSString * const BRANCH_INIT_KEY_REFERRER;
extern NSString * const BRANCH_INIT_KEY_PHONE_NUMBER;
extern NSString * const BRANCH_INIT_KEY_IS_FIRST_SESSION;
extern NSString * const BRANCH_INIT_KEY_CLICKED_BRANCH_LINK;

#pragma mark - Branch Enums
typedef NS_ENUM(NSUInteger, BranchCreditHistoryOrder) {
    BranchMostRecentFirst,
    BranchLeastRecentFirst
};

typedef NS_ENUM(NSUInteger, BranchPromoCodeRewardLocation) {
    BranchPromoCodeRewardReferredUser = 0,
    BranchPromoCodeRewardReferringUser = 2,
    BranchPromoCodeRewardBothUsers = 3
};

typedef NS_ENUM(NSUInteger, BranchPromoCodeUsageType) {
    BranchPromoCodeUsageTypeOncePerUser = 1,
    BranchPromoCodeUsageTypeUnlimitedUses = 0
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
 
 @param params A dictionary to use while building up the Branch link.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params;

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.

 Internally, this will create a short Branch Url that will be attached to the shared content.

 @param params A dictionary to use while building up the Branch link.
 @param feature The feature the generated link will be associated with.
*/
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature  __attribute__((deprecated(("Use methods without 'and'"))));

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link.
 @param feature The feature the generated link will be associated with.
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage __attribute__((deprecated(("Use methods without 'and'"))));

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link.
 @param feature The feature the generated link will be associated with.
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in.
 @param tags An array of tag strings to be associated with the link.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags __attribute__((deprecated(("Use methods without 'and'"))));

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link.
 @param feature The feature the generated link will be associated with.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @warning This can fail if the alias is already taken.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias;
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias __attribute__((deprecated(("Use methods without 'and'"))));
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias __attribute__((deprecated(("Use methods without 'and'"))));

/**
 Create a BranchActivityItemProvider which subclasses the `UIActivityItemProvider` This can be used for simple sharing via a `UIActivityViewController`.
 
 Internally, this will create a short Branch Url that will be attached to the shared content.
 
 @param params A dictionary to use while building up the Branch link.
 @param feature The feature the generated link will be associated with.
 @param stage The stage used for the generated link, typically used to indicate what part of a funnel the user is in.
 @param tags An array of tag strings to be associated with the link.
 @param alias The alias for a link.
 @params delegate A delegate allowing you to override any of the parameters provided here based on the user-selected channel
 @warning This can fail if the alias is already taken.
 */
+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias delegate:(id <BranchActivityItemProviderDelegate>)delegate;



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
 Just initialize the Branch session, specifying whether to allow it to automatically display matching deep linked controllers
 
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSessionAndAutomaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController;

/**
 Initialize the Branch session and handle the completion with a callback
 
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSessionAndRegisterDeepLinkHandler:(callbackWithParams)callback;

/**
 Just initialize the Branch session with the app launch options, specifying whether to allow it to be treated as a referral.
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @warning This is not the recommended method of initializing Branch. While Branch is able to properly attribute deep linking info with the launch options, you lose the ability to do anything with a callback.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable;

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
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController;

/**
 Initialize the Branch session and handle the completion with a callback
 
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSession:(BOOL)isReferrable automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController;

/**
 Initialize the Branch session and handle the completion with a callback
 
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSessionAndAutomaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController deepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController deepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 @warning This is not the recommended method of initializing Branch, as you potentially lose deep linking info by not passing the launch options.
 */
- (void)initSessionAndAutomaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController isReferrable:(BOOL)isReferrable deepLinkHandler:(callbackWithParams)callback;

/**
 Initialize the Branch session with the app launch options and handle the completion with a callback
 
 @param options The launch options provided by the AppDelegate's `didFinishLaunchingWithOptions:` method.
 @param automaticallyDisplayController Boolean indicating whether we will automatically launch into deep linked controller matched in the init session dictionary.
 @param isReferrable Boolean representing whether to allow the session to be marked as referred, overriding the default behavior.
 @param callback A callback that is called when the session is opened. This will be called multiple times during the apps life, including any time the app goes through a background / foreground cycle.
 */
- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController isReferrable:(BOOL)isReferrable deepLinkHandler:(callbackWithParams)callback;

/**
 Allow Branch to handle a link opening the app, returning whether it was from a Branch link or not.
 
 @param url The url that caused the app to be opened.
 */
- (BOOL)handleDeepLink:(NSURL *)url;

#pragma mark - Deep Link Controller methods

///---------------------------
/// @name Deep Link Controller
///---------------------------

- (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)controller forKey:(NSString *)key;

#pragma mark - Configuration methods

///--------------------
/// @name Configuration
///--------------------

/**
 Have Branch treat this device / session as a debug session, causing more information to be logged, and info to be available in the debug tab of the dashboard.
 
 @warning This should not be used in production.
 */
- (void)setDebug;

/**
 Have Branch treat this device / session as a debug session, causing more information to be logged, and info to be available in the debug tab of the dashboard.
 
 @warning Deprecated, use the instance method.
 @warning This should not be used in production.
 */
+ (void)setDebug __attribute__((deprecated(("Use the instance method instead"))));

/**
 Specify the time to wait in seconds between retries in the case of a Branch server error
 
 @param retryInterval Number of seconds to wait between retries.
 */
- (void)setRetryInterval:(NSTimeInterval)retryInterval;

/**
 Specify the max number of times to retry in the case of a Branch server error
 
 @param maxRetries Number of retries to make.
 */
- (void)setMaxRetries:(NSInteger)maxRetries;

/**
 Specify the amount of time before a request should be considered "timed out"
 
 @param timeout Number of seconds to before a request is considered timed out.
 */
- (void)setNetworkTimeout:(NSTimeInterval)timeout;

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
 Indicates whether or not this user has a custom identity specified for them. Note that this is *independent of installs*. If you call setIdentity, this device
 will have that identity associated with this user until `logout` is called. This includes persisting through uninstalls, as we track device id.
 */
- (BOOL)isUserIdentified;

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

/**
 Loads credit totals from the server.
 
 @param callback The callback that is called once the request has completed.
 */
- (void)loadRewardsWithCallback:(callbackWithStatus)callback;

/**
 Redeem credits from the default bucket.
 
 @param count The number of credits to redeem.
 @warning You must `loadRewardsWithCallback:` before calling `redeemRewards`.
 */
- (void)redeemRewards:(NSInteger)count;

/**
 Redeem credits from the default bucket.
 
 @param count The number of credits to redeem.
 @param callback The callback that is called once the request has completed.
 @warning You must `loadRewardsWithCallback:` before calling `redeemRewards`.
 */
- (void)redeemRewards:(NSInteger)count callback:(callbackWithStatus)callback;

/**
 Redeem credits from the specified bucket.
 
 @param count The number of credits to redeem.
 @param bucket The bucket to redeem credits from.
 @warning You must `loadRewardsWithCallback:` before calling `redeemRewards`.
 */
- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket;

/**
 Redeem credits from the specified bucket.
 
 @param count The number of credits to redeem.
 @param bucket The bucket to redeem credits from.
 @param callback The callback that is called once the request has completed.
 @warning You must `loadRewardsWithCallback:` before calling `redeemRewards`.
 */
- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket callback:(callbackWithStatus)callback;

/**
 Get the local credit balance for the default bucket.
 
 @warning You must `loadRewardsWithCallback:` before calling `getCredits`. This method does not make a request for the balance.
 */
- (NSInteger)getCredits;

/**
 Get the local credit balance for the specified bucket.
 
 @param bucket The bucket to get credits balance from.
 @warning You must `loadRewardsWithCallback:` before calling `getCredits`. This method does not make a request for the balance.
 */
- (NSInteger)getCreditsForBucket:(NSString *)bucket;

/**
 Loads the last 100 credit transaction history items for the default bucket.
 
 @param callback The callback to call with the list of transactions.
 */
- (void)getCreditHistoryWithCallback:(callbackWithList)callback;

/**
 Loads the last 100 credit transaction history items for the specified bucket.
 
 @param bucket The bucket to get transaction history for.
 @param callback The callback to call with the list of transactions.
 */
- (void)getCreditHistoryForBucket:(NSString *)bucket andCallback:(callbackWithList)callback;

/**
 Loads the last n credit transaction history items after the specified transaction ID for the default.
 
 @param creditTransactionId The ID of the transaction to start from.
 @param length The number of transactions to pull.
 @param order The direction to order transactions in the callback list. Least recent first means oldest items will be in the front of the response array, most recent means newest items will be front.
 @param callback The callback to call with the list of transactions.
 */
- (void)getCreditHistoryAfter:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback;

/**
 Loads the last n credit transaction history items after the specified transaction ID for the specified bucket.
 
 @param bucket The bucket to get transaction history for.
 @param creditTransactionId The ID of the transaction to start from.
 @param length The number of transactions to pull.
 @param order The direction to order transactions in the callback list. Least recent first means oldest items will be in the front of the response array, most recent means newest items will be front.
 @param callback The callback to call with the list of transactions.
 */
- (void)getCreditHistoryForBucket:(NSString *)bucket after:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback;

#pragma mark - Action methods

///--------------
/// @name Actions
///--------------

/**
 Load actions counts that have taken place for users referred by the current user.

 @param callback The callback that is called once the request has completed.
 */
- (void)loadActionCountsWithCallback:(callbackWithStatus)callback;

/**
 Send a user action to the server. Some examples actions could be things like `viewed_personal_welcome`, `purchased_an_item`, etc.
 
 @param action The action string.
 */
- (void)userCompletedAction:(NSString *)action;

/**
 Send a user action to the server with additional state items. Some examples actions could be things like `viewed_personal_welcome`, `purchased_an_item`, etc.
 
 @param action The action string.
 @param state The additional state items associated with the action.
 */
- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state;

/**
 Gets the total number of times an action has taken place for users referred by the current user. Note, this does not include actions taken by this user, only referred users' actions.
 
 @param action The action string.
 @warning You must `loadActionCountsWithCallback:` before calling `getTotalCountsForAction:`. This method does not make a request for the counts.
 */
- (NSInteger)getTotalCountsForAction:(NSString *)action;

/**
 Gets the distinct number of times an action has taken place for users referred by the current user. Note, this does not include actions taken by this user, only referred users' actions.

 Distinct in this case can be explained as follows:
 Scenario 1: User A completed action `buy`, User B completed action `buy` -- Total Actions: 2, Distinct Actions: 2
 Scenario 2: User A completed action `buy`, User A completed action `buy` again -- Total Actions: 2, Distinct Actions: 1
 
 @param action The action string.
 @warning You must `loadActionCountsWithCallback:` before calling `getUniqueCountsForAction:`. This method does not make a request for the counts.
 */
- (NSInteger)getUniqueCountsForAction:(NSString *)action;

#pragma mark - Short Url Sync methods

///---------------------------------------
/// @name Synchronous Short Url Generation
///---------------------------------------

/**
 Get a short url without any items specified. The usage type will default to unlimited.
 */
- (NSString *)getShortURL;

/**
 Get a short url with specified params. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params;

/**
 Get a short url with specified params, channel, and feature. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature;

/**
 Get a short url with specified params, channel, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage;

/**
 Get a short url with specified params, channel, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @warning This method makes a synchronous url request.
 @warning This can fail if the alias is already taken.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

/**
 Get a short url with specified params, channel, feature, stage, and type.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param type The type of link this is, one of Single Use or Unlimited Use. Single use means once *per user*, not once period.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type;

/**
 Get a short url with specified params, channel, feature, stage, and match duration. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param matchDuration How long to keep an unmatched link click in the Branch backend server's queue before discarding.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration;

/**
 Get a short url with specified tags, params, channel, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage;

/**
 Get a short url with specified tags, params, channel, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @warning This method makes a synchronous url request.
 @warning This can fail if the alias is already taken.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

/**
 Get a short url with specified tags, params, channel, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @param ignoreUAString The User Agent string to tell the server to ignore the next request from, to prevent it from treating a preview scrape as a link click.
 @warning This method makes a synchronous url request.
 @warning This method is primarily intended to be an internal Branch method, used to work around a bug with SLComposeViewController
 @warning This can fail if the alias is already taken.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString;

/**
 Get a short url with specified tags, params, channel, feature, stage, and type.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param type The type of link this is, one of Single Use or Unlimited Use. Single use means once *per user*, not once period.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type;

/**
 Get a short url with specified tags, params, channel, feature, stage, and match duration. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param matchDuration How long to keep an unmatched link click in the Branch backend server's queue before discarding.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration;

/**
 Get a short url with specified params and channel. The usage type will default to unlimited. Content Urls use the feature `BRANCH_FEATURE_TAG_SHARE`.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Content Urls use the feature `BRANCH_FEATURE_TAG_SHARE`.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel;

/**
 Get a short url with specified params and channel. The usage type will default to unlimited. Referral Urls use the feature `BRANCH_FEATURE_TAG_REFERRAL`.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Referral Urls use the feature `BRANCH_FEATURE_TAG_REFERRAL`.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @warning This method makes a synchronous url request.
 */
- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel;

#pragma mark - Long Url generation

///--------------------------
/// @name Long Url generation
///--------------------------

/**
 Construct a long url with specified params. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params;

/**
 Get a long url with specified params and feature. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature;

/**
 Get a long url with specified params, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage;

/**
 Get a long url with specified params, feature, stage, and tags. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param tags An array of tags to associate with this link, useful for tracking.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags;

/**
 Get a long url with specified params, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @warning This can fail if the alias is already taken.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

/**
 Get a long url with specified params, channel, tags, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @warning This can fail if the alias is already taken.
 */
- (NSString *)getLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias;

#pragma mark - Short Url Async methods

///----------------------------------------
/// @name Asynchronous Short Url Generation
///----------------------------------------

/**
 Get a short url without any items specified. The usage type will default to unlimited.
 
 @param callback Callback called with the url.
 */
- (void)getShortURLWithCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, channel, and feature. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, channel, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, channel, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @param callback Callback called with the url.
 @warning This can fail if the alias is already taken.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, channel, feature, stage, and link type.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param type The type of link this is, one of Single Use or Unlimited Use. Single use means once *per user*, not once period.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, channel, feature, stage, and match duration. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param matchDuration How long to keep an unmatched link click in the Branch backend server's queue before discarding.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, tags, channel, feature, and stage. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, tags, channel, feature, stage, and alias. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param alias The alias for a link.
 @param callback Callback called with the url.
 @warning This can fail if the alias is already taken.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, tags, channel, feature, stage, and link type.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param type The type of link this is, one of Single Use or Unlimited Use. Single use means once *per user*, not once period.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback;

/**
 Get a short url with the specified params, tags, channel, feature, stage, and match duration. The usage type will default to unlimited.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param feature The feature this is utilizing. Examples could be Sharing, Referring, Inviting, etc.
 @param stage The stage used for the generated link, indicating what part of a funnel the user is in.
 @param matchDuration How long to keep an unmatched link click in the Branch backend server's queue before discarding.
 @param callback Callback called with the url.
 */
- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Content Urls use the feature `BRANCH_FEATURE_TAG_SHARE`.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param callback Callback called with the url.
 */
- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Content Urls use the feature `BRANCH_FEATURE_TAG_SHARE`.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param callback Callback called with the url.
 */
- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Referral Urls use the feature `BRANCH_FEATURE_TAG_REFERRAL`.
 
 @param params Dictionary of parameters to include in the link.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param callback Callback called with the url.
 */
- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;

/**
 Get a short url with specified params, tags, and channel. The usage type will default to unlimited. Referral Urls use the feature `BRANCH_FEATURE_TAG_REFERRAL`.
 
 @param params Dictionary of parameters to include in the link.
 @param tags An array of tags to associate with this link, useful for tracking.
 @param channel The channel for the link. Examples could be Facebook, Twitter, SMS, etc, depending on where it will be shared.
 @param callback Callback called with the url.
 */
- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback;

#pragma mark - Referral Code methods

///-------------------------
/// @name Promo Code methods
///-------------------------

/**
 Get a promo code without providing any parameters.
 
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithCallback:(callbackWithParams)callback;
- (void)getReferralCodeWithCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeCallback: instead"))));;

/**
 Get a promo code with an amount of credits the code will be worth.
 
 @param amount Number of credits generating user will earn when a user is referred by this code.
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithAmount:(NSInteger)amount callback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeWithAmount:callback: instead"))));;

/**
 Get a promo code with an amount of credits the code will be worth, and a prefix for the code.
 
 @param prefix The string to prefix the code with.
 @param amount Number of credits generating user will earn when a user is referred by this code.
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount callback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeWithPrefix:amount:callback: instead"))));;

/**
 Get a promo code with an amount of credits the code will be worth, and an expiration date.
 
 @param amount Number of credits generating user will earn when a user is referred by this code.
 @param expiration The date when the code should be invalidated.
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration callback:(callbackWithParams)callback;
- (void)getReferralCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeWithAmount:expiration:callback: instead"))));

/**
 Get a promo code with an amount of credits the code will be worth, the prefix to put in front of it, and an expiration date.
 
 @param prefix The string to prefix the code with.
 @param amount Number of credits generating user will earn when a user is referred by this code.
 @param expiration The date when the code should be invalidated.
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration callback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeWithPrefix:amount:expiration:callback: instead"))));

/**
 Get a promo code with an amount of credits the code will be worth, the prefix to put in front of it, an expiration date, the bucket it will be part of, the calculation method, and location of user earning credits.
 
 @param prefix The string to prefix the code with.
 @param amount Number of credits to be earned (by the user specified by location).
 @param expiration The date when the code should be invalidated.
 @param bucket A bucket the credits should be associated with.
 @param type The type of this code will be, one of Single Use or Unlimited Use. Single use means once *per user*, not once period.
 @param location The location of the user who earns credits for the referral, one of Referrer, Referree (the referred user), or Both.
 @param callback The callback that is called with the created referral code object.
 */
- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket usageType:(BranchPromoCodeUsageType)usageType rewardLocation:(BranchPromoCodeRewardLocation)rewardLocation callback:(callbackWithParams)callback;
- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket calculationType:(BranchPromoCodeUsageType)calcType location:(BranchPromoCodeRewardLocation)location andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use getPromoCodeWithPrefix:amount:expiration:bucket:usageType:rewardLocation:callback: instead"))));

/**
 Validate a promo code. Will callback with the referral code object on success, or an error if it's invalid.
 
 @param code The referral code to validate
 @param callback The callback that is called with the referral code object on success, or an error if it's invalid.
 */
- (void)validatePromoCode:(NSString *)code callback:(callbackWithParams)callback;
- (void)validateReferralCode:(NSString *)code andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use validatePromoCode:callback: instead"))));

/**
 Apply a promo code, awarding the referral points. Will callback with the referral code object on success, or an error if it's invalid.
 
 @param code The referral code to validate
 @param callback The callback that is called with the referral code object on success, or an error if it's invalid.
 */
- (void)applyPromoCode:(NSString *)code callback:(callbackWithParams)callback;
- (void)applyReferralCode:(NSString *)code andCallback:(callbackWithParams)callback __attribute__((deprecated(("Use applyPromoCode:callback: instead"))));

/**
 Method for creating a one of Branch instance and specifying its dependencies.
 
 @warning This is meant for use internally only (exposed for the sake of testing) and should not be used by apps.
 */
- (id)initWithInterface:(BNCServerInterface *)interface queue:(BNCServerRequestQueue *)queue cache:(BNCLinkCache *)cache preferenceHelper:(BNCPreferenceHelper *)preferenceHelper key:(NSString *)key;

/**
 Method for logging a message to the Branch server, used when remote debugging is enabled.
 
 @warning This is meant for use internally only (exposed for the sake of testing) and should not be used by apps.
 */
- (void)log:(NSString *)log;

@end

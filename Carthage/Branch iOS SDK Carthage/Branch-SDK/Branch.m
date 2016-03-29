//
//  Branch_SDK.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequest.h"
#import "BNCServerResponse.h"
#import "BNCSystemObserver.h"
#import "BNCServerRequestQueue.h"
#import "BNCConfig.h"
#import "BNCError.h"
#import "BNCLinkData.h"
#import "BNCLinkCache.h"
#import "BNCEncodingUtils.h"
#import "BNCContentDiscoveryManager.h"
#import "BNCStrongMatchHelper.h"
#import "BranchUniversalObject.h"
#import "BranchSetIdentityRequest.h"
#import "BranchLogoutRequest.h"
#import "BranchLoadActionsRequest.h"
#import "BranchUserCompletedActionRequest.h"
#import "BranchLoadRewardsRequest.h"
#import "BranchRedeemRewardsRequest.h"
#import "BranchCreditHistoryRequest.h"
#import "BranchGetPromoCodeRequest.h"
#import "BranchValidatePromoCodeRequest.h"
#import "BranchApplyPromoCodeRequest.h"
#import "BranchShortUrlRequest.h"
#import "BranchShortUrlSyncRequest.h"
#import "BranchCloseRequest.h"
#import "BranchOpenRequest.h"
#import "BranchInstallRequest.h"
#import "BranchSpotlightUrlRequest.h"
#import "BranchRegisterViewRequest.h"

NSString * const BRANCH_FEATURE_TAG_SHARE = @"share";
NSString * const BRANCH_FEATURE_TAG_REFERRAL = @"referral";
NSString * const BRANCH_FEATURE_TAG_INVITE = @"invite";
NSString * const BRANCH_FEATURE_TAG_DEAL = @"deal";
NSString * const BRANCH_FEATURE_TAG_GIFT = @"gift";

NSString * const BRANCH_INIT_KEY_CHANNEL = @"~channel";
NSString * const BRANCH_INIT_KEY_FEATURE = @"~feature";
NSString * const BRANCH_INIT_KEY_TAGS = @"~tags";
NSString * const BRANCH_INIT_KEY_CAMPAIGN = @"~campaign";
NSString * const BRANCH_INIT_KEY_STAGE = @"~stage";
NSString * const BRANCH_INIT_KEY_CREATION_SOURCE = @"~creation_source";
NSString * const BRANCH_INIT_KEY_REFERRER = @"+referrer";
NSString * const BRANCH_INIT_KEY_PHONE_NUMBER = @"+phone_number";
NSString * const BRANCH_INIT_KEY_IS_FIRST_SESSION = @"+is_first_session";
NSString * const BRANCH_INIT_KEY_CLICKED_BRANCH_LINK = @"+clicked_branch_link";
NSString * const BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY = @"branch";

@interface Branch() <BranchDeepLinkingControllerCompletionDelegate>


@property (strong, nonatomic) BNCServerInterface *bServerInterface;
@property (strong, nonatomic) NSTimer *sessionTimer;
@property (strong, nonatomic) BNCServerRequestQueue *requestQueue;
@property (strong, nonatomic) dispatch_semaphore_t processing_sema;
@property (strong, nonatomic) callbackWithParams sessionInitWithParamsCallback;
@property (strong, nonatomic) callbackWithBranchUniversalObject sessionInitWithBranchUniversalObjectCallback;
@property (assign, nonatomic) NSInteger networkCount;
@property (assign, nonatomic) BOOL isInitialized;
@property (assign, nonatomic) BOOL shouldCallSessionInitCallback;
@property (assign, nonatomic) BOOL shouldAutomaticallyDeepLink;
@property (strong, nonatomic) BNCLinkCache *linkCache;
@property (strong, nonatomic) BNCPreferenceHelper *preferenceHelper;
@property (strong, nonatomic) BNCContentDiscoveryManager *contentDiscoveryManager;
@property (strong, nonatomic) UILongPressGestureRecognizer *debugGestureRecognizer;
@property (strong, nonatomic) NSTimer *debugHeartbeatTimer;
@property (strong, nonatomic) NSString *branchKey;
@property (strong, nonatomic) NSMutableDictionary *deepLinkControllers;
@property (weak, nonatomic) UIViewController *deepLinkPresentingController;
@property (assign, nonatomic) BOOL useCookieBasedMatching;
@property (strong, nonatomic) NSDictionary *deepLinkDebugParams;
@property (assign, nonatomic) BOOL accountForFacebookSDK;


@end

@implementation Branch

#pragma mark - Public methods


#pragma mark - GetInstance methods

+ (Branch *)getInstance {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    
    // If no Branch Key
    NSString *branchKey = [preferenceHelper getBranchKey:YES];
    NSString *keyToUse = branchKey;
    if (!branchKey) {
        // If no app key
        NSString *appKey = preferenceHelper.appKey;
        if (!appKey) {
            NSLog(@"[Branch Warning] Please enter your branch_key in the plist!");
            return nil;
        }
        else {
            keyToUse = appKey;
            NSLog(@"Usage of App Key is deprecated, please move toward using a Branch key");
        }
    }
    
    return [Branch getInstanceInternal:keyToUse returnNilIfNoCurrentInstance:NO];
}

+ (Branch *)getTestInstance {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    
    // If no Branch Key
    NSString *branchKey = [preferenceHelper getBranchKey:NO];
    NSString *keyToUse = branchKey;
    if (!branchKey) {
        // If no app key
        NSString *appKey = preferenceHelper.appKey;
        if (!appKey) {
            NSLog(@"[Branch Warning] Please enter your branch_key in the plist!");
            return nil;
        }
        // If they did provide an app key, show them a warning. Shouldn't use app key with a test instance.
        else {
            NSLog(@"[Branch Warning] You requested the test instance, but provided an app key. App Keys cannot be used for test instances. Additionally, usage of App Key is deprecated, please move toward using a Branch key");
            keyToUse = appKey;
        }
    }
    
    return [Branch getInstanceInternal:keyToUse returnNilIfNoCurrentInstance:NO];
}

+ (Branch *)getInstance:(NSString *)branchKey {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    
    if ([branchKey rangeOfString:@"key_"].location != NSNotFound) {
        preferenceHelper.branchKey = branchKey;
    }
    else {
        preferenceHelper.appKey = branchKey;
    }
    
    return [Branch getInstanceInternal:branchKey returnNilIfNoCurrentInstance:NO];
}

- (id)initWithInterface:(BNCServerInterface *)interface queue:(BNCServerRequestQueue *)queue cache:(BNCLinkCache *)cache preferenceHelper:(BNCPreferenceHelper *)preferenceHelper key:(NSString *)key {
    if (self = [super init]) {
        _bServerInterface = interface;
        _bServerInterface.preferenceHelper = preferenceHelper;
        _requestQueue = queue;
        _linkCache = cache;
        _preferenceHelper = preferenceHelper;
        _branchKey = key;
        
        _contentDiscoveryManager = [[BNCContentDiscoveryManager alloc] init];
        _isInitialized = NO;
        _shouldCallSessionInitCallback = YES;
        _processing_sema = dispatch_semaphore_create(1);
        _networkCount = 0;
        _deepLinkControllers = [[NSMutableDictionary alloc] init];
        _useCookieBasedMatching = YES;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}


#pragma mark - BrachActivityItemProvider methods

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:nil stage:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:stage alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage alias:alias delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params feature:(NSString *)feature stage:(NSString *)stage tags:(NSArray *)tags alias:(NSString *)alias delegate:(id <BranchActivityItemProviderDelegate>)delegate {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage alias:alias delegate:delegate];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:nil alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:stage alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage alias:nil delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:nil feature:feature stage:stage alias:alias delegate:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithParams:params tags:tags feature:feature stage:stage alias:alias delegate:nil];
}

#pragma mark - Configuration methods

+ (void)setDebug {
    [[Branch getInstance] setDebug];
}

- (void)setDebug {
    self.preferenceHelper.isDebug = YES;
}

- (void)resetUserSession {
    self.isInitialized = NO;
}

- (BOOL)isUserIdentified {
    return self.preferenceHelper.userIdentity != nil;
}

- (void)setNetworkTimeout:(NSTimeInterval)timeout {
    self.preferenceHelper.timeout = timeout;
}

- (void)setMaxRetries:(NSInteger)maxRetries {
    self.preferenceHelper.retryCount = maxRetries;
}

- (void)setRetryInterval:(NSTimeInterval)retryInterval {
    self.preferenceHelper.retryInterval = retryInterval;
}

- (void)disableCookieBasedMatching {
    self.useCookieBasedMatching = NO;
}

- (void)accountForFacebookSDKPreventingAppLaunch {
    self.accountForFacebookSDK = YES;
}

#pragma mark - InitSession Permutation methods

- (void)initSessionWithLaunchOptions:(NSDictionary *)options {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options andRegisterDeepLinkHandler:(callbackWithParams)callback {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options andRegisterDeepLinkHandlerUsingBranchUniversalObject:(callbackWithBranchUniversalObject)callback {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:NO registerDeepLinkHandlerUsingBranchUniversalObject:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable {
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:YES automaticallyDisplayController:NO registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:automaticallyDisplayController registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback {
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:YES automaticallyDisplayController:NO registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController deepLinkHandler:(callbackWithParams)callback {
    [self initSessionWithLaunchOptions:options isReferrable:YES explicitlyRequestedReferrable:NO automaticallyDisplayController:automaticallyDisplayController registerDeepLinkHandler:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController {
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:YES automaticallyDisplayController:automaticallyDisplayController registerDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options automaticallyDisplayDeepLinkController:(BOOL)automaticallyDisplayController isReferrable:(BOOL)isReferrable deepLinkHandler:(callbackWithParams)callback {
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:YES automaticallyDisplayController:automaticallyDisplayController registerDeepLinkHandler:callback];
}


#pragma mark - Actual Init Session

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable automaticallyDisplayController:(BOOL)automaticallyDisplayController registerDeepLinkHandlerUsingBranchUniversalObject:(callbackWithBranchUniversalObject)callback {
    self.sessionInitWithBranchUniversalObjectCallback = callback;
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:explicitlyRequestedReferrable automaticallyDisplayController:automaticallyDisplayController];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable automaticallyDisplayController:(BOOL)automaticallyDisplayController registerDeepLinkHandler:(callbackWithParams)callback {
    self.sessionInitWithParamsCallback = callback;
    [self initSessionWithLaunchOptions:options isReferrable:isReferrable explicitlyRequestedReferrable:explicitlyRequestedReferrable automaticallyDisplayController:automaticallyDisplayController];
}


- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable explicitlyRequestedReferrable:(BOOL)explicitlyRequestedReferrable automaticallyDisplayController:(BOOL)automaticallyDisplayController {
    self.shouldAutomaticallyDeepLink = automaticallyDisplayController;
    
    self.preferenceHelper.isReferrable = isReferrable;
    self.preferenceHelper.explicitlyRequestedReferrable = explicitlyRequestedReferrable;

    // Handle push notification on app launch
    if ([options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        id branchUrlFromPush = [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey][BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY];
        if ([branchUrlFromPush isKindOfClass:[NSString class]]) {
            self.preferenceHelper.universalLinkUrl = branchUrlFromPush;
        }
    }
    
    if ([BNCSystemObserver getOSVersion].integerValue >= 8) {
        if (![options objectForKey:UIApplicationLaunchOptionsURLKey] && ![options objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
            [self initUserSessionAndCallCallback:YES];
        }
        else if ([options objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
            self.preferenceHelper.isContinuingUserActivity = YES;
            if (self.accountForFacebookSDK) {
                id activity = [[options objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey] objectForKey:@"UIApplicationLaunchOptionsUserActivityKey"];
                if (activity && [activity isKindOfClass:[NSUserActivity class]]) {
                    [self continueUserActivity:activity];
                }
            }
        }
    }
    else if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
        [self initUserSessionAndCallCallback:YES];
    }
}



//these params will be added
- (void) setDeepLinkDebugMode:(NSDictionary *)debugParams {
    self.deepLinkDebugParams = debugParams;
}


- (BOOL)handleDeepLink:(NSURL *)url {
    BOOL handled = NO;
    if (url) {
        //always save the incoming url in the preferenceHelper in the externalIntentURI field
        self.preferenceHelper.externalIntentURI = [url absoluteString];

        NSString *query = [url fragment];
        if (!query) {
            query = [url query];
        }
        
        NSDictionary *params = [BNCEncodingUtils decodeQueryStringToDictionary:query];
        if (params[@"link_click_id"]) {
            handled = YES;
            self.preferenceHelper.linkClickIdentifier = params[@"link_click_id"];
        }
    }
    
    [self initUserSessionAndCallCallback:YES];
    
    return handled;
}

- (BOOL)continueUserActivity:(NSUserActivity *)userActivity {
    //check to see if a browser activity needs to be handled
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        self.preferenceHelper.universalLinkUrl = [userActivity.webpageURL absoluteString];
        [self initUserSessionAndCallCallback:YES];
        self.preferenceHelper.isContinuingUserActivity = NO;
        
        id branchUniversalLinkDomains = [self.preferenceHelper getBranchUniversalLinkDomains];
        if ([branchUniversalLinkDomains isKindOfClass:[NSString class]] && [[userActivity.webpageURL absoluteString] containsString:branchUniversalLinkDomains]) {
            return YES;
        }
        else if ([branchUniversalLinkDomains isKindOfClass:[NSArray class]]) {
            for (id oneDomain in branchUniversalLinkDomains) {
                if ([oneDomain isKindOfClass:[NSString class]] && [[userActivity.webpageURL absoluteString] containsString:oneDomain]) {
                    return YES;
                }
            }
        }
        
        return [[userActivity.webpageURL absoluteString] containsString:@"bnc.lt"];
    }
    
    //check to see if a spotlight activity needs to be handled
    NSString *spotlightIdentifier = [self.contentDiscoveryManager spotlightIdentifierFromActivity:userActivity];
    
    if (spotlightIdentifier) {
        self.preferenceHelper.spotlightIdentifier = spotlightIdentifier;
    }
    else {
        NSString *nonBranchSpotlightIdentifier = [self.contentDiscoveryManager standardSpotlightIdentifierFromActivity:userActivity];
        if (nonBranchSpotlightIdentifier) {
            self.preferenceHelper.spotlightIdentifier = nonBranchSpotlightIdentifier;
        }
    }
    [self initUserSessionAndCallCallback:YES];
    self.preferenceHelper.isContinuingUserActivity = NO;
    
    return spotlightIdentifier != nil;
}

#pragma mark - Generic Request support

- (void)executeGenericRequest:(BNCServerRequest*)request {
    [self initSessionIfNeededAndNotInProgress];
    [self.requestQueue enqueue:request];
    [self processNextQueueItem];
}


#pragma mark - Push Notification support

// handle push notification if app is already launched
- (void)handlePushNotification:(NSDictionary *) userInfo {
    // If app is active, then close out the session and start a new one
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self callClose];
    }

    // look for a branch shortlink in the payload (shortlink because iOS7 only supports 256 bytes)
    NSString *urlStr = [userInfo objectForKey:BRANCH_PUSH_NOTIFICATION_PAYLOAD_KEY];
    if (urlStr) {
        // reusing this field, so as not to create yet another url slot on prefshelper
        self.preferenceHelper.universalLinkUrl = urlStr;
    }

    // Again, if app is active, then close out the session and start a new one
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self applicationDidBecomeActive];
    }
}


#pragma mark - Deep Link Controller methods

- (void)registerDeepLinkController:(UIViewController <BranchDeepLinkingController> *)controller forKey:(NSString *)key {
    self.deepLinkControllers[key] = controller;
}


#pragma mark - Identity methods

- (void)setIdentity:(NSString *)userId {
    [self setIdentity:userId withCallback:NULL];
}

- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback {
    if (!userId || [self.preferenceHelper.userIdentity isEqualToString:userId]) {
        if (callback) {
            callback([self getFirstReferringParams], nil);
        }
        return;
    }
    
    [self initSessionIfNeededAndNotInProgress];
    
    BranchSetIdentityRequest *req = [[BranchSetIdentityRequest alloc] initWithUserId:userId callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (void)logout {
    [self logoutWithCallback:nil];
}


- (void)logoutWithCallback:(callbackWithStatus)callback {
    if (!self.isInitialized) {
        NSLog(@"Branch is not initialized, cannot logout");
        if (callback) {callback(NO, nil);}
    }
    
    BranchLogoutRequest *req = [[BranchLogoutRequest alloc] initWithCallback:^(BOOL success, NSError *error) {
        if (success) {
            // Clear cached links
            self.linkCache = [[BNCLinkCache alloc] init];
            
            if (callback) {
                callback(YES, nil);
            }
            if (self.preferenceHelper.isDebug) {
                NSLog(@"Logout Success");
            }
        } else /*failure*/ {
            if (callback) {
                callback(NO, error);
            }
            if (self.preferenceHelper.isDebug) {
                NSLog(@"Logout Failure");
            }
        }
    }];
    
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}



#pragma mark - User Action methods

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BranchLoadActionsRequest *req = [[BranchLoadActionsRequest alloc] initWithCallback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (NSInteger)getTotalCountsForAction:(NSString *)action {
    return [self.preferenceHelper getActionTotalCount:action];
}

- (NSInteger)getUniqueCountsForAction:(NSString *)action {
    return [self.preferenceHelper getActionUniqueCount:action];
}

- (void)userCompletedAction:(NSString *)action {
    [self userCompletedAction:action withState:nil];
}

- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state {
    if (!action) {
        return;
    }
    
    [self initSessionIfNeededAndNotInProgress];
    
    BranchUserCompletedActionRequest *req = [[BranchUserCompletedActionRequest alloc] initWithAction:action state:state];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}


#pragma mark - Credit methods

- (void)loadRewardsWithCallback:(callbackWithStatus)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BranchLoadRewardsRequest *req = [[BranchLoadRewardsRequest alloc] initWithCallback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (NSInteger)getCredits {
    return [self.preferenceHelper getCreditCount];
}

- (void)redeemRewards:(NSInteger)count {
    [self redeemRewards:count forBucket:@"default" callback:NULL];
}

- (void)redeemRewards:(NSInteger)count callback:(callbackWithStatus)callback {
    [self redeemRewards:count forBucket:@"default" callback:callback];
}

- (NSInteger)getCreditsForBucket:(NSString *)bucket {
    return [self.preferenceHelper getCreditCountForBucket:bucket];
}

- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket {
    [self redeemRewards:count forBucket:bucket callback:NULL];
}

- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket callback:(callbackWithStatus)callback {
    if (count == 0) {
        if (callback) {
            callback(false, [NSError errorWithDomain:BNCErrorDomain code:BNCRedeemCreditsError userInfo:@{ NSLocalizedDescriptionKey: @"Cannot redeem zero credits." }]);
        }
        else {
            NSLog(@"[Branch Warning] Cannot redeem zero credits");
        }
        return;
    }
    
    NSInteger totalAvailableCredits = [self.preferenceHelper getCreditCountForBucket:bucket];
    if (count > totalAvailableCredits) {
        if (callback) {
            callback(false, [NSError errorWithDomain:BNCErrorDomain code:BNCRedeemCreditsError userInfo:@{ NSLocalizedDescriptionKey: @"You're trying to redeem more credits than are available. Have you loaded rewards?" }]);
        }
        else {
            NSLog(@"[Branch Warning] You're trying to redeem more credits than are available. Have you loaded rewards?");
        }
        return;
    }
    
    [self initSessionIfNeededAndNotInProgress];
    
    BranchRedeemRewardsRequest *req = [[BranchRedeemRewardsRequest alloc] initWithAmount:count bucket:bucket callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (void)getCreditHistoryWithCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:nil after:nil number:100 order:BranchMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:bucket after:nil number:100 order:BranchMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryAfter:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:nil after:creditTransactionId number:length order:order andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket after:(NSString *)creditTransactionId number:(NSInteger)length order:(BranchCreditHistoryOrder)order andCallback:(callbackWithList)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BranchCreditHistoryRequest *req = [[BranchCreditHistoryRequest alloc] initWithBucket:bucket creditTransactionId:creditTransactionId length:length order:order callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (BranchUniversalObject *)getFirstReferringBranchUniversalObject {
    NSDictionary *params = [self getFirstReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchUniversalObject getBranchUniversalObjectFromDictionary:params];
    }
    return nil;
}

- (BranchLinkProperties *)getFirstReferringBranchLinkProperties {
    NSDictionary *params = [self getFirstReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchLinkProperties getBranchLinkPropertiesFromDictionary:params];
    }
    return nil;
}

- (NSDictionary *)getFirstReferringParams {
    NSDictionary *origInstallParams = [BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.installParams];
    
    if (self.deepLinkDebugParams) {
        NSMutableDictionary* debugInstallParams = [[BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.sessionParams] mutableCopy];
        [debugInstallParams addEntriesFromDictionary:self.deepLinkDebugParams];
        return debugInstallParams;
    }
    return origInstallParams;
}

- (NSDictionary *)getLatestReferringParams {
    NSDictionary *origSessionParams = [BNCEncodingUtils decodeJsonStringToDictionary:self.preferenceHelper.sessionParams];
    
    if (self.deepLinkDebugParams) {
        NSMutableDictionary* debugSessionParams = [origSessionParams mutableCopy];
        [debugSessionParams addEntriesFromDictionary:self.deepLinkDebugParams];
        return debugSessionParams;
    }
    return origSessionParams;
}

- (BranchUniversalObject *)getLatestReferringBranchUniversalObject {
    NSDictionary *params = [self getLatestReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchUniversalObject getBranchUniversalObjectFromDictionary:params];
    }
    return nil;
}

- (BranchLinkProperties *)getLatestReferringBranchLinkProperties {
    NSDictionary *params = [self getLatestReferringParams];
    if ([[params objectForKey:BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] isEqual:@1]) {
        return [BranchLinkProperties getBranchLinkPropertiesFromDictionary:params];
    }
    return nil;
}

#pragma mark - ContentUrl methods

- (NSString *)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:params andCallback:callback];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:params andCallback:callback];
}


#pragma mark - ShortUrl methods

- (NSString *)getShortURL {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andParams:nil ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:ignoreUAString forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias ignoreUAString:(NSString *)ignoreUAString forceLinkCreation:(BOOL)forceLinkCreation {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:ignoreUAString forceLinkCreation:forceLinkCreation];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:tags andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:nil andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (void)getShortURLWithCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andParams:nil andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:nil andFeature:nil andStage:nil andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:type andMatchDuration:0 andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andMatchDuration:(NSUInteger)duration andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:feature andStage:nil andParams:params andCallback:callback];
}

- (void)getShortUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andAlias:(NSString *)alias andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params andCallback:callback];
}

- (void)getSpotlightUrlWithParams:(NSDictionary *)params callback:(callbackWithParams)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BranchSpotlightUrlRequest *req = [[BranchSpotlightUrlRequest alloc] initWithParams:params callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

#pragma mark - LongUrl methods
- (NSString *)getLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateLongURLWithParams:params andChannel:channel andTags:tags andFeature:feature andStage:stage andAlias:alias];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:nil andStage:nil andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:nil andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:stage andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andTags:(NSArray *)tags {
    return [self generateLongURLWithParams:params andChannel:nil andTags:tags andFeature:feature andStage:stage andAlias:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateLongURLWithParams:params andChannel:nil andTags:nil andFeature:feature andStage:stage andAlias:alias];
}

#pragma mark - Discoverable content methods

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords callback:callback];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams publiclyIndexable:(BOOL)publiclyIndexable {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable thumbnailUrl:thumbnailUrl userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords];
}

- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams callback:callback];
}
- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate callback:(callbackWithUrl)callback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:callback];
}

//Use this with iOS 9+ only
- (void)createDiscoverableContentWithTitle:(NSString *)title description:(NSString *)description thumbnailUrl:(NSURL *)thumbnailUrl linkParams:(NSDictionary *)linkParams type:(NSString *)type publiclyIndexable:(BOOL)publiclyIndexable keywords:(NSSet *)keywords expirationDate:(NSDate *)expirationDate spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    [self.contentDiscoveryManager indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:linkParams expirationDate:expirationDate callback:nil spotlightCallback:spotlightCallback];
}

#pragma mark - Referral methods

- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:params ignoreUAString:nil forceLinkCreation:NO];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:params andCallback:callback];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andMatchDuration:0 andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:params andCallback:callback];
}

- (void)getPromoCodeWithCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:0 expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:0 expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getPromoCodeWithAmount:(NSInteger)amount callback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:amount expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithAmount:(NSInteger)amount andCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:amount expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount callback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount andCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:nil bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getPromoCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration callback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:amount expiration:expiration bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:nil amount:amount expiration:expiration bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration callback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:expiration bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:expiration bucket:nil usageType:BranchPromoCodeUsageTypeUnlimitedUses rewardLocation:BranchPromoCodeRewardReferringUser callback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket calculationType:(BranchPromoCodeUsageType)calcType location:(BranchPromoCodeRewardLocation)location andCallback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:expiration bucket:bucket usageType:calcType rewardLocation:location useOld:YES callback:callback];
}

- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket usageType:(BranchPromoCodeUsageType)usageType rewardLocation:(BranchPromoCodeRewardLocation)rewardLocation callback:(callbackWithParams)callback {
    [self getPromoCodeWithPrefix:prefix amount:amount expiration:expiration bucket:bucket usageType:usageType rewardLocation:rewardLocation useOld:NO callback:callback];
}

- (void)getPromoCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket usageType:(BranchPromoCodeUsageType)usageType rewardLocation:(BranchPromoCodeRewardLocation)rewardLocation useOld:(BOOL)useOld callback:(callbackWithParams)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    if (!bucket) {
        bucket = @"default";
    }
    
    BranchGetPromoCodeRequest *req = [[BranchGetPromoCodeRequest alloc] initWithUsageType:usageType rewardLocation:rewardLocation amount:amount bucket:bucket prefix:prefix expiration:expiration useOld:useOld callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (void)validateReferralCode:(NSString *)code andCallback:(callbackWithParams)callback {
    [self validatePromoCode:code useOld:YES callback:callback];
}

- (void)validatePromoCode:(NSString *)code callback:(callbackWithParams)callback {
    [self validatePromoCode:code useOld:NO callback:callback];
}

- (void)validatePromoCode:(NSString *)code useOld:(BOOL)useOld callback:(callbackWithParams)callback {
    if (!code.length) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidPromoCodeError userInfo:@{ NSLocalizedDescriptionKey: @"No code specified" }]);
        }
        return;
    }
    
    [self initSessionIfNeededAndNotInProgress];
    
    BranchValidatePromoCodeRequest *req = [[BranchValidatePromoCodeRequest alloc] initWithCode:code useOld:useOld callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (void)applyReferralCode:(NSString *)code andCallback:(callbackWithParams)callback {
    [self applyPromoCode:code useOld:YES callback:callback];
}

- (void)applyPromoCode:(NSString *)code callback:(callbackWithParams)callback {
    [self applyPromoCode:code useOld:NO callback:callback];
}

- (void)applyPromoCode:(NSString *)code useOld:(BOOL)useOld callback:(callbackWithParams)callback {
    if (!code.length) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidPromoCodeError userInfo:@{ NSLocalizedDescriptionKey: @"No code specified" }]);
        }
        return;
    }
    
    [self initSessionIfNeededAndNotInProgress];
    
    BranchApplyPromoCodeRequest *req = [[BranchApplyPromoCodeRequest alloc] initWithCode:code useOld:useOld callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}


#pragma mark - Private methods

+ (Branch *)getInstanceInternal:(NSString *)key returnNilIfNoCurrentInstance:(BOOL)returnNilIfNoCurrentInstance {
    static Branch *branch;
    
    if (!branch && returnNilIfNoCurrentInstance) {
        return nil;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
        
        // If there was stored key and it isn't the same as the currently used (or doesn't exist), we need to clean up
        // Note: Link Click Identifier is not cleared because of the potential for that to mess up a deep link
        if (preferenceHelper.lastRunBranchKey && ![key isEqualToString:preferenceHelper.lastRunBranchKey]) {
            NSLog(@"[Branch Warning] The Branch Key has changed, clearing relevant items");
            
            preferenceHelper.appVersion = nil;
            preferenceHelper.deviceFingerprintID = nil;
            preferenceHelper.sessionID = nil;
            preferenceHelper.identityID = nil;
            preferenceHelper.userUrl = nil;
            preferenceHelper.installParams = nil;
            preferenceHelper.sessionParams = nil;
            
            [[BNCServerRequestQueue getInstance] clearQueue];
        }
        
        preferenceHelper.lastRunBranchKey = key;
        
        branch = [[Branch alloc] initWithInterface:[[BNCServerInterface alloc] init] queue:[BNCServerRequestQueue getInstance] cache:[[BNCLinkCache alloc] init] preferenceHelper:preferenceHelper key:key];
    });
    
    return branch;
}


#pragma mark - URL Generation methods

- (void)generateShortUrl:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BNCLinkData *linkData = [self prepareLinkDataFor:tags andAlias:alias andType:type andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:nil];
    
    if ([self.linkCache objectForKey:linkData]) {
        if (callback) {
            callback([self.linkCache objectForKey:linkData], nil);
        }
        return;
    }
    
    BranchShortUrlRequest *req = [[BranchShortUrlRequest alloc] initWithTags:tags alias:alias type:type matchDuration:duration channel:channel feature:feature stage:stage params:params linkData:linkData linkCache:self.linkCache callback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}

- (NSString *)generateShortUrl:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSDictionary *)params ignoreUAString:(NSString *)ignoreUAString forceLinkCreation:(BOOL)forceLinkCreation {
    NSString *shortURL = nil;
    
    BNCLinkData *linkData = [self prepareLinkDataFor:tags andAlias:alias andType:type andMatchDuration:duration andChannel:channel andFeature:feature andStage:stage andParams:params ignoreUAString:ignoreUAString];
    
    // If an ignore UA string is present, we always get a new url. Otherwise, if we've already seen this request, use the cached version
    if (!ignoreUAString && [self.linkCache objectForKey:linkData]) {
        shortURL = [self.linkCache objectForKey:linkData];
    }
    else {
        BranchShortUrlSyncRequest *req = [[BranchShortUrlSyncRequest alloc] initWithTags:tags alias:alias type:type matchDuration:duration channel:channel feature:feature stage:stage params:params linkData:linkData linkCache:self.linkCache];
        
        if (self.isInitialized) {
            [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"Created custom url synchronously"];
            BNCServerResponse *serverResponse = [req makeRequest:self.bServerInterface key:self.branchKey];
            shortURL = [req processResponse:serverResponse];
            
            // cache the link
            if (shortURL) {
                [self.linkCache setObject:shortURL forKey:linkData];
            }
        }
        else {
            if (forceLinkCreation) {
                if (self.branchKey) {
                    return [BranchShortUrlSyncRequest createLinkFromBranchKey:self.branchKey tags:tags alias:alias type:type matchDuration:duration channel:channel feature:feature stage:stage params:params];
                }
            }
            NSLog(@"Branch SDK Error: making request before init succeeded!");
        }
    }
    
    return shortURL;
}

- (NSString *)generateLongURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    NSString *baseLongUrl = [NSString stringWithFormat:@"%@/a/%@", BNC_LINK_URL, self.branchKey];
    
    return [self longUrlWithBaseUrl:baseLongUrl params:params tags:tags feature:feature channel:nil stage:stage alias:alias duration:0 type:BranchLinkTypeUnlimitedUse];
}

- (NSString *)longUrlWithBaseUrl:(NSString *)baseUrl params:(NSDictionary *)params tags:(NSArray *)tags feature:(NSString *)feature channel:(NSString *)channel stage:(NSString *)stage alias:(NSString *)alias duration:(NSUInteger)duration type:(BranchLinkType)type {
    NSMutableString *longUrl = [[NSMutableString alloc] initWithFormat:@"%@?", baseUrl];
    
    for (NSString *tag in tags) {
        [longUrl appendFormat:@"tags=%@&", tag];
    }
    
    if ([alias length]) {
        [longUrl appendFormat:@"alias=%@&", alias];
    }
    
    if ([channel length]) {
        [longUrl appendFormat:@"channel=%@&", channel];
    }
    
    if ([feature length]) {
        [longUrl appendFormat:@"feature=%@&", feature];
    }
    
    if ([stage length]) {
        [longUrl appendFormat:@"stage=%@&", stage];
    }
    
    [longUrl appendFormat:@"type=%ld&", (long)type];
    [longUrl appendFormat:@"matchDuration=%ld&", (long)duration];
    
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", base64EncodedParams];
    
    return longUrl;
}

- (BNCLinkData *)prepareLinkDataFor:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andMatchDuration:(NSUInteger)duration andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSDictionary *)params ignoreUAString:(NSString *)ignoreUAString {
    BNCLinkData *post = [[BNCLinkData alloc] init];
    
    [post setupType:type];
    [post setupTags:tags];
    [post setupChannel:channel];
    [post setupFeature:feature];
    [post setupStage:stage];
    [post setupAlias:alias];
    [post setupMatchDuration:duration];
    [post setupIgnoreUAString:ignoreUAString];
    [post setupParams:params];
    
    return post;
}


#pragma mark - BranchUniversalObject methods

- (void)registerViewWithParams:(NSDictionary *)params andCallback:(callbackWithParams)callback {
    [self initSessionIfNeededAndNotInProgress];
    
    BranchRegisterViewRequest *req = [[BranchRegisterViewRequest alloc] initWithParams:params andCallback:callback];
    [self.requestQueue enqueue:req];
    [self processNextQueueItem];
}


#pragma mark - Application State Change methods

- (void)applicationDidBecomeActive {
    if (!self.isInitialized && !self.preferenceHelper.isContinuingUserActivity && ![self.requestQueue containsInstallOrOpen]) {
        [self initUserSessionAndCallCallback:YES];
    }
}

- (void)applicationWillResignActive {
    [self clearTimer];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(callClose) userInfo:nil repeats:NO];
    [self.requestQueue persistImmediately];
    
    if (self.debugGestureRecognizer) {
        [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:self.debugGestureRecognizer];
    }
}

- (void)clearTimer {
    [self.sessionTimer invalidate];
}

- (void)callClose {
    if (self.isInitialized) {
        self.isInitialized = NO;
        
        if (self.preferenceHelper.sessionID && ![self.requestQueue containsClose]) {
            BranchCloseRequest *req = [[BranchCloseRequest alloc] init];
            [self.requestQueue enqueue:req];
        }
        
        [self processNextQueueItem];
    }
}


#pragma mark - Queue management

- (void)insertRequestAtFront:(BNCServerRequest *)req {
    if (self.networkCount == 0) {
        [self.requestQueue insert:req at:0];
    }
    else {
        [self.requestQueue insert:req at:1];
    }
}

- (void)processNextQueueItem {
    dispatch_semaphore_wait(self.processing_sema, DISPATCH_TIME_FOREVER);
    
    if (self.networkCount == 0 && self.requestQueue.size > 0) {
        self.networkCount = 1;
        dispatch_semaphore_signal(self.processing_sema);
        
        BNCServerRequest *req = [self.requestQueue peek];
        
        if (req) {
            BNCServerCallback callback = ^(BNCServerResponse *response, NSError *error) {
                // If the request was successful, or was a bad user request, continue processing.
                if (!error || error.code == BNCBadRequestError || error.code == BNCDuplicateResourceError) {
                    [req processResponse:response error:error];
                    
                    [self.requestQueue dequeue];
                    self.networkCount = 0;
                    [self processNextQueueItem];
                }
                // On network problems, or Branch down, call the other callbacks and stop processing.
                else {
                    // First, gather all the requests to fail
                    NSMutableArray *requestsToFail = [[NSMutableArray alloc] init];
                    for (int i = 0; i < self.requestQueue.size; i++) {
                        [requestsToFail addObject:[self.requestQueue peekAt:i]];
                    }
                    
                    // Next, remove all the requests that should not be replayed. Note, we do this before calling callbacks, in case any
                    // of the callbacks try to kick off another request, which could potentially start another request (and call these callbacks again)
                    for (BNCServerRequest *request in requestsToFail) {
                        if (![request isKindOfClass:[BranchUserCompletedActionRequest class]] && ![request isKindOfClass:[BranchSetIdentityRequest class]]) {
                            [self.requestQueue remove:request];
                        }
                    }
                    
                    // Then, set the network count to zero, indicating that requests can be started again
                    self.networkCount = 0;
                    
                    // Finally, call all the requests callbacks with the error
                    for (BNCServerRequest *request in requestsToFail) {
                        [request processResponse:nil error:error];
                    }
                }
            };
            
            if (![req isKindOfClass:[BranchInstallRequest class]] && !self.preferenceHelper.identityID) {
                NSLog(@"[Branch Error] User session has not been initialized!");
                [req processResponse:nil error:[NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"Branch User Session has not been initialized" }]];
                return;
            }
            else if (![req isKindOfClass:[BranchOpenRequest class]] && (!self.preferenceHelper.deviceFingerprintID || !self.preferenceHelper.sessionID)) {
                NSLog(@"[Branch Error] Missing session items!");
                [req processResponse:nil error:[NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"Branch User Session has not been initialized" }]];
                return;
            }
            
            if (![req isKindOfClass:[BranchCloseRequest class]]) {
                [self clearTimer];
            }
            
            [req makeRequest:self.bServerInterface key:self.branchKey callback:callback];
        }
    }
    else {
        dispatch_semaphore_signal(self.processing_sema);
    }
}


#pragma mark - Session Initialization

- (void)initSessionIfNeededAndNotInProgress {
    if (!self.isInitialized && !self.preferenceHelper.isContinuingUserActivity && ![self.requestQueue containsInstallOrOpen]) {
        [self initUserSessionAndCallCallback:NO];
    }
}

- (void)initUserSessionAndCallCallback:(BOOL)callCallback {
    self.shouldCallSessionInitCallback = callCallback;
    
    // If the session is not yet initialized
    if (!self.isInitialized) {
        [self initializeSession];
    }
    // If the session was initialized, but callCallback was specified, do so.
    else if (callCallback) {
        if (self.sessionInitWithParamsCallback) {
            self.sessionInitWithParamsCallback([self getLatestReferringParams], nil);
        }
        else if (self.sessionInitWithBranchUniversalObjectCallback) {
            self.sessionInitWithBranchUniversalObjectCallback([self getLatestReferringBranchUniversalObject], [self getLatestReferringBranchLinkProperties], nil);
        }
    }
}

- (void)initializeSession {
    if (!self.branchKey) {
        NSLog(@"[Branch Warning] Please enter your branch_key in the plist!");
        return;
    }
    else if ([self.branchKey rangeOfString:@"key_test_"].location != NSNotFound) {
        NSLog(@"[Branch Warning] You are using your test app's Branch Key. Remember to change it to live Branch Key for deployment.");
    }
    
    if (!self.preferenceHelper.identityID) {
        [self registerInstallOrOpen:[BranchInstallRequest class]];
    }
    else {
        [self registerInstallOrOpen:[BranchOpenRequest class]];
    }
}

- (void)registerInstallOrOpen:(Class)clazz {
    callbackWithStatus initSessionCallback = ^(BOOL success, NSError *error) {
        if (error) {
            [self handleInitFailure:error];
        }
        else {
            [self handleInitSuccess];
        }
    };
    
    if ([BNCSystemObserver getOSVersion].integerValue >= 9 && self.useCookieBasedMatching) {
        [[BNCStrongMatchHelper strongMatchHelper] createStrongMatchWithBranchKey:self.branchKey];
    }
    
    // If there isn't already an Open / Install request, add one to the queue
    if (![self.requestQueue containsInstallOrOpen]) {
        BranchOpenRequest *req = [[clazz alloc] initWithCallback:initSessionCallback];
        
        [self insertRequestAtFront:req];
    }
    // If there is already one in the queue, make sure it's in the front.
    // Make sure a callback is associated with this request. This callback can
    // be cleared if the app is terminated while an Open/Install is pending.
    else {
        BranchOpenRequest *req = [self.requestQueue moveInstallOrOpenToFront:self.networkCount];
        req.callback = initSessionCallback;
    }
    
    [self processNextQueueItem];
}

- (void)handleInitSuccess {
    self.isInitialized = YES;
    
    NSDictionary *latestReferringParams = [self getLatestReferringParams];
    if (self.shouldCallSessionInitCallback) {
        if (self.sessionInitWithParamsCallback) {
            self.sessionInitWithParamsCallback(latestReferringParams, nil);
        }
        else if (self.sessionInitWithBranchUniversalObjectCallback) {
            self.sessionInitWithBranchUniversalObjectCallback([self getLatestReferringBranchUniversalObject], [self getLatestReferringBranchLinkProperties], nil);
        }
    }
    
    if (self.shouldAutomaticallyDeepLink) {
        // Find any matched keys, then launch any controllers that match
        // TODO which one to launch if more than one match?
        NSMutableSet *keysInParams = [NSMutableSet setWithArray:[latestReferringParams allKeys]];
        NSSet *desiredKeysSet = [NSSet setWithArray:[self.deepLinkControllers allKeys]];
        [keysInParams intersectSet:desiredKeysSet];
        
        // If we find a matching key, configure and show the controller
        if ([keysInParams count]) {
            NSString *key = [[keysInParams allObjects] firstObject];
            UIViewController <BranchDeepLinkingController> *branchSharingController = self.deepLinkControllers[key];
            if ([branchSharingController respondsToSelector:@selector(configureControlWithData:)]) {
                [branchSharingController configureControlWithData:latestReferringParams];
            }
            else {
                [self.preferenceHelper log:FILE_NAME line:LINE_NUM message:@"[Branch Warning] View controller does not implement configureControlWithData:"];
            }
            branchSharingController.deepLinkingCompletionDelegate = self;
            self.deepLinkPresentingController = [[[UIApplication sharedApplication].delegate window] rootViewController];
            
            if ([self.deepLinkPresentingController presentedViewController]) {
                [self.deepLinkPresentingController dismissViewControllerAnimated:NO completion:^{
                    [self.deepLinkPresentingController presentViewController:branchSharingController animated:YES completion:NULL];
                }];
            }
            else {
                [self.deepLinkPresentingController presentViewController:branchSharingController animated:YES completion:NULL];
            }
        }
    }
}

- (void)handleInitFailure:(NSError *)error {
    self.isInitialized = NO;
    
    if (self.shouldCallSessionInitCallback) {
        if (self.sessionInitWithParamsCallback) {
            self.sessionInitWithParamsCallback(nil, error);
        }
        else if (self.sessionInitWithBranchUniversalObjectCallback) {
            self.sessionInitWithBranchUniversalObjectCallback(nil, nil, error);
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - BranchDeepLinkingControllerCompletionDelegate methods

- (void)deepLinkingControllerCompleted {
    [self.deepLinkPresentingController dismissViewControllerAnimated:YES completion:NULL];
}


@end

//
//  Branch_SDK.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchServerInterface.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequest.h"
#import "BNCServerResponse.h"
#import "BNCSystemObserver.h"
#import "BNCServerRequestQueue.h"
#import "BNCConfig.h"
#import "BNCError.h"
#import "BNCLinkData.h"
#import "BNCLinkCache.h"


static NSString *APP_ID = @"app_id";
static NSString *IDENTITY = @"identity";
static NSString *IDENTITY_ID = @"identity_id";
static NSString *SESSION_ID = @"session_id";
static NSString *BUCKET = @"bucket";
static NSString *AMOUNT = @"amount";
static NSString *EVENT = @"event";
static NSString *METADATA = @"metadata";
static NSString *TOTAL = @"total";
static NSString *UNIQUE = @"unique";
static NSString *MESSAGE = @"message";
static NSString *ERROR = @"error";
static NSString *DEVICE_FINGERPRINT_ID = @"device_fingerprint_id";
static NSString *LINK = @"link";
static NSString *LINK_CLICK_ID = @"link_click_id";
static NSString *URL = @"url";
static NSString *REFERRING_DATA = @"referring_data";
static NSString *REFERRER = @"referrer";
static NSString *REFERREE = @"referree";
static NSString *CREDIT = @"credit";

static NSString *LENGTH = @"length";
static NSString *BEGIN_AFTER_ID = @"begin_after_id";
static NSString *DIRECTION = @"direction";

static NSString *REDEEM_CODE = @"$redeem_code";
static NSString *REFERRAL_CODE = @"referral_code";
static NSString *REFERRAL_CODE_CALCULATION_TYPE = @"calculation_type";
static NSString *REFERRAL_CODE_LOCATION = @"location";
static NSString *REFERRAL_CODE_TYPE = @"type";
static NSString *REFERRAL_CODE_PREFIX = @"prefix";
static NSString *REFERRAL_CODE_CREATION_SOURCE = @"creation_source";
static NSString *REFERRAL_CODE_EXPIRATION = @"expiration";

static NSInteger REFERRAL_CREATION_SOURCE_SDK = 2;

static int BNCDebugTriggerDuration = 2.9;
static int BNCDebugTriggerFingers = 4;
static int BNCDebugTriggerFingersSimulator = 2;
static dispatch_queue_t bnc_asyncDebugQueue = nil;
static NSTimer *bnc_debugTimer = nil;
static UILongPressGestureRecognizer *BNCLongPress = nil;


#define DIRECTIONS @[@"desc", @"asc"]



@interface Branch() <BNCServerInterfaceDelegate, BNCDebugConnectionDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) BranchServerInterface *bServerInterface;

@property (nonatomic) BOOL isInit;

@property (strong, nonatomic) NSTimer *sessionTimer;
@property (strong, nonatomic) BNCServerRequestQueue *requestQueue;
@property (nonatomic) dispatch_semaphore_t processing_sema;
@property (nonatomic) dispatch_queue_t asyncQueue;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger networkCount;
@property (strong, nonatomic) callbackWithStatus pointLoadCallback;
@property (strong, nonatomic) callbackWithStatus rewardLoadCallback;
@property (strong, nonatomic) callbackWithParams sessionparamLoadCallback;
@property (strong, nonatomic) callbackWithParams installparamLoadCallback;
@property (strong, nonatomic) callbackWithUrl urlLoadCallback;
@property (strong, nonatomic) callbackWithList creditHistoryLoadCallback;
@property (strong, nonatomic) callbackWithParams getReferralCodeCallback;
@property (strong, nonatomic) callbackWithParams validateReferralCodeCallback;
@property (strong, nonatomic) callbackWithParams applyReferralCodeCallback;
@property (assign, nonatomic) BOOL initFinished;
@property (assign, nonatomic) BOOL initFailed;
@property (assign, nonatomic) BOOL initNotCalled;
@property (assign, nonatomic) BOOL lastRequestWasInit;
@property (assign, nonatomic) BOOL hasNetwork;
@property (strong, nonatomic) BNCLinkCache *linkCache;

@end

@implementation Branch

static Branch *currInstance;

// PUBLIC CALLS

+ (Branch *)getInstance {
    if (!currInstance) {
        NSString *appKey = [BNCPreferenceHelper getAppKey];
        if (!appKey || [appKey isEqualToString:NO_STRING_VALUE]) {
            NSLog(@"Branch Warning: Please enter your Branch App Key in the plist!");
        }
        
        [Branch initInstance];
    }
    return currInstance;
}

+ (Branch *)getInstance:(NSString *)appKey {
    [BNCPreferenceHelper setAppKey:appKey];
    
    if (!currInstance) {
        [Branch initInstance];
    }
    
    return currInstance;
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                   andParams:(NSDictionary *)params
                                                     andTags:(NSArray *)tags
                                                  andFeature:(NSString *)feature
                                                    andStage:(NSString *)stage
                                                    andAlias:(NSString *)alias {
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:tags andFeature:feature andStage:stage andAlias:alias];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                          andParams:(NSDictionary *)params {
    
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:nil andFeature:nil andStage:nil andAlias:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                          andParams:(NSDictionary *)params
                                                         andFeature:(NSString *)feature {
    
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:nil andFeature:feature andStage:nil andAlias:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                          andParams:(NSDictionary *)params
                                                         andFeature:(NSString *)feature
                                                           andStage:(NSString *)stage {
    
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:nil andFeature:feature andStage:stage andAlias:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                          andParams:(NSDictionary *)params
                                                         andFeature:(NSString *)feature
                                                           andStage:(NSString *)stage
                                                            andTags:(NSArray *)tags {
    
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:tags andFeature:feature andStage:stage andAlias:nil];
}

+ (BranchActivityItemProvider *)getBranchActivityItemWithDefaultURL:(NSString *)url
                                                          andParams:(NSDictionary *)params
                                                            andFeature:(NSString *)feature
                                                           andStage:(NSString *)stage
                                                           andAlias:(NSString *)alias {
    
    return [[BranchActivityItemProvider alloc] initWithDefaultURL:url andParams:params andTags:nil andFeature:feature andStage:stage andAlias:alias];
}

+ (void)initInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currInstance = [[Branch alloc] init];
        currInstance.isInit = NO;
        currInstance.bServerInterface = [[BranchServerInterface alloc] init];
        currInstance.bServerInterface.delegate = currInstance;
        currInstance.processing_sema = dispatch_semaphore_create(1);
        currInstance.asyncQueue = dispatch_queue_create("brnch_request_queue", NULL);
        currInstance.requestQueue = [BNCServerRequestQueue getInstance];
        currInstance.initFinished = NO;
        currInstance.initFailed = NO;
        currInstance.hasNetwork = YES;
        currInstance.initNotCalled = YES;
        currInstance.lastRequestWasInit = YES;
        currInstance.linkCache = [[BNCLinkCache alloc] init];
    
        [[NSNotificationCenter defaultCenter] addObserver:currInstance
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
        [[NSNotificationCenter defaultCenter] addObserver:currInstance
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
        currInstance.retryCount = 0;
        currInstance.networkCount = 0;
    });
}

+ (void)setDebug {
    [BNCPreferenceHelper setDevDebug];
}

- (void)resetUserSession {
    if (self) {
        self.isInit = NO;
    }
}

- (void)setNetworkTimeout:(NSInteger)timeout {
    if (self) {
        [BNCPreferenceHelper setTimeout:timeout];
    }
}

- (void)setMaxRetries:(NSInteger)maxRetries {
    if (self) {
        [BNCPreferenceHelper setRetryCount:maxRetries];
    }
}

- (void)setRetryInterval:(NSInteger)retryInterval {
    if (self) {
        [BNCPreferenceHelper setRetryInterval:retryInterval];
    }
}

- (void)initSession {
    [self initSessionAndRegisterDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options {
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
        [self initSessionAndRegisterDeepLinkHandler:nil];
    }
}

- (void)initSession:(BOOL)isReferrable {
    [self initSession:isReferrable andRegisterDeepLinkHandler:nil];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options andRegisterDeepLinkHandler:(callbackWithParams)callback {
    self.sessionparamLoadCallback = callback;
    if (![BNCSystemObserver getUpdateState] && ![self hasUser]) {
        [BNCPreferenceHelper setIsReferrable];
    } else {
        [BNCPreferenceHelper clearIsReferrable];
    }
    
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
        [self initUserSessionWithCallbackInternal:callback];
    }
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable {
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
        [self initSession:isReferrable andRegisterDeepLinkHandler:nil];
    }
}

- (void)initSession:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback {
    if (isReferrable) {
        [BNCPreferenceHelper setIsReferrable];
    } else {
        [BNCPreferenceHelper clearIsReferrable];
    }
    
    [self initUserSessionWithCallbackInternal:callback];
}

- (void)initSessionWithLaunchOptions:(NSDictionary *)options isReferrable:(BOOL)isReferrable andRegisterDeepLinkHandler:(callbackWithParams)callback {
    self.sessionparamLoadCallback = callback;
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey]) {
        [self initSession:isReferrable andRegisterDeepLinkHandler:callback];
    }
}

- (void)initSessionAndRegisterDeepLinkHandler:(callbackWithParams)callback {
    if (![BNCSystemObserver getUpdateState] && ![self hasUser]) {
        [BNCPreferenceHelper setIsReferrable];
    } else {
        [BNCPreferenceHelper clearIsReferrable];
    }
    
    [self initUserSessionWithCallbackInternal:callback];
}

- (void)initUserSessionWithCallbackInternal:(callbackWithParams)callback {
    self.sessionparamLoadCallback = callback;
    self.lastRequestWasInit = YES;
    self.initFailed = NO;
    self.initNotCalled = NO;
    if (!self.isInit) {
        self.isInit = YES;
        [self initializeSession];
    } else if ([self hasUser] && [self hasSession] && ![self.requestQueue containsInstallOrOpen]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getLatestReferringParams], nil);
    } else {
        if (![self.requestQueue containsInstallOrOpen]) {
            [self initializeSession];
        } else {
            dispatch_async(self.asyncQueue, ^{
                [self processNextQueueItem];
            });
        }
    }
}

- (BOOL)handleDeepLink:(NSURL *)url {
    BOOL handled = NO;
    if (url) {
        NSString *query = [url fragment];
        if (!query) {
            query = [url query];
        }
        NSDictionary *params = [self parseURLParams:query];
        if ([params objectForKey:@"link_click_id"]) {
            handled = YES;
            [BNCPreferenceHelper setLinkClickIdentifier:[params objectForKey:@"link_click_id"]];
        }
    }
    [BNCPreferenceHelper setIsReferrable];
    [self initUserSessionWithCallbackInternal:self.sessionparamLoadCallback];
    return handled;
}

- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback {
    self.installparamLoadCallback = callback;
    [self setIdentity:userId];
}

- (void)setIdentity:(NSString *)userId {
    if (!userId || [[BNCPreferenceHelper getUserIdentity] isEqualToString:userId])
        return;

    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_IDENTIFY;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[
                                                                                   userId,
                                                                                   [BNCPreferenceHelper getAppKey],
                                                                                   [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                   [BNCPreferenceHelper getSessionID],
                                                                                   [BNCPreferenceHelper getIdentityID],
                                                                                   [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                         forKeys:@[
                                                                                   IDENTITY,
                                                                                   APP_ID,
                                                                                   DEVICE_FINGERPRINT_ID,
                                                                                   SESSION_ID,
                                                                                   IDENTITY_ID,
                                                                                   @"sdk"]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)logout {
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[
                                                                                   [BNCPreferenceHelper getAppKey],
                                                                                   [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                   [BNCPreferenceHelper getSessionID],
                                                                                   [BNCPreferenceHelper getIdentityID],
                                                                                   [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                         forKeys:@[
                                                                                   APP_ID,
                                                                                   DEVICE_FINGERPRINT_ID,
                                                                                   SESSION_ID,
                                                                                   IDENTITY_ID,
                                                                                   @"sdk"]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback {
    self.pointLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_COUNTS;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[
                                                                                   [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                         forKeys:@[
                                                                                   @"sdk"]];
        req.postData = post;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)loadRewardsWithCallback:(callbackWithStatus)callback {
    self.rewardLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"ios%@", SDK_VERSION]] forKeys:@[@"sdk"]];
        req.postData = post;
        req.tag = REQ_TAG_GET_REWARDS;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (NSInteger)getCredits {
    return [BNCPreferenceHelper getCreditCount];
}

- (void)redeemRewards:(NSInteger)count {
    [self redeemRewards:count forBucket:@"default"];
}

- (NSInteger)getCreditsForBucket:(NSString *)bucket {
    return [BNCPreferenceHelper getCreditCountForBucket:bucket];
}

- (NSInteger)getTotalCountsForAction:(NSString *)action {
    return [BNCPreferenceHelper getActionTotalCount:action];
}
- (NSInteger)getUniqueCountsForAction:(NSString *)action {
    return [BNCPreferenceHelper getActionUniqueCount:action];
}

- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket {
    dispatch_async(self.asyncQueue, ^{
        NSInteger redemptionsToAdd = 0;
        NSInteger credits = [BNCPreferenceHelper getCreditCountForBucket:bucket];
        if (count > credits) {
            redemptionsToAdd = credits;
            NSLog(@"Branch Warning: You're trying to redeem more credits than are available. Have you updated loaded rewards");
        } else {
            redemptionsToAdd = count;
        }
        
        if (redemptionsToAdd > 0) {
            BNCServerRequest *req = [[BNCServerRequest alloc] init];
            req.tag = REQ_TAG_REDEEM_REWARDS;
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[
                                                                                       bucket,
                                                                                       [NSNumber numberWithInteger:redemptionsToAdd],
                                                                                       [BNCPreferenceHelper getAppKey],
                                                                                       [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                       [BNCPreferenceHelper getIdentityID],
                                                                                       [BNCPreferenceHelper getSessionID],
                                                                                       [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                             forKeys:@[
                                                                                       BUCKET,
                                                                                       AMOUNT,
                                                                                       APP_ID,
                                                                                       DEVICE_FINGERPRINT_ID,
                                                                                       IDENTITY_ID,
                                                                                       SESSION_ID,
                                                                                       @"sdk"]];
            req.postData = post;
            [self.requestQueue enqueue:req];
            
            if (self.initFinished || !self.hasNetwork) {
                self.lastRequestWasInit = NO;
                [self processNextQueueItem];
            } else if (self.initFailed || self.initNotCalled) {
                [self handleFailure:[self.requestQueue size]-1];
            }
        }
    });
    
}

- (void)getCreditHistoryWithCallback:(callbackWithList)callback {
    [self getCreditHistoryAfter:nil number:100 order:BranchMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:bucket after:nil number:100 order:BranchMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryAfter:(NSString *)creditTransactionId number:(NSInteger)length order:(CreditHistoryOrder)order andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:nil after:creditTransactionId number:length order:order andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket after:(NSString *)creditTransactionId number:(NSInteger)length order:(CreditHistoryOrder)order andCallback:(callbackWithList)callback {
    self.creditHistoryLoadCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARD_HISTORY;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjects:@[
                                                                                 [BNCPreferenceHelper getAppKey],
                                                                                 [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                 [BNCPreferenceHelper getIdentityID],
                                                                                 [BNCPreferenceHelper getSessionID],
                                                                                 [NSNumber numberWithLong:length],
                                                                                 DIRECTIONS[order],
                                                                                 [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                       forKeys:@[APP_ID,
                                                                                 DEVICE_FINGERPRINT_ID,
                                                                                 IDENTITY_ID,
                                                                                 SESSION_ID,
                                                                                 LENGTH,
                                                                                 DIRECTION,
                                                                                 @"sdk"]];
        if (bucket) {
            [data setObject:bucket forKey:BUCKET];
        }
        if (creditTransactionId) {
            [data setObject:creditTransactionId forKey:BEGIN_AFTER_ID];
        }
        req.postData = data;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)userCompletedAction:(NSString *)action {
    [self userCompletedAction:action withState:nil];
}

- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state {
    if (!action)
        return;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_COMPLETE_ACTION;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[
                                                                                   action,
                                                                                   [BNCPreferenceHelper getAppKey],
                                                                                   [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                   [BNCPreferenceHelper getIdentityID],
                                                                                   [BNCPreferenceHelper getSessionID],
                                                                                   [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                         forKeys:@[
                                                                                   EVENT,
                                                                                   APP_ID,
                                                                                   DEVICE_FINGERPRINT_ID,
                                                                                   IDENTITY_ID,
                                                                                   SESSION_ID,
                                                                                   @"sdk"]];
        NSDictionary *saniState = [self sanitizeQuotesFromInput:state];
        if (saniState && [NSJSONSerialization isValidJSONObject:saniState]) [post setObject:saniState forKey:METADATA];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (NSDictionary *)getFirstReferringParams {
    NSString *storedParam = [BNCPreferenceHelper getInstallParams];
    return [self convertParamsStringToDictionary:storedParam];
}

- (NSDictionary *)getLatestReferringParams {
    NSString *storedParam = [BNCPreferenceHelper getSessionParams];
    return [self convertParamsStringToDictionary:storedParam];
}

- (NSString *)getShortURL {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:nil andFeature:nil andStage:nil andParams:nil];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:nil andFeature:nil andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:tags andAlias:nil andType:type andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type {
    return [self generateShortUrl:nil andAlias:nil andType:type andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}

- (NSString *)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature {
    return [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]];
}


- (void)getShortURLWithCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:nil andFeature:nil andStage:nil andParams:nil andCallback:callback];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:nil andFeature:nil andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:alias andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andAlias:nil andType:type andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:alias andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andType:(BranchLinkType)type andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:type andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andAlias:nil andType:BranchLinkTypeUnlimitedUse andChannel:channel andFeature:feature andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getReferralCodeWithCallback:(callbackWithParams)callback {
    self.getReferralCodeCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_CODE;
        NSMutableArray *keys = [NSMutableArray arrayWithArray:@[APP_ID,
                                                                DEVICE_FINGERPRINT_ID,
                                                                IDENTITY_ID,
                                                                SESSION_ID,
                                                                @"sdk"]];
        NSMutableArray *values = [NSMutableArray arrayWithArray:@[[BNCPreferenceHelper getAppKey],
                                                                  [BNCPreferenceHelper getDeviceFingerprintID],
                                                                  [BNCPreferenceHelper getIdentityID],
                                                                  [BNCPreferenceHelper getSessionID],
                                                                  [NSString stringWithFormat:@"ios%@", SDK_VERSION]]];
        
        NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
        req.postData = post;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)getReferralCodeWithAmount:(NSInteger)amount andCallback:(callbackWithParams)callback {
    [self getReferralCodeWithPrefix:nil amount:amount expiration:nil bucket:@"default" calculationType:BranchUnlimitedRewards location:BranchReferringUser andCallback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount andCallback:(callbackWithParams)callback {
    [self getReferralCodeWithPrefix:prefix amount:amount expiration:nil bucket:@"default" calculationType:BranchUnlimitedRewards location:BranchReferringUser andCallback:callback];
}

- (void)getReferralCodeWithAmount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback {
    [self getReferralCodeWithPrefix:nil amount:amount expiration:expiration bucket:@"default" calculationType:BranchUnlimitedRewards location:BranchReferringUser andCallback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration andCallback:(callbackWithParams)callback {
    [self getReferralCodeWithPrefix:prefix amount:amount expiration:expiration bucket:@"default" calculationType:BranchUnlimitedRewards location:BranchReferringUser andCallback:callback];
}

- (void)getReferralCodeWithPrefix:(NSString *)prefix amount:(NSInteger)amount expiration:(NSDate *)expiration bucket:(NSString *)bucket calculationType:(ReferralCodeCalculation)calcType location:(ReferralCodeLocation)location andCallback:(callbackWithParams)callback
{
    self.getReferralCodeCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_CODE;
        NSMutableArray *keys = [NSMutableArray arrayWithArray:@[APP_ID,
                                                                DEVICE_FINGERPRINT_ID,
                                                                IDENTITY_ID,
                                                                SESSION_ID,
                                                                REFERRAL_CODE_CALCULATION_TYPE,
                                                                REFERRAL_CODE_LOCATION,
                                                                REFERRAL_CODE_TYPE,
                                                                REFERRAL_CODE_CREATION_SOURCE,
                                                                AMOUNT,
                                                                BUCKET,
                                                                @"sdk"]];
        NSMutableArray *values = [NSMutableArray arrayWithArray:@[[BNCPreferenceHelper getAppKey],
                                                                  [BNCPreferenceHelper getDeviceFingerprintID],
                                                                  [BNCPreferenceHelper getIdentityID],
                                                                  [BNCPreferenceHelper getSessionID],
                                                                  [NSNumber numberWithLong:calcType],
                                                                  [NSNumber numberWithLong:location],
                                                                  CREDIT,
                                                                  [NSNumber numberWithLong:REFERRAL_CREATION_SOURCE_SDK],
                                                                  [NSNumber numberWithLong:amount],
                                                                  bucket,
                                                                  [NSString stringWithFormat:@"ios%@", SDK_VERSION]]];
        if (prefix && prefix.length > 0) {
            [keys addObject:REFERRAL_CODE_PREFIX];
            [values addObject:prefix];
        }
        if (expiration) {
            [keys addObject:REFERRAL_CODE_EXPIRATION];
            [values addObject:[self convertDate:expiration]];
        }
        
        NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
        req.postData = post;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (NSString *)convertDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:date];
}

- (void)validateReferralCode:(NSString *)code andCallback:(callbackWithParams)callback {
    self.validateReferralCodeCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_VALIDATE_REFERRAL_CODE;
        NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObjects:@[code,
                                                                                 [BNCPreferenceHelper getIdentityID],
                                                                                 [BNCPreferenceHelper getAppKey],
                                                                                 [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                 [BNCPreferenceHelper getSessionID],
                                                                                 [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                       forKeys:@[
                                                                                 REFERRAL_CODE,
                                                                                 IDENTITY_ID,
                                                                                 APP_ID,
                                                                                 DEVICE_FINGERPRINT_ID,
                                                                                 SESSION_ID,
                                                                                 @"sdk"]];
        req.postData = post;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

- (void)applyReferralCode:(NSString *)code andCallback:(callbackWithParams)callback {
    self.applyReferralCodeCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_APPLY_REFERRAL_CODE;
        NSMutableDictionary *post = [NSMutableDictionary dictionaryWithObjects:@[code,
                                                                                 [BNCPreferenceHelper getIdentityID],
                                                                                 [BNCPreferenceHelper getAppKey],
                                                                                 [BNCPreferenceHelper getSessionID],
                                                                                 [BNCPreferenceHelper getDeviceFingerprintID],
                                                                                 [NSString stringWithFormat:@"ios%@", SDK_VERSION]]
                                                                       forKeys:@[REFERRAL_CODE,
                                                                                 IDENTITY_ID,
                                                                                 APP_ID,
                                                                                 SESSION_ID,
                                                                                 DEVICE_FINGERPRINT_ID,
                                                                                 @"sdk"]];
        req.postData = post;
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    });
}

// PRIVATE CALLS

- (void)generateShortUrl:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSString *)params andCallback:(callbackWithUrl)callback {
    
    BNCServerRequest *req = [[BNCServerRequest alloc] init];
    req.tag = REQ_TAG_GET_CUSTOM_URL;
    BNCLinkData *post = [self prepareLinkDataFor:tags andAlias:alias andType:type andChannel:channel andFeature:feature andStage:stage andParams:params];
    
    if (![self.linkCache objectForKey:post]) {
        self.urlLoadCallback = callback;
        
        dispatch_async(self.asyncQueue, ^{
            req.postData = post.data;
            req.linkData = post;
            
            if (!self.initFailed) {
                [self.requestQueue enqueue:req];
            }
            
            if (self.initFinished || !self.hasNetwork) {
                self.lastRequestWasInit = NO;
                [self processNextQueueItem];
            } else if (self.initFailed || self.initNotCalled) {
                [self handleFailure:[self.requestQueue size]-1];
            }
        });
    } else if (callback) {
        callback([self.linkCache objectForKey:post], nil);
    }
}

- (NSString *)generateShortUrl:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSString *)params {
    NSString *shortURL = nil;
    
    BNCServerRequest *req = [[BNCServerRequest alloc] init];
    req.tag = REQ_TAG_GET_CUSTOM_URL;
    BNCLinkData *post = [self prepareLinkDataFor:tags andAlias:alias andType:type andChannel:channel andFeature:feature andStage:stage andParams:params];
    
    if ([self.linkCache objectForKey:post]) {
        shortURL = [self.linkCache objectForKey:post];
    } else {
        req.postData = post.data;
        req.linkData = post;
        
        if (self.initFinished && self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Created custom url synchronously"];
            BNCServerResponse * serverResponse = [self.bServerInterface createCustomUrlSynchronous:req];
            shortURL = [serverResponse.data objectForKey:URL];
            
            // cache the link
            BNCLinkData *linkData = serverResponse.linkData;
            if (linkData) {
                [self.linkCache setObject:shortURL forKey:linkData];
            }
        } else if (self.initFailed || self.initNotCalled) {
            NSLog(@"Branch SDK Error: making request before init succeeded!");
        }
    }
    
    return shortURL;
}

- (BNCLinkData *)prepareLinkDataFor:(NSArray *)tags andAlias:(NSString *)alias andType:(BranchLinkType)type andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSString *)params {
    BNCLinkData *post = [[BNCLinkData alloc] init];
    [post setObject:[BNCPreferenceHelper getAppKey] forKey:APP_ID];
    [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:DEVICE_FINGERPRINT_ID];
    [post setObject:[BNCPreferenceHelper getIdentityID] forKey:IDENTITY_ID];
    [post setObject:[BNCPreferenceHelper getSessionID] forKey:SESSION_ID];
    
    [post setupType:type];
    [post setupTags:tags];
    [post setupChannel:channel];
    [post setupFeature:feature];
    [post setupStage:stage];
    [post setupAlias:alias];
    
    [post setObject:[NSString stringWithFormat:@"ios%@", SDK_VERSION] forKey:@"sdk"];
    
    NSString *args = params ? params : @"{ \"source\":\"ios\" }";
    [post setupParams:args];
    return post;
}

- (void)insertRequestAtFront:(BNCServerRequest *)req {
    if (self.networkCount == 0) {
        [self.requestQueue insert:req at:0];
    } else {
        [self.requestQueue insert:req at:1];
    }
}

- (void)applicationDidBecomeActive {
    if (!self.isInit) {
        self.initFailed = NO;
        self.initNotCalled = NO;
        self.lastRequestWasInit = YES;
        dispatch_async(self.asyncQueue, ^{
            self.isInit = YES;
            if (![self hasUser]) {
                [self registerInstallOrOpen:REQ_TAG_REGISTER_INSTALL];
            } else {
                [self registerInstallOrOpen:REQ_TAG_REGISTER_OPEN];
            }
        });
    }
    
    [self bnc_addDebugGestureRecognizer];
}

- (void)applicationWillResignActive {
    [self clearTimer];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(callClose) userInfo:nil repeats:NO];
    
    if (BNCLongPress) {
        [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:BNCLongPress];
    }
}

- (void)clearTimer {
    [self.sessionTimer invalidate];
}

- (void)callClose {
    self.isInit = NO;
    self.lastRequestWasInit = NO;
    self.initNotCalled = YES;
    if (!self.hasNetwork) {
        // if there's no network connectivity, purge the old install/open
        BNCServerRequest *req = [self.requestQueue peek];
        if (req && ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN])) {
            [self.requestQueue dequeue];
        }
    } else {
        if (![self.requestQueue containsClose]) {
            BNCServerRequest *req = [[BNCServerRequest alloc] initWithTag:REQ_TAG_REGISTER_CLOSE];
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"ios%@", SDK_VERSION]] forKeys:@[@"sdk"]];
            req.postData = post;
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            dispatch_async(self.asyncQueue, ^{
                [self processNextQueueItem];
            });
        } else if (self.initFailed || self.initNotCalled) {
            [self handleFailure:[self.requestQueue size]-1];
        }
    }
}

- (NSDictionary *)convertParamsStringToDictionary:(NSString *)paramsString {
    if (![paramsString isEqualToString:NO_STRING_VALUE]) {
        NSData *tempData = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *params = [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
        if (!params) {
            NSString *decodedVersion = [BNCPreferenceHelper base64DecodeStringToString:paramsString];
            tempData = [decodedVersion dataUsingEncoding:NSUTF8StringEncoding];
            params = [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
            if (!params) {
                params = [[NSDictionary alloc] init];
            }
        }
        return params;
    }
    return [[NSDictionary alloc] init];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count > 1) {
            NSString *val = [[kv objectAtIndex:1]
                             stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [params setObject:val forKey:[kv objectAtIndex:0]];
        }
    }
    return params;
}

- (NSDictionary *)sanitizeQuotesFromInput:(NSDictionary *)input {
    NSMutableDictionary *retDict = [[NSMutableDictionary alloc] init];
    [input enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]) {
            [retDict setObject:[[[[obj stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""] stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] stringByReplacingOccurrencesOfString:@"’" withString:@"'"] stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"] forKey:key];
        } else {
            [retDict setObject:obj forKey:key];
        }
    }];
    return retDict;
}

- (void)processListOfApps {
    dispatch_async(dispatch_queue_create("app_lister", NULL), ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_UPLOAD_LIST_OF_APPS;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
        [post setObject:[BNCPreferenceHelper getAppKey] forKey:APP_ID];
        [post setObject:[BNCPreferenceHelper getDeviceFingerprintID] forKey:DEVICE_FINGERPRINT_ID];
        [post setObject:[BNCSystemObserver getOS] forKey:@"os"];
        [post setObject:[NSString stringWithFormat:@"ios%@", SDK_VERSION] forKey:@"sdk"];
        [post setObject:[BNCSystemObserver getListOfApps] forKey:@"apps_data"];
        req.postData = post;
        
        if (!self.initFailed) {
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            self.lastRequestWasInit = NO;
            [self processNextQueueItem];
        }
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)processNextQueueItem {
    dispatch_semaphore_wait(self.processing_sema, DISPATCH_TIME_FOREVER);
    
    if (self.networkCount == 0 && self.requestQueue.size > 0) {
        self.networkCount = 1;
        dispatch_semaphore_signal(self.processing_sema);
        
        BNCServerRequest *req = [self.requestQueue peek];
        
        if (req) {
            if (![req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] && ![self hasUser]) {
                NSLog(@"Branch Error: User session has not been initialized!");
                self.networkCount = 0;
                [self handleFailure:[self.requestQueue size]-1];
                return;
            }
            
            if (![req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
                [self clearTimer];
            }
            
            if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling register install"];
                [self.bServerInterface registerInstall:[BNCPreferenceHelper isDebug]];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling register open"];
                [self.bServerInterface registerOpen:[BNCPreferenceHelper isDebug]];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling get referrals"];
                [self.bServerInterface getReferralCounts];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling get rewards"];
                [self.bServerInterface getRewards];
            } else if ([req.tag isEqualToString:REQ_TAG_REDEEM_REWARDS] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling redeem rewards"];
                [self.bServerInterface redeemRewards:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_COMPLETE_ACTION] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling completed action"];
                [self.bServerInterface userCompletedAction:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling create custom url"];
                [self.bServerInterface createCustomUrl:req];
            } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling identify user"];
                [self.bServerInterface identifyUser:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_LOGOUT] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling logout"];
                [self.bServerInterface logoutUser:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling close"];
                [self.bServerInterface registerClose];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling get reward history"];
                [self.bServerInterface getCreditHistory:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_CODE] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling get/create referral code"];
                [self.bServerInterface getReferralCode:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_VALIDATE_REFERRAL_CODE] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling validate referral code"];
                [self.bServerInterface validateReferralCode:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_APPLY_REFERRAL_CODE] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling apply referral code"];
                [self.bServerInterface applyReferralCode:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_UPLOAD_LIST_OF_APPS] && [self hasSession]) {
                [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"calling upload apps"];
                [self.bServerInterface uploadListOfApps:req.postData];
            }
        }
    } else {
        dispatch_semaphore_signal(self.processing_sema);
    }
    
}

- (void)handleFailure:(unsigned int)index {
    NSDictionary *errorDict;
    if (self.initNotCalled)
        errorDict = [BNCError getUserInfoDictForDomain:BNCNotInitError];
    BNCServerRequest *req;
    if (index >= [self.requestQueue size]) {
        req = [self.requestQueue peekAt:[self.requestQueue size]-1];
    } else {
        req = [self.requestQueue peekAt:index];
    }
    
    if (req) {
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            errorDict = [BNCError getUserInfoDictForDomain:BNCInitError];
            if (self.sessionparamLoadCallback) self.sessionparamLoadCallback(errorDict, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:errorDict]);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCGetReferralsError];
            if (self.pointLoadCallback) {
                self.pointLoadCallback(NO, [NSError errorWithDomain:BNCErrorDomain code:BNCGetReferralsError userInfo:errorDict]);
                self.pointLoadCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCGetCreditsError];
            if (self.rewardLoadCallback) {
                self.rewardLoadCallback(NO, [NSError errorWithDomain:BNCErrorDomain code:BNCGetCreditsError userInfo:errorDict]);
                self.rewardLoadCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCGetCreditHistoryError];
            if (self.creditHistoryLoadCallback) {
                self.creditHistoryLoadCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCGetCreditHistoryError userInfo:errorDict]);
                self.creditHistoryLoadCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            if (self.urlLoadCallback) {
                if (!self.initNotCalled)
                    errorDict = [BNCError getUserInfoDictForDomain:BNCCreateURLError];
                NSString *failedUrl = nil;
                if (![[BNCPreferenceHelper getUserURL] isEqualToString:NO_STRING_VALUE]) {
                    failedUrl = [BNCPreferenceHelper getUserURL];
                }
                self.urlLoadCallback(failedUrl, [NSError errorWithDomain:BNCErrorDomain code:BNCCreateURLError userInfo:errorDict]);
                self.urlLoadCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCIdentifyError];
            if (self.installparamLoadCallback) {
                self.installparamLoadCallback(errorDict, [NSError errorWithDomain:BNCErrorDomain code:BNCIdentifyError userInfo:errorDict]);
                self.installparamLoadCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_CODE]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCGetReferralCodeError];
            if (self.getReferralCodeCallback) {
                self.getReferralCodeCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCGetReferralCodeError userInfo:errorDict]);
                self.getReferralCodeCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_VALIDATE_REFERRAL_CODE]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCValidateReferralCodeError];
            if (self.validateReferralCodeCallback) {
                self.validateReferralCodeCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCValidateReferralCodeError userInfo:errorDict]);
                self.validateReferralCodeCallback = nil;
            }
        } else if ([req.tag isEqualToString:REQ_TAG_APPLY_REFERRAL_CODE]) {
            if (!self.initNotCalled)
                errorDict = [BNCError getUserInfoDictForDomain:BNCApplyReferralCodeError];
            if (self.applyReferralCodeCallback) {
                self.applyReferralCodeCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCApplyReferralCodeError userInfo:errorDict]);
                self.applyReferralCodeCallback = nil;
            }
        }
    }
}

- (void)retryLastRequest {
    self.retryCount = self.retryCount + 1;
    if (self.retryCount > [BNCPreferenceHelper getRetryCount]) {
        [self handleFailure:0];
        [self.requestQueue dequeue];
        self.retryCount = 0;
    } else {
        [NSThread sleepForTimeInterval:[BNCPreferenceHelper getRetryInterval]];
    }
    [self processNextQueueItem];
}

- (void)updateAllRequestsInQueue {
    for (int i = 0; i < self.requestQueue.size; i++) {
        BNCServerRequest *request = [self.requestQueue peekAt:i];
        
        if (request && request.postData) {
            for (NSString *key in [request.postData allKeys]) {
                if ([key isEqualToString:APP_ID]) {
                    [request.postData setValue:[BNCPreferenceHelper getAppKey] forKey:APP_ID];
                } else if ([key isEqualToString:SESSION_ID]) {
                    [request.postData setValue:[BNCPreferenceHelper getSessionID] forKey:SESSION_ID];
                } else if ([key isEqualToString:IDENTITY_ID]) {
                    [request.postData setValue:[BNCPreferenceHelper getIdentityID] forKey:IDENTITY_ID];
                }
            }
        }
    }

    [self.requestQueue persist];
}

- (BOOL)hasIdentity {
    return ![[BNCPreferenceHelper getUserIdentity] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasUser {
    return ![[BNCPreferenceHelper getIdentityID] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasSession {
    return ![[BNCPreferenceHelper getSessionID] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasAppKey {
    return ![[BNCPreferenceHelper getAppKey] isEqualToString:NO_STRING_VALUE];
}

- (void)registerInstallOrOpen:(NSString *)tag {
    if (![self.requestQueue containsInstallOrOpen]) {
        BNCServerRequest *req = [[BNCServerRequest alloc] initWithTag:tag];
        [self insertRequestAtFront:req];
    } else {
        [self.requestQueue moveInstallOrOpen:tag ToFront:self.networkCount];
    }
    
    dispatch_async(self.asyncQueue, ^{
        [self processNextQueueItem];
    });
}

-(void)initializeSession {
    if (![self hasAppKey]) {
        NSLog(@"Branch Warning: Feed me app key please! You need to call getInstance:yourAppKey first.");
        return;
    }
    
    if ([self hasUser]) {
        [self registerInstallOrOpen:REQ_TAG_REGISTER_OPEN];
    } else {
        [self registerInstallOrOpen:REQ_TAG_REGISTER_INSTALL];
    }
}

-(void)processReferralCounts:(NSDictionary *)returnedData {
    BOOL updateListener = NO;
    
    for (NSString *key in returnedData) {
        NSDictionary *counts = [returnedData objectForKey:key];
        NSInteger total = [[counts objectForKey:TOTAL] integerValue];
        NSInteger unique = [[counts objectForKey:UNIQUE] integerValue];
        
        if (total != [BNCPreferenceHelper getActionTotalCount:key] || unique != [BNCPreferenceHelper getActionUniqueCount:key])
            updateListener = YES;
        
        [BNCPreferenceHelper setActionTotalCount:key withCount:total];
        [BNCPreferenceHelper setActionUniqueCount:key withCount:unique];
    }
    if (self.pointLoadCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pointLoadCallback(updateListener, nil);
            self.pointLoadCallback = nil;
        });
    }
}


-(void)processReferralCredits:(NSDictionary *)returnedData {
    BOOL updateListener = NO;
    
    for (NSString *key in returnedData) {
        NSInteger credits = [[returnedData objectForKey:key] integerValue];
        
        if (credits != [BNCPreferenceHelper getCreditCountForBucket:key])
            updateListener = YES;
        
        [BNCPreferenceHelper setCreditCount:credits forBucket:key];
    }
    if (self.rewardLoadCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rewardLoadCallback(updateListener, nil);
            self.rewardLoadCallback = nil;
        });
    }
}

- (void)processCreditHistory:(NSArray *)returnedData {
    if (self.creditHistoryLoadCallback) {
        for (NSMutableDictionary *transaction in returnedData) {
            if ([transaction objectForKey:REFERRER] == [NSNull null]) {
                [transaction removeObjectForKey:REFERRER];
            }
            if ([transaction objectForKey:REFERREE] == [NSNull null]) {
                [transaction removeObjectForKey:REFERREE];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.creditHistoryLoadCallback(returnedData, nil);
            self.creditHistoryLoadCallback = nil;
        });
    }
}

- (void)processReferralCodeGet:(NSDictionary *)returnedData {
    if (self.getReferralCodeCallback) {
        NSError *error = nil;
        if (![returnedData objectForKey:REFERRAL_CODE]) {
            NSDictionary *errorDict = [BNCError getUserInfoDictForDomain:BNCDuplicateReferralCodeError];
            error = [NSError errorWithDomain:BNCErrorDomain code:BNCDuplicateReferralCodeError userInfo:errorDict];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.getReferralCodeCallback(returnedData, error);
            self.getReferralCodeCallback = nil;
        });
    }
}

- (void)processReferralCodeValidation:(NSDictionary *)returnedData {
    if (self.validateReferralCodeCallback) {
        NSError *error = nil;
        if (![returnedData objectForKey:REFERRAL_CODE]) {
            NSDictionary *errorDict = [BNCError getUserInfoDictForDomain:BNCInvalidReferralCodeError];
            error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:errorDict];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.validateReferralCodeCallback(returnedData, error);
            self.validateReferralCodeCallback = nil;
        });
    }
}

- (void)processReferralCodeApply:(NSDictionary *)returnedData {
    if (self.applyReferralCodeCallback) {
        NSError *error = nil;
        if (![returnedData objectForKey:REFERRAL_CODE]) {
            NSDictionary *errorDict = [BNCError getUserInfoDictForDomain:BNCInvalidReferralCodeError];
            error = [NSError errorWithDomain:BNCErrorDomain code:BNCInvalidReferralCodeError userInfo:errorDict];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.applyReferralCodeCallback(returnedData, error);
            self.applyReferralCodeCallback = nil;
        });
    }
}

- (void)serverCallback:(BNCServerResponse *)response {
    if (response) {
        NSInteger status = [response.statusCode integerValue];
        NSString *requestTag = response.tag;
        
        BOOL retry = NO;
        self.hasNetwork = YES;
        
        if (status == 409) {
            if ([requestTag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.urlLoadCallback) {
                        self.urlLoadCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCCreateURLDuplicateAliasError userInfo:[BNCError getUserInfoDictForDomain:BNCCreateURLDuplicateAliasError]]);
                        self.urlLoadCallback = nil;
                    }
                });
            } else {
                NSLog(@"Branch API Error: Duplicate Branch resource error.");
                [self handleFailure:[self.requestQueue size]-1];
            }
        } else if (status >= 400 && status < 500) {
            if (response.data && [response.data objectForKey:ERROR]) {
                NSLog(@"Branch API Error: %@", [[response.data objectForKey:ERROR] objectForKey:MESSAGE]);
            }
            if (self.lastRequestWasInit && !self.initFailed) {
                self.initFailed = YES;
                for (int i = 0; i < [self.requestQueue size]-1; i++) {
                    [self handleFailure:i];
                }
            }
            [self handleFailure:[self.requestQueue size]-1];
        } else if (status != 200) {
            if (status == NSURLErrorNotConnectedToInternet || status == NSURLErrorCannotFindHost) {
                self.hasNetwork = NO;
                [self handleFailure:self.lastRequestWasInit ? 0 : [self.requestQueue size]-1];
                if ([requestTag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {  // for safety sake		
                    [self.requestQueue dequeue];
                }
                NSLog(@"Branch API Error: Poor network connectivity. Please try again later.");
            } else {
                retry = YES;
                dispatch_async(self.asyncQueue, ^{
                    [self retryLastRequest];
                });
            }
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            [BNCPreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [BNCPreferenceHelper setDeviceFingerprintID:[response.data objectForKey:DEVICE_FINGERPRINT_ID]];
            [BNCPreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            [BNCPreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            
            if ([BNCPreferenceHelper getIsReferrable]) {
                if ([response.data objectForKey:DATA]) {
                    [BNCPreferenceHelper setInstallParams:[response.data objectForKey:DATA]];
                } else {
                    [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
                }
            }
            [BNCPreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([response.data objectForKey:LINK_CLICK_ID]) {
                [BNCPreferenceHelper setLinkClickID:[response.data objectForKey:LINK_CLICK_ID]];
            } else {
                [BNCPreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            if ([response.data objectForKey:DATA]) {
                [BNCPreferenceHelper setSessionParams:[response.data objectForKey:DATA]];
            } else {
                [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            if ([BNCPreferenceHelper getNeedAppListCheck]) {
                [self processListOfApps];
            }
            [self updateAllRequestsInQueue];
            
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getLatestReferringParams], nil);
                });
            }
            
            self.initFinished = YES;
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [BNCPreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            [BNCPreferenceHelper setDeviceFingerprintID:[response.data objectForKey:DEVICE_FINGERPRINT_ID]];
            if ([response.data objectForKey:IDENTITY_ID]) {
                [BNCPreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            }
            if ([response.data objectForKey:LINK_CLICK_ID]) {
                [BNCPreferenceHelper setLinkClickID:[response.data objectForKey:LINK_CLICK_ID]];
            } else {
                [BNCPreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            [BNCPreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([BNCPreferenceHelper getIsReferrable]) {
                if ([response.data objectForKey:DATA]) {
                    [BNCPreferenceHelper setInstallParams:[response.data objectForKey:DATA]];
                }
            }
            if ([BNCPreferenceHelper getNeedAppListCheck]) {
                [self processListOfApps];
            }
            if ([response.data objectForKey:DATA]) {
                [BNCPreferenceHelper setSessionParams:[response.data objectForKey:DATA]];
            } else {
                [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getLatestReferringParams], nil);
                });
            }
            
            self.initFinished = YES;
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REWARDS]) {
            [self processReferralCredits:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REWARD_HISTORY]) {
            [self processCreditHistory:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
            [self processReferralCounts:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            NSString *url = [response.data objectForKey:URL];
            if (self.urlLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.urlLoadCallback) {
                        self.urlLoadCallback(url, nil);
                        self.urlLoadCallback = nil;
                    }
                });
            }
            
            // cache the link
            BNCLinkData *linkData = response.linkData;
            if (linkData) {
                [self.linkCache setObject:url forKey:linkData];
            }
        } else if ([requestTag isEqualToString:REQ_TAG_LOGOUT]) {
            [BNCPreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            [BNCPreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [BNCPreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            
            [BNCPreferenceHelper setUserIdentity:NO_STRING_VALUE];
            [BNCPreferenceHelper setInstallParams:NO_STRING_VALUE];
            [BNCPreferenceHelper setSessionParams:NO_STRING_VALUE];
            [BNCPreferenceHelper clearUserCreditsAndCounts];
        } else if ([requestTag isEqualToString:REQ_TAG_IDENTIFY]) {
            [BNCPreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [BNCPreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            
            if ([response.data objectForKey:REFERRING_DATA]) {
                [BNCPreferenceHelper setInstallParams:[response.data objectForKey:REFERRING_DATA]];
            }
            
            if (self.requestQueue.size > 0) {
                BNCServerRequest *req = [self.requestQueue peek];
                if (req && req.postData && [req.postData objectForKey:IDENTITY]) {
                    [BNCPreferenceHelper setUserIdentity:[req.postData objectForKey:IDENTITY]];
                }
            }
            
            if (self.installparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.installparamLoadCallback) {
                        self.installparamLoadCallback([self getFirstReferringParams], nil);
                        self.installparamLoadCallback = nil;
                    }
                });
            }
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REFERRAL_CODE]) {
            [self processReferralCodeGet:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_VALIDATE_REFERRAL_CODE]) {
            [self processReferralCodeValidation:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_APPLY_REFERRAL_CODE]) {
            [self processReferralCodeApply:response.data];
        } else if ([requestTag isEqualToString:REQ_TAG_UPLOAD_LIST_OF_APPS]) {
            [BNCPreferenceHelper setAppListCheckDone];
        }
        
        if (!retry && self.hasNetwork && !self.initFailed) {
            [self.requestQueue dequeue];
            
            dispatch_async(self.asyncQueue, ^{
                self.networkCount = 0;
                [self processNextQueueItem];
            });
        } else {
            self.networkCount = 0;
        }
    }
}

#pragma mark - Debugger functions

- (void)bnc_addDebugGestureRecognizer {
    [self bnc_addGesterRecognizer:@selector(bnc_connectToDebug:)];
}

- (void)bnc_addCancelDebugGestureRecognizer {
    [self bnc_addGesterRecognizer:@selector(bnc_endDebug:)];
}

- (void)bnc_addGesterRecognizer:(SEL)action {
    BNCLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:action];
    BNCLongPress.delegate = self;
    BNCLongPress.minimumPressDuration = BNCDebugTriggerDuration;
    if ([BNCSystemObserver isSimulator]) {
        BNCLongPress.numberOfTouchesRequired = BNCDebugTriggerFingersSimulator;
    } else {
        BNCLongPress.numberOfTouchesRequired = BNCDebugTriggerFingers;
    }
    [[UIApplication sharedApplication].keyWindow addGestureRecognizer:BNCLongPress];
}

- (void)bnc_connectToDebug:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan){
        NSLog(@"======= Start Debug Session =======");
        [BNCPreferenceHelper setDebugConnectionDelegate:self];
        [BNCPreferenceHelper setDebug];
    }
}

- (void)bnc_startDebug {
    NSLog(@"======= Connected to Branch Remote Debugger =======");
    
    if (!bnc_asyncDebugQueue) {
        bnc_asyncDebugQueue = dispatch_queue_create("bnc_debug_queue", NULL);
    }
    
    [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:BNCLongPress];
    [self bnc_addCancelDebugGestureRecognizer];
    
    //TODO: change to send screenshots instead in future
    if (!bnc_debugTimer || !bnc_debugTimer.isValid) {
        bnc_debugTimer = [NSTimer scheduledTimerWithTimeInterval:20.0f
                                                          target:self
                                                        selector:@selector(bnc_keepDebugAlive)     //change to @selector(bnc_takeScreenshot)
                                                        userInfo:nil
                                                         repeats:YES];
    }
}

- (void)bnc_endDebug:(UILongPressGestureRecognizer *)sender {
    NSLog(@"======= End Debug Session =======");
    
    [[UIApplication sharedApplication].keyWindow removeGestureRecognizer:sender];
    [BNCPreferenceHelper clearDebug];
    bnc_asyncDebugQueue = nil;
    [bnc_debugTimer invalidate];
    [self bnc_addDebugGestureRecognizer];
}

- (void)bnc_keepDebugAlive {
    if (bnc_asyncDebugQueue) {
        dispatch_async(bnc_asyncDebugQueue, ^{
            [BNCPreferenceHelper keepDebugAlive];
        });
    }
}

#pragma mark - BNCDebugConnectionDelegate

- (void)bnc_debugConnectionEstablished {
    [self bnc_startDebug];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
        return YES;
}

@end

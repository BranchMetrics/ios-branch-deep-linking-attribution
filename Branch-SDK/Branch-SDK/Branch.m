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


static NSString *APP_ID = @"app_id";
static NSString *IDENTITY = @"identity";
static NSString *IDENTITY_ID = @"identity_id";
static NSString *SESSION_ID = @"session_id";
static NSString *BUCKET = @"bucket";
static NSString *AMOUNT = @"amount";
static NSString *EVENT = @"event";
static NSString *METADATA = @"metadata";
static NSString *TAGS = @"tags";
static NSString *CHANNEL = @"channel";
static NSString *FEATURE = @"feature";
static NSString *STAGE = @"stage";
static NSString *DATA = @"data";
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

static NSString *LENGTH = @"length";
static NSString *BEGIN_AFTER_ID = @"begin_after_id";
static NSString *DIRECTION = @"direction";

#define DIRECTIONS @[@"desc", @"asc"]



@interface Branch() <BNCServerInterfaceDelegate>

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
@property (assign, nonatomic) BOOL initFinished;
@property (assign, nonatomic) BOOL hasNetwork;
@property (assign, nonatomic) BOOL isDebugMode;

@end

@implementation Branch

static const NSInteger RETRY_INTERVAL = 3;
static const NSInteger MAX_RETRIES = 5;

static Branch *currInstance;

// PUBLIC CALLS

+ (Branch *)getInstance:(NSString *)key {
    [BNCPreferenceHelper setAppKey:key];
    
    if (!currInstance) {
        [Branch initInstance];
    }
    
    return currInstance;
}

+ (Branch *)getInstance {
    if (!currInstance) {
        [Branch initInstance];
        NSLog(@"Branch Warning: getInstance called before getInstance with key. Please init");
    }
    return currInstance;
}

+ (void)initInstance {
    currInstance = [[Branch alloc] init];
    currInstance.isInit = NO;
    currInstance.bServerInterface = [[BranchServerInterface alloc] init];
    currInstance.bServerInterface.delegate = currInstance;
    currInstance.processing_sema = dispatch_semaphore_create(1);
    currInstance.asyncQueue = dispatch_queue_create("brnch_request_queue", NULL);
    currInstance.requestQueue = [BNCServerRequestQueue getInstance];
    currInstance.initFinished = NO;
    currInstance.hasNetwork = YES;
    currInstance.isDebugMode = NO;
    
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
}

- (void)setDebug {
    self.isDebugMode = YES;
}

- (void)resetUserSession {
    if (self) {
        self.isInit = NO;
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
    if (!self.isInit) {
        self.isInit = YES;
        [self initializeSession];
    } else if ([self hasUser] && [self hasSession] && ![self.requestQueue containsInstallOrOpen]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getLatestReferringParams], nil);
    } else {
        if (![self.requestQueue containsInstallOrOpen]) {
            [self initializeSession];
        } else {
            [self processNextQueueItem];
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
    if (!userId)
        return;

    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_IDENTIFY;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[userId, [BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getIdentityID]] forKeys:@[IDENTITY, APP_ID, IDENTITY_ID]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
        }
    });
}

- (void)logout {
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getSessionID]] forKeys:@[APP_ID, SESSION_ID]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
        }
    });
}

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback {
    self.pointLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_COUNTS;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
        }
    });
}

- (void)loadRewardsWithCallback:(callbackWithStatus)callback {
    self.rewardLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARDS;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
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
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[bucket, [NSNumber numberWithInteger:redemptionsToAdd], [BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getIdentityID]] forKeys:@[BUCKET, AMOUNT, APP_ID, IDENTITY_ID]];
            req.postData = post;
            [self.requestQueue enqueue:req];
            
            if (self.initFinished || !self.hasNetwork) {
                [self processNextQueueItem];
            }
        }
    });
    
}

- (void)getCreditHistoryWithCallback:(callbackWithList)callback {
    [self getCreditHistoryAfter:nil number:100 order:kMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:bucket after:nil number:100 order:kMostRecentFirst andCallback:callback];
}

- (void)getCreditHistoryAfter:(NSString *)creditTransactionId number:(NSInteger)length order:(CreditHistoryOrder)order andCallback:(callbackWithList)callback {
    [self getCreditHistoryForBucket:nil after:creditTransactionId number:length order:order andCallback:callback];
}

- (void)getCreditHistoryForBucket:(NSString *)bucket after:(NSString *)creditTransactionId number:(NSInteger)length order:(CreditHistoryOrder)order andCallback:(callbackWithList)callback {
    self.creditHistoryLoadCallback = callback;
    
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARD_HISTORY;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjects:@[[BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getIdentityID], [NSNumber numberWithLong:length], DIRECTIONS[order]]
                                                                       forKeys:@[APP_ID, IDENTITY_ID, LENGTH, DIRECTION]];
        if (bucket) {
            [data setObject:bucket forKey:BUCKET];
        }
        if (creditTransactionId) {
            [data setObject:creditTransactionId forKey:BEGIN_AFTER_ID];
        }
        req.postData = data;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
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
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[action, [BNCPreferenceHelper getAppKey], [BNCPreferenceHelper getSessionID]] forKeys:@[EVENT, APP_ID, SESSION_ID]];
        NSDictionary *saniState = [self sanitizeQuotesFromInput:state];
        if (saniState && [NSJSONSerialization isValidJSONObject:saniState]) [post setObject:saniState forKey:METADATA];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
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

- (void)getShortURLWithCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:nil andFeature:nil andStage:nil andParams:nil andCallback:callback];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getContentUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:channel andFeature:BRANCH_FEATURE_TAG_SHARE andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getReferralUrlWithParams:(NSDictionary *)params andChannel:(NSString *)channel andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:channel andFeature:BRANCH_FEATURE_TAG_REFERRAL andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:nil andFeature:nil andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTags:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tags andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:channel andFeature:feature andStage:stage andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andChannel:(NSString *)channel andFeature:(NSString *)feature andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andChannel:channel andFeature:feature andStage:nil andParams:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]] andCallback:callback];
}

// PRIVATE CALLS

- (void)generateShortUrl:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSString *)params andCallback:(callbackWithUrl)callback {
    self.urlLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        BNCServerRequest *req = [[BNCServerRequest alloc] init];
        req.tag = REQ_TAG_GET_CUSTOM_URL;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
        [post setObject:[BNCPreferenceHelper getAppKey] forKey:APP_ID];
        [post setObject:[BNCPreferenceHelper getIdentityID] forKey:IDENTITY_ID];
        if (tags)
            [post setObject:tags forKey:TAGS];
        if (channel)
            [post setObject:channel forKey:CHANNEL];
        if (feature)
            [post setObject:feature forKey:FEATURE];
        if (stage)
            [post setObject:stage forKey:STAGE];
        
        NSString *args = params ? params : @"{ \"source\":\"ios\" }";
        [post setObject:args forKey:DATA];
        
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished || !self.hasNetwork) {
            [self processNextQueueItem];
        }
    });
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
        dispatch_async(self.asyncQueue, ^{
            BNCServerRequest *req = [[BNCServerRequest alloc] init];
            if (![self hasUser]) {
                req.tag = REQ_TAG_REGISTER_INSTALL;
            } else {
                req.tag = REQ_TAG_REGISTER_OPEN;
            }
            [self insertRequestAtFront:req];
            [self processNextQueueItem];
            self.isInit = YES;
        });
    }
}

- (void)applicationWillResignActive {
    [self clearTimer];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(callClose) userInfo:nil repeats:NO];
}

- (void)clearTimer {
    [self.sessionTimer invalidate];
}

- (void)callClose {
    self.isInit = NO;
    
    if (!self.hasNetwork) {
        // if there's no network connectivity, purge the old install/open
        BNCServerRequest *req = [self.requestQueue peek];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [self.requestQueue dequeue];
        }
    } else {
        if (![self.requestQueue containsClose]) {
            BNCServerRequest *req = [[BNCServerRequest alloc] initWithTag:REQ_TAG_REGISTER_CLOSE];
            [self.requestQueue enqueue:req];
        }
        
        if (self.initFinished || !self.hasNetwork) {
            dispatch_async(self.asyncQueue, ^{
                [self processNextQueueItem];
            });
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
            if (![req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
                [self clearTimer];
            }
            
            if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
                Debug(@"calling register install");
                [self.bServerInterface registerInstall:self.isDebugMode];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_OPEN] && [self hasUser]) {
                Debug(@"calling register open");
                [self.bServerInterface registerOpen:self.isDebugMode];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS] && [self hasUser] && [self hasSession]) {
                Debug(@"calling get referrals");
                [self.bServerInterface getReferralCounts];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS] && [self hasUser] && [self hasSession]) {
                Debug(@"calling get rewards");
                [self.bServerInterface getRewards];
            } else if ([req.tag isEqualToString:REQ_TAG_REDEEM_REWARDS] && [self hasUser] && [self hasSession]) {
                Debug(@"calling redeem rewards");
                [self.bServerInterface redeemRewards:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_COMPLETE_ACTION] && [self hasUser] && [self hasSession]) {
                Debug(@"calling completed action");
                [self.bServerInterface userCompletedAction:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL] && [self hasUser] && [self hasSession]) {
                Debug(@"calling create custom url");
                [self.bServerInterface createCustomUrl:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY] && [self hasUser] && [self hasSession]) {
                Debug(@"calling identify user");
                [self.bServerInterface identifyUser:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_LOGOUT] && [self hasUser] && [self hasSession]) {
                Debug(@"calling logout");
                [self.bServerInterface logoutUser:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE] && [self hasUser] && [self hasSession]) {
                Debug(@"calling close");
                [self.bServerInterface registerClose];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY] && [self hasUser] && [self hasSession]) {
                Debug(@"calling get reward history");
                [self.bServerInterface getCreditHistory:req.postData];
            } else if (![self hasUser]) {
                if (![self hasAppKey] && [self hasSession]) {
                    NSLog(@"Branch Warning: User session not init yet. Please call initUserSession");
                } else {
                    self.networkCount = 0;
                    [self initSession];
                }
            }
        }
    } else {
        dispatch_semaphore_signal(self.processing_sema);
    }
    
}

- (void)handleFailure {
    NSDictionary *errorDict = [NSDictionary dictionaryWithObject:@[@"Trouble reaching server. Please try again in a few minutes"] forKey:NSLocalizedDescriptionKey];
    
    BNCServerRequest *req = [self.requestQueue peek];
    if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback(errorDict, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:errorDict]);
    } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
        if (self.pointLoadCallback) self.pointLoadCallback(NO, [NSError errorWithDomain:BNCErrorDomain code:BNCGetReferralsError userInfo:nil]);
    } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS]) {
        if (self.rewardLoadCallback) self.rewardLoadCallback(NO, [NSError errorWithDomain:BNCErrorDomain code:BNCGetCreditsError userInfo:nil]);
    } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY]) {
        if (self.creditHistoryLoadCallback) {
            self.creditHistoryLoadCallback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCGetCreditHistoryError userInfo:nil]);
        }
    } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
        if (self.urlLoadCallback) self.urlLoadCallback(@"Trouble reaching server. Please try again in a few minutes", [NSError errorWithDomain:BNCErrorDomain code:BNCCreateURLError userInfo:errorDict]);
    } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
        if (self.installparamLoadCallback) self.installparamLoadCallback(errorDict, [NSError errorWithDomain:BNCErrorDomain code:BNCIdentifyError userInfo:errorDict]);
    }
}

- (void)retryLastRequest {
    self.retryCount = self.retryCount + 1;
    if (self.retryCount > MAX_RETRIES) {
        [self handleFailure];
        [self.requestQueue dequeue];
        self.retryCount = 0;
    } else {
        [NSThread sleepForTimeInterval:RETRY_INTERVAL];
    }
    [self processNextQueueItem];
}

- (void)updateAllRequestsInQueue {
    for (int i = 0; i < self.requestQueue.size; i++) {
        BNCServerRequest *request = [self.requestQueue peekAt:i];
        
        if (request.postData) {
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
        });
    }
}

- (void)serverCallback:(BNCServerResponse *)response {
    if (response) {
        NSInteger status = [response.statusCode integerValue];
        NSString *requestTag = response.tag;
        
        BOOL retry = NO;
        self.hasNetwork = YES;
        
        if (status >= 400 && status < 500) {
            if (response.data && [response.data objectForKey:ERROR]) {
                NSLog(@"Branch API Error: %@", [[response.data objectForKey:ERROR] objectForKey:MESSAGE]);
            }
        } else if (status != 200) {
            if (status == NSURLErrorNotConnectedToInternet || status == NSURLErrorNetworkConnectionLost || status == NSURLErrorCannotFindHost) {
                self.hasNetwork = NO;
                [self handleFailure];
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
            
            [self updateAllRequestsInQueue];
            
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getLatestReferringParams], nil);
                });
            }
            
            self.initFinished = YES;
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [BNCPreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
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
                    if (self.urlLoadCallback) self.urlLoadCallback(url, nil);
                });
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
                if (req.postData && [req.postData objectForKey:IDENTITY]) {
                    [BNCPreferenceHelper setUserIdentity:[req.postData objectForKey:IDENTITY]];
                }
            }
            
            if (self.installparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.installparamLoadCallback) self.installparamLoadCallback([self getFirstReferringParams], nil);
                });
            }
        } else if ([requestTag isEqualToString:REQ_TAG_COMPLETE_ACTION] || [requestTag isEqualToString:REQ_TAG_PROFILE_DATA] || [requestTag isEqualToString:REQ_TAG_REDEEM_REWARDS] || [requestTag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
        }
        
        if (!retry && self.hasNetwork) {
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

@end

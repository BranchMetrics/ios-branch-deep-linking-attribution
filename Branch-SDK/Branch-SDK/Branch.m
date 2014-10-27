//
//  Branch_SDK.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchServerInterface.h"
#import "PreferenceHelper.h"
#import "ServerRequest.h"
#import "ServerResponse.h"
#import "SystemObserver.h"
#import "ServerRequestQueue.h"
#import "Config.h"


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

static NSString *LENGTH = @"length";
static NSString *BEGIN_AFTER_ID = @"begin_after_id";
static NSString *DIRECTION = @"direction";

#define DIRECTIONS @[@"desc", @"asc"]



@interface Branch() <ServerInterfaceDelegate>

@property (strong, nonatomic) BranchServerInterface *bServerInterface;

@property (nonatomic) BOOL isInit;

@property (strong, nonatomic) NSTimer *sessionTimer;
@property (strong, nonatomic) ServerRequestQueue *requestQueue;
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

@end

@implementation Branch

static const NSInteger RETRY_INTERVAL = 3;
static const NSInteger MAX_RETRIES = 5;

static Branch *currInstance;

// PUBLIC CALLS

+ (Branch *)getInstance:(NSString *)key {
    [PreferenceHelper setAppKey:key];
    
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
    currInstance.requestQueue = [ServerRequestQueue getInstance];
    currInstance.initFinished = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:currInstance
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:currInstance
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    currInstance.retryCount = 0;
    currInstance.networkCount = 0;
}

- (void)resetUserSession {
    if (self) {
        self.isInit = NO;
    }
}

- (void)initUserSession {
    [self initUserSessionWithCallback:nil];
}

- (void)initUserSessionWithLaunchOptions:(NSDictionary *)options {
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey])
        [self initUserSessionWithCallback:nil];
}

- (void)initUserSession:(BOOL)isReferrable {
    [self initUserSessionWithCallback:nil andIsReferrable:isReferrable];
}

- (void)initUserSessionWithCallback:(callbackWithParams)callback withLaunchOptions:(NSDictionary *)options {
    self.sessionparamLoadCallback = callback;
    if (![SystemObserver getUpdateState] && ![self hasUser])
        [PreferenceHelper setIsReferrable];
    else
        [PreferenceHelper clearIsReferrable];
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey])
        [self initUserSessionWithCallbackInternal:callback];
}

- (void)initUserSessionWithLaunchOptions:(NSDictionary *)options andIsReferrable:(BOOL)isReferrable {
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey])
        [self initUserSessionWithCallback:nil andIsReferrable:isReferrable];
}

- (void) initUserSessionWithCallback:(callbackWithParams)callback andIsReferrable:(BOOL)isReferrable {
    if (isReferrable) {
        [PreferenceHelper setIsReferrable];
    } else {
        [PreferenceHelper clearIsReferrable];
    }
    [self initUserSessionWithCallbackInternal:callback];
}

- (void)initUserSessionWithCallback:(callbackWithParams)callback andIsReferrable:(BOOL)isReferrable withLaunchOptions:(NSDictionary *)options {
    self.sessionparamLoadCallback = callback;
    if (![options objectForKey:UIApplicationLaunchOptionsURLKey])
        [self initUserSessionWithCallback:callback andIsReferrable:isReferrable];
}

- (void)initUserSessionWithCallback:(callbackWithParams)callback {
    if (![SystemObserver getUpdateState] && ![self hasUser])
        [PreferenceHelper setIsReferrable];
    else
        [PreferenceHelper clearIsReferrable];
    [self initUserSessionWithCallbackInternal:callback];
}

- (void)initUserSessionWithCallbackInternal:(callbackWithParams)callback {
    self.sessionparamLoadCallback = callback;
    if (!self.isInit) {
        self.isInit = YES;
        [self initSession];
    } else if ([self hasUser] && [self hasSession] && ![self.requestQueue containsInstallOrOpen]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
    } else {
        if (![self.requestQueue containsInstallOrOpen]) {
            [self initSession];
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
            [PreferenceHelper setLinkClickIdentifier:[params objectForKey:@"link_click_id"]];
        }
    }
    [PreferenceHelper setIsReferrable];
    [self initUserSessionWithCallbackInternal:self.sessionparamLoadCallback];
    return handled;
}

//deprecated
- (void)identifyUser:(NSString *)userId withCallback:(callbackWithParams)callback {
    self.installparamLoadCallback = callback;
    [self identifyUser:userId];
}

//deprecated
- (void)identifyUser:(NSString *)userId {
    if (!userId)
        return;
    if ([self hasIdentity])
        return;
    if (![self identifyInQueue]) {
        dispatch_async(self.asyncQueue, ^{
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_IDENTIFY;
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[userId, [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[IDENTITY, APP_ID, IDENTITY_ID]];
            req.postData = post;
            [self.requestQueue enqueue:req];
            
            if (self.initFinished) {
                [self processNextQueueItem];
            }
        });
    }
}

//deprecated
- (void)clearUser {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[APP_ID, SESSION_ID]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (void)setIdentity:(NSString *)userId withCallback:(callbackWithParams)callback {
    self.installparamLoadCallback = callback;
    [self setIdentity:userId];
}

- (void)setIdentity:(NSString *)userId {
    if (!userId)
        return;

    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_IDENTIFY;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[userId, [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[IDENTITY, APP_ID, IDENTITY_ID]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (void)logout {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[APP_ID, SESSION_ID]];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback {
    self.pointLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_COUNTS;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (void)loadRewardsWithCallback:(callbackWithStatus)callback {
    self.rewardLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARDS;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (NSInteger)getCredits {
    return [PreferenceHelper getCreditCount];
}

- (void)redeemRewards:(NSInteger)count {
    [self redeemRewards:count forBucket:@"default"];
}

- (NSInteger)getCreditsForBucket:(NSString *)bucket {
    return [PreferenceHelper getCreditCountForBucket:bucket];
}

- (NSInteger)getTotalCountsForAction:(NSString *)action {
    return [PreferenceHelper getActionTotalCount:action];
}
- (NSInteger)getUniqueCountsForAction:(NSString *)action {
    return [PreferenceHelper getActionUniqueCount:action];
}

- (void)redeemRewards:(NSInteger)count forBucket:(NSString *)bucket {
    dispatch_async(self.asyncQueue, ^{
        NSInteger redemptionsToAdd = 0;
        NSInteger credits = [PreferenceHelper getCreditCountForBucket:bucket];
        if (count > credits) {
            redemptionsToAdd = credits;
            NSLog(@"Branch Warning: You're trying to redeem more credits than are available. Have you updated loaded rewards");
        } else {
            redemptionsToAdd = count;
        }
        
        if (redemptionsToAdd > 0) {
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_REDEEM_REWARDS;
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[bucket, [NSNumber numberWithInteger:redemptionsToAdd], [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[BUCKET, AMOUNT, APP_ID, IDENTITY_ID]];
            req.postData = post;
            [self.requestQueue enqueue:req];
            
            if (self.initFinished) {
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
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARD_HISTORY;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjects:@[[PreferenceHelper getAppKey], [PreferenceHelper getIdentityID], [NSNumber numberWithLong:length], DIRECTIONS[order]]
                                                                       forKeys:@[APP_ID, IDENTITY_ID, LENGTH, DIRECTION]];
        if (bucket) {
            [data setObject:bucket forKey:BUCKET];
        }
        if (creditTransactionId) {
            [data setObject:creditTransactionId forKey:BEGIN_AFTER_ID];
        }
        req.postData = data;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
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
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_COMPLETE_ACTION;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[action, [PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[EVENT, APP_ID, SESSION_ID]];
        NSDictionary *saniState = [self sanitizeQuotesFromInput:state];
        if (saniState && [NSJSONSerialization isValidJSONObject:saniState]) [post setObject:saniState forKey:METADATA];
        req.postData = post;
        [self.requestQueue enqueue:req];
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (NSDictionary *)getInstallReferringParams {
    NSString *storedParam = [PreferenceHelper getInstallParams];
    return [self convertParamsStringToDictionary:storedParam];
}

- (NSDictionary *)getReferringParams {
    NSString *storedParam = [PreferenceHelper getSessionParams];
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
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_CUSTOM_URL;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
        [post setObject:[PreferenceHelper getAppKey] forKey:APP_ID];
        [post setObject:[PreferenceHelper getIdentityID] forKey:IDENTITY_ID];
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
        
        if (self.initFinished) {
            [self processNextQueueItem];
        }
    });
}

- (void)applicationDidBecomeActive {
    dispatch_async(self.asyncQueue, ^{
        if (!self.isInit) {
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_REGISTER_OPEN;
            [self.requestQueue insert:req at:0];
            [self processNextQueueItem];
        }
    });
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
    
    if (![self.requestQueue containsClose]) {
        ServerRequest *req = [[ServerRequest alloc] initWithTag:REQ_TAG_REGISTER_CLOSE];
        [self.requestQueue enqueue:req];
    }
    
    if (self.initFinished) {
        dispatch_async(self.asyncQueue, ^{
            [self processNextQueueItem];
        });
    }
}

- (NSDictionary *)convertParamsStringToDictionary:(NSString *)paramsString {
    if (![paramsString isEqualToString:NO_STRING_VALUE]) {
        NSData *tempData = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *params = [NSJSONSerialization JSONObjectWithData:tempData options:0 error:nil];
        if (!params) {
            NSString *decodedVersion = [PreferenceHelper base64DecodeStringToString:paramsString];
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
        
        ServerRequest *req = [self.requestQueue peek];
        
        if (req) {
            if (![req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
                [self clearTimer];
            }
            
            if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
                Debug(@"calling register install");
                [self.bServerInterface registerInstall];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_OPEN] && [self hasUser]) {
                Debug(@"calling register open");
                [self.bServerInterface registerOpen];
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
                Debug(@"calling identify user");
                [self.bServerInterface logoutUser:req.postData];
            } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE] && [self hasUser] && [self hasSession]) {
                Debug(@"calling identify user");
                [self.bServerInterface registerClose];
            } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY] && [self hasUser] && [self hasSession]) {
                Debug(@"calling get reward history");
                [self.bServerInterface getCreditHistory:req.postData];
            } else if (![self hasUser]) {
                if (![self hasAppKey] && [self hasSession]) {
                    NSLog(@"Branch Warning: User session not init yet. Please call initUserSession");
                } else {
                    self.networkCount = 0;
                    [self initUserSession];
                }
            }
        }
    } else {
        dispatch_semaphore_signal(self.processing_sema);
    }
    
}

- (void)retryLastRequest {
    self.retryCount = self.retryCount + 1;
    if (self.retryCount > MAX_RETRIES) {
        ServerRequest *req = [self.requestQueue peek];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            NSDictionary *errorDict = [[NSDictionary alloc] initWithObjects:@[@"Trouble reaching server. Please try again in a few minutes"] forKeys:@[@"error"]];
            if (self.sessionparamLoadCallback) self.sessionparamLoadCallback(errorDict);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
            if (self.pointLoadCallback) self.pointLoadCallback(NO);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS]) {
            if (self.rewardLoadCallback) self.rewardLoadCallback(NO);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARD_HISTORY]) {
            if (self.creditHistoryLoadCallback) {
                self.creditHistoryLoadCallback(nil);
            }
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            if (self.urlLoadCallback) self.urlLoadCallback(@"Trouble reaching server. Please try again in a few minutes");
        } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
            NSDictionary *errorDict = [[NSDictionary alloc] initWithObjects:@[@"Trouble reaching server. Please try again in a few minutes"] forKeys:@[@"error"]];
            if (self.installparamLoadCallback) self.installparamLoadCallback(errorDict);
        }
        [self.requestQueue dequeue];
        self.retryCount = 0;
    } else {
        [NSThread sleepForTimeInterval:RETRY_INTERVAL];
    }
    [self processNextQueueItem];
}

- (void)updateAllRequestsInQueue {
    for (int i = 0; i < self.requestQueue.size; i++) {
        ServerRequest *request = [self.requestQueue peekAt:i];
        
        if (request.postData) {
            for (NSString *key in [request.postData allKeys]) {
                if ([key isEqualToString:APP_ID]) {
                    [request.postData setValue:[PreferenceHelper getAppKey] forKey:APP_ID];
                } else if ([key isEqualToString:SESSION_ID]) {
                    [request.postData setValue:[PreferenceHelper getSessionID] forKey:SESSION_ID];
                } else if ([key isEqualToString:IDENTITY_ID]) {
                    [request.postData setValue:[PreferenceHelper getIdentityID] forKey:IDENTITY_ID];
                }
            }
        }
    }

    [self.requestQueue persist];
}

//deprecate
- (BOOL)identifyInQueue {
    for (int i = 0; i < self.requestQueue.size; i++) {
        ServerRequest *req = [self.requestQueue peekAt:i];
        if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasIdentity {
    return ![[PreferenceHelper getUserIdentity] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasUser {
    return ![[PreferenceHelper getIdentityID] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasSession {
    return ![[PreferenceHelper getSessionID] isEqualToString:NO_STRING_VALUE];
}

- (BOOL)hasAppKey {
    return ![[PreferenceHelper getAppKey] isEqualToString:NO_STRING_VALUE];
}

- (void)registerInstallOrOpen:(NSString *)tag {
    if (![self.requestQueue containsInstallOrOpen]) {
        ServerRequest *req = [[ServerRequest alloc] initWithTag:tag];
        [self.requestQueue insert:req at:0];
    } else {
        [self.requestQueue moveInstallOrOpenToFront:tag];
    }
    
    dispatch_async(self.asyncQueue, ^{
        [self processNextQueueItem];
    });
}

-(void)initSession {
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
        
        if (total != [PreferenceHelper getActionTotalCount:key] || unique != [PreferenceHelper getActionUniqueCount:key])
            updateListener = YES;
        
        [PreferenceHelper setActionTotalCount:key withCount:total];
        [PreferenceHelper setActionUniqueCount:key withCount:unique];
    }
    if (self.pointLoadCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pointLoadCallback(updateListener);
        });
    }
}


-(void)processReferralCredits:(NSDictionary *)returnedData {
    BOOL updateListener = NO;
    
    for (NSString *key in returnedData) {
        NSInteger credits = [[returnedData objectForKey:key] integerValue];
        
        if (credits != [PreferenceHelper getCreditCountForBucket:key])
            updateListener = YES;
        
        [PreferenceHelper setCreditCount:credits forBucket:key];
    }
    if (self.rewardLoadCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rewardLoadCallback(updateListener);
        });
    }
}

- (void)processCreditHistory:(NSArray *)returnedData {
    if (self.creditHistoryLoadCallback) {
        for (NSMutableDictionary *transaction in returnedData) {
            if ([transaction objectForKey:REFERRER] == [NSNull null]) {
                [transaction removeObjectForKey:REFERRER];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.creditHistoryLoadCallback(returnedData);
        });
    }
}

- (void)serverCallback:(ServerResponse *)response {
    if (response) {
        NSInteger status = [response.statusCode integerValue];
        NSString *requestTag = response.tag;
        
        BOOL retry = NO;
        self.networkCount = 0;
        if (status >= 400 && status < 500) {
            if (response.data && [response.data objectForKey:ERROR]) {
                NSLog(@"Branch API Error: %@", [[response.data objectForKey:ERROR] objectForKey:MESSAGE]);
            }
        } else if (status != 200) {
            retry = YES;
            dispatch_async(self.asyncQueue, ^{
                [self retryLastRequest];
            });
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            [PreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [PreferenceHelper setDeviceFingerprintID:[response.data objectForKey:DEVICE_FINGERPRINT_ID]];
            [PreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            [PreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            
            if ([PreferenceHelper getIsReferrable]) {
                if ([response.data objectForKey:DATA]) {
                    [PreferenceHelper setInstallParams:[response.data objectForKey:DATA]];
                } else {
                    [PreferenceHelper setInstallParams:NO_STRING_VALUE];
                }
            }
            [PreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([response.data objectForKey:LINK_CLICK_ID]) {
                [PreferenceHelper setLinkClickID:[response.data objectForKey:LINK_CLICK_ID]];
            } else {
                [PreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            if ([response.data objectForKey:DATA]) {
                [PreferenceHelper setSessionParams:[response.data objectForKey:DATA]];
            } else {
                [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            
            [self updateAllRequestsInQueue];
            
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
                });
            }
            
            self.initFinished = YES;
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [PreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            if ([response.data objectForKey:LINK_CLICK_ID]) {
                [PreferenceHelper setLinkClickID:[response.data objectForKey:LINK_CLICK_ID]];
            } else {
                [PreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            [PreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([PreferenceHelper getIsReferrable]) {
                if ([response.data objectForKey:DATA]) {
                    [PreferenceHelper setInstallParams:[response.data objectForKey:DATA]];
                }
            }
            
            if ([response.data objectForKey:DATA]) {
                [PreferenceHelper setSessionParams:[response.data objectForKey:DATA]];
            } else {
                [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
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
                    if (self.urlLoadCallback) self.urlLoadCallback(url);
                });
            }
        } else if ([requestTag isEqualToString:REQ_TAG_LOGOUT]) {
            [PreferenceHelper setSessionID:[response.data objectForKey:SESSION_ID]];
            [PreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [PreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            
            [PreferenceHelper setUserIdentity:NO_STRING_VALUE];
            [PreferenceHelper setInstallParams:NO_STRING_VALUE];
            [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            [PreferenceHelper clearUserCreditsAndCounts];
        } else if ([requestTag isEqualToString:REQ_TAG_IDENTIFY]) {
            [PreferenceHelper setIdentityID:[response.data objectForKey:IDENTITY_ID]];
            [PreferenceHelper setUserURL:[response.data objectForKey:LINK]];
            
            if ([response.data objectForKey:REFERRING_DATA]) {
                [PreferenceHelper setInstallParams:[response.data objectForKey:REFERRING_DATA]];
            }
            
            if (self.requestQueue.size > 0) {
                ServerRequest *req = [self.requestQueue peek];
                if (req.postData && [req.postData objectForKey:IDENTITY]) {
                    [PreferenceHelper setUserIdentity:[req.postData objectForKey:IDENTITY]];
                }
            }
            
            if (self.installparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.installparamLoadCallback) self.installparamLoadCallback([self getInstallReferringParams]);
                });
            }
        } else if ([requestTag isEqualToString:REQ_TAG_COMPLETE_ACTION] || [requestTag isEqualToString:REQ_TAG_PROFILE_DATA] || [requestTag isEqualToString:REQ_TAG_REDEEM_REWARDS] || [requestTag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
        }
        
        if (!retry) {
            [self.requestQueue dequeue];
            
            dispatch_async(self.asyncQueue, ^{
                [self processNextQueueItem];
            });
        }
    }
}

@end

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
#import "SystemObserver.h"

@interface Branch() <ServerInterfaceDelegate>

@property (strong, nonatomic) BranchServerInterface *bServerInterface;

@property (nonatomic) BOOL isInit;

@property (strong, nonatomic) NSTimer *sessionTimer;
@property (strong, nonatomic) NSMutableArray *uploadQueue;
@property (nonatomic) dispatch_semaphore_t processing_sema;
@property (nonatomic) dispatch_queue_t asyncQueue;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger networkCount;
@property (strong, nonatomic) callbackWithStatus pointLoadCallback;
@property (strong, nonatomic) callbackWithStatus rewardLoadCallback;
@property (strong, nonatomic) callbackWithParams sessionparamLoadCallback;
@property (strong, nonatomic) callbackWithParams installparamLoadCallback;
@property (strong, nonatomic) callbackWithUrl urlLoadCallback;

@end

@implementation Branch

static const NSInteger RETRY_INTERVAL = 3;
static const NSInteger MAX_RETRIES = 5;

static Branch *currInstance;

// PUBLIC CALLS

+ (Branch *)getInstance:(NSString *)key {
    if (!currInstance) {
        [Branch initInstance];
        [PreferenceHelper setAppKey:key];
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
    currInstance.isInit = false;
    currInstance.bServerInterface = [[BranchServerInterface alloc] init];
    currInstance.bServerInterface.delegate = currInstance;
    currInstance.processing_sema = dispatch_semaphore_create(1);
    currInstance.asyncQueue = dispatch_queue_create("brnch_upload_queue", NULL);
    currInstance.uploadQueue = [[NSMutableArray alloc] init];
    
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
    } else if ([self hasUser] && [self hasSession] && ![self installOrOpenInQueue]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
    } else {
        if ((![self hasUser] || ![self hasSession]) && ![self installOrOpenInQueue]) {
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

- (void)identifyUser:(NSString *)userId withCallback:(callbackWithParams)callback {
    self.installparamLoadCallback = callback;
    [self identifyUser:userId];
}

- (void)identifyUser:(NSString *)userId {
    if (!userId)
        return;
    if ([self hasIdentity])
        return;
    if (![self identifyInQueue]) {
        dispatch_async(self.asyncQueue, ^{
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_IDENTIFY;
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[userId, [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[@"identity", @"app_id", @"identity_id"]];
            req.postData = post;
            [self.uploadQueue addObject:req];
            [self processNextQueueItem];
        });
    }
}

- (void)clearUser {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[[PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[@"app_id", @"session_id"]];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)loadActionCountsWithCallback:(callbackWithStatus)callback {
    self.pointLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRAL_COUNTS;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)loadRewardsWithCallback:(callbackWithStatus)callback {
    self.rewardLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REWARDS;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
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
            NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[bucket, [NSNumber numberWithInteger:redemptionsToAdd], [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[@"bucket", @"amount", @"app_id", @"identity_id"]];
            req.postData = post;
            [self.uploadQueue addObject:req];
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
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[action, [PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[@"event", @"app_id", @"session_id"]];
        NSDictionary *saniState = [self sanitizeQuotesFromInput:state];
        if (saniState && [NSJSONSerialization isValidJSONObject:saniState]) [post setObject:saniState forKey:@"metadata"];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
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

- (NSString *)getLongURL {
    return [self generateLongUrl:nil andParams:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params {
    return [self generateLongUrl:nil andParams:[PreferenceHelper base64EncodeStringToString:[BranchServerInterface encodePostToUniversalString:[self sanitizeQuotesFromInput:params]]]];
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

- (NSString *)generateLongUrl:(NSString *)tag andParams:(NSString *)params {
    if ([self hasUser]) {
        NSString *url = [PreferenceHelper getUserURL];
        if (tag) {
            url = [[url stringByAppendingString:@"?t="] stringByAppendingString:tag];
            if (params) {
                url = [[url stringByAppendingString:@"&d="] stringByAppendingString:params];
            }
        } else if (params) {
            url = [[url stringByAppendingString:@"?d="] stringByAppendingString:params];
        }
        return url;
    } else {
        return @"init incomplete, did you call init yet?";
    }
}

- (void)generateShortUrl:(NSArray *)tags andChannel:(NSString *)channel andFeature:(NSString *)feature andStage:(NSString *)stage andParams:(NSString *)params andCallback:(callbackWithUrl)callback {
    self.urlLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_CUSTOM_URL;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
        [post setObject:[PreferenceHelper getAppKey] forKey:@"app_id"];
        [post setObject:[PreferenceHelper getIdentityID] forKey:@"identity_id"];
        if (tags)
            [post setObject:tags forKey:@"tags"];
        if (channel)
            [post setObject:channel forKey:@"channel"];
        if (feature)
            [post setObject:feature forKey:@"feature"];
        if (stage)
            [post setObject:stage forKey:@"stage"];
        if (params)
            [post setObject:params forKey:@"data"];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)applicationDidBecomeActive {
    dispatch_async(self.asyncQueue, ^{
        if (!self.isInit) {
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_REGISTER_OPEN;
            [self.uploadQueue addObject:req];
            [self processNextQueueItem];
        }
    });
}
- (void)applicationWillResignActive {
    [self clearTimer];
    self.sessionTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(callClose) userInfo:nil repeats:NO];
}

- (void)clearTimer {
    [self.sessionTimer invalidate];
}

- (void)callClose {
    dispatch_async(self.asyncQueue, ^{
        self.isInit = NO;
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_REGISTER_CLOSE;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
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
        NSString *val = [[kv objectAtIndex:1]
                         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [params setObject:val forKey:[kv objectAtIndex:0]];
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
    if (self.networkCount == 0 && [self.uploadQueue count] > 0) {
        self.networkCount = 1;
        dispatch_semaphore_signal(self.processing_sema);
        
        ServerRequest *req = [self.uploadQueue objectAtIndex:0];

        if (![req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
            [self clearTimer];
        }
        
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            if (LOG) NSLog(@"calling register install");
            [self.bServerInterface registerInstall];
        } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_OPEN] && [self hasUser]) {
            if (LOG) NSLog(@"calling register open");
            [self.bServerInterface registerOpen];
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling get referrals");
            [self.bServerInterface getReferralCounts];
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling get rewards");
            [self.bServerInterface getRewards];
        } else if ([req.tag isEqualToString:REQ_TAG_REDEEM_REWARDS] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling redeem rewards");
            [self.bServerInterface redeemRewards:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_COMPLETE_ACTION] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling completed action");
            [self.bServerInterface userCompletedAction:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling create custom url");
            [self.bServerInterface createCustomUrl:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface identifyUser:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_LOGOUT] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface logoutUser:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE] && [self hasUser] && [self hasSession]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface registerClose];
        } else if (![self hasUser]) {
            if (![self hasAppKey] && [self hasSession]) {
                NSLog(@"Branch Warning: User session not init yet. Please call initUserSession");
            } else {
                self.networkCount = 0;
                [self initUserSession];
            }
        }
    } else {
        dispatch_semaphore_signal(self.processing_sema);
    }
   
}

- (void)retryLastRequest {
    self.retryCount = self.retryCount + 1;
    if (self.retryCount > MAX_RETRIES) {
        ServerRequest *req = [self.uploadQueue objectAtIndex:0];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            NSDictionary *errorDict = [[NSDictionary alloc] initWithObjects:@[@"Trouble reaching server. Please try again in a few minutes"] forKeys:@[@"error"]];
            if (self.sessionparamLoadCallback) self.sessionparamLoadCallback(errorDict);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
            if (self.pointLoadCallback) self.pointLoadCallback(NO);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REWARDS]) {
            if (self.rewardLoadCallback) self.rewardLoadCallback(NO);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            if (self.urlLoadCallback) self.urlLoadCallback(@"Trouble reaching server. Please try again in a few minutes");
        } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
            NSDictionary *errorDict = [[NSDictionary alloc] initWithObjects:@[@"Trouble reaching server. Please try again in a few minutes"] forKeys:@[@"error"]];
            if (self.installparamLoadCallback) self.installparamLoadCallback(errorDict);
        }
        [self.uploadQueue removeObjectAtIndex:0];
        self.retryCount = 0;
    } else {
        [NSThread sleepForTimeInterval:RETRY_INTERVAL];
    }
    [self processNextQueueItem];
}

- (void)updateAllRequestsInQueue {
    for (ServerRequest *request in self.uploadQueue) {
        if (request.postData) {
            for (NSString *key in [request.postData allKeys]) {
                if ([key isEqualToString:@"app_id"]) {
                    [request.postData setValue:[PreferenceHelper getAppKey] forKey:@"app_id"];
                } else if ([key isEqualToString:@"session_id"]) {
                    [request.postData setValue:[PreferenceHelper getSessionID] forKey:@"session_id"];
                } else if ([key isEqualToString:@"identity_id"]) {
                    [request.postData setValue:[PreferenceHelper getIdentityID] forKey:@"identity_id"];
                }
            }
        }
    }
}

- (BOOL)identifyInQueue {
    for (ServerRequest *req in self.uploadQueue) {
        if ([req.tag isEqualToString:REQ_TAG_IDENTIFY]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)installOrOpenInQueue {
    for (ServerRequest *req in self.uploadQueue) {
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL] || [req.tag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            return YES;
        }
    }
    return NO;
}

- (void)moveInstallToFront {
    for (int i = 0; i < [self.uploadQueue count]; i++) {
        ServerRequest *req = [self.uploadQueue objectAtIndex:i];
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            [self.uploadQueue removeObjectAtIndex:i];
            i--;
            break;
        }
    }
    ServerRequest *req = [[ServerRequest alloc] init];
    req.postData = nil;
    req.tag = REQ_TAG_REGISTER_INSTALL;
    [self.uploadQueue insertObject:req atIndex:0];
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

- (void)registerInstall {
    if (![self installOrOpenInQueue]) {
        ServerRequest *req = [[ServerRequest alloc] init];
        req.postData = nil;
        req.tag = REQ_TAG_REGISTER_INSTALL;
        [self.uploadQueue insertObject:req atIndex:0];
    } else {
        [self moveInstallToFront];
    }
    dispatch_async(self.asyncQueue, ^{
        [self processNextQueueItem];
    });
}

- (void)registerOpen {
    ServerRequest *req = [[ServerRequest alloc] init];
    req.postData = nil;
    req.tag = REQ_TAG_REGISTER_OPEN;
    [self.uploadQueue insertObject:req atIndex:0];
    dispatch_async(self.asyncQueue, ^{
        [self processNextQueueItem];
    });
}

-(void)initSession {
    if ([self hasUser]) {
        [self registerOpen];
    } else {
        [self registerInstall];
    }
}

-(void)processReferralCounts:(NSDictionary *)returnedData {
    BOOL updateListener = NO;
    
    for (NSString *key in returnedData) {
        if ([key isEqualToString:kpServerStatusCode] || [key isEqualToString:kpServerRequestTag])
            continue;
        
        NSDictionary *counts = [returnedData objectForKey:key];
        NSInteger total = [[counts objectForKey:@"total"] integerValue];
        NSInteger unique = [[counts objectForKey:@"unique"] integerValue];
        
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
        if ([key isEqualToString:kpServerStatusCode] || [key isEqualToString:kpServerRequestTag])
            continue;
        
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

- (void)serverCallback:(NSDictionary *)returnedData {
    if (returnedData) {
        NSInteger status = [[returnedData objectForKey:kpServerStatusCode] integerValue];
        NSString *requestTag = [returnedData objectForKey:kpServerRequestTag];
        
        BOOL retry = NO;
        self.networkCount = 0;
        if (status >= 400 && status < 500) {
            NSLog(@"Branch API Error: %@", [returnedData objectForKey:@"message"]);
            [self.uploadQueue removeObjectAtIndex:0];
        } else if (status != 200) {
            retry = YES;
            dispatch_async(self.asyncQueue, ^{
                [self retryLastRequest];
            });
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            [PreferenceHelper setDeviceFingerprintID:[returnedData objectForKey:@"device_fingerprint_id"]];
            [PreferenceHelper setUserURL:[returnedData objectForKey:@"link"]];
            [PreferenceHelper setSessionID:[returnedData objectForKey:@"session_id"]];
            
            if ([PreferenceHelper getIsReferrable]) {
                if ([returnedData objectForKey:@"data"]) {
                    [PreferenceHelper setInstallParams:[returnedData objectForKey:@"data"]];
                } else {
                    [PreferenceHelper setInstallParams:NO_STRING_VALUE];
                }
            }
            [PreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([returnedData objectForKey:@"link_click_id"]) {
                [PreferenceHelper setLinkClickID:[returnedData objectForKey:@"link_click_id"]];
            } else {
                [PreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            if ([returnedData objectForKey:@"data"]) {
                [PreferenceHelper setSessionParams:[returnedData objectForKey:@"data"]];
            } else {
                [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            
            [self updateAllRequestsInQueue];
            
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                     if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_OPEN]) {
            [PreferenceHelper setSessionID:[returnedData objectForKey:@"session_id"]];
            if ([returnedData objectForKey:@"link_click_id"]) {
                [PreferenceHelper setLinkClickID:[returnedData objectForKey:@"link_click_id"]];
            } else {
                [PreferenceHelper setLinkClickID:NO_STRING_VALUE];
            }
            [PreferenceHelper setLinkClickIdentifier:NO_STRING_VALUE];
            
            if ([PreferenceHelper getIsReferrable]) {
                if ([returnedData objectForKey:@"data"]) {
                    [PreferenceHelper setInstallParams:[returnedData objectForKey:@"data"]];
                }
            }
            
            if ([returnedData objectForKey:@"data"]) {
                [PreferenceHelper setSessionParams:[returnedData objectForKey:@"data"]];
            } else {
                [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REWARDS]) {
            [self processReferralCredits:returnedData];
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REFERRAL_COUNTS]) {
            [self processReferralCounts:returnedData];
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            NSString *url = [returnedData objectForKey:@"url"];
            if (self.urlLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.urlLoadCallback) self.urlLoadCallback(url);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_LOGOUT]) {
            [PreferenceHelper setSessionID:[returnedData objectForKey:@"session_id"]];
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            [PreferenceHelper setUserURL:[returnedData objectForKey:@"link"]];
            
            [PreferenceHelper setUserIdentity:NO_STRING_VALUE];
            [PreferenceHelper setInstallParams:NO_STRING_VALUE];
            [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            [PreferenceHelper clearUserCreditsAndCounts];
            
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_IDENTIFY]) {
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            [PreferenceHelper setUserURL:[returnedData objectForKey:@"link"]];
            
            if ([returnedData objectForKey:@"referring_data"]) {
                [PreferenceHelper setInstallParams:[returnedData objectForKey:@"referring_data"]];
            }
            
            if ([self.uploadQueue objectAtIndex:0]) {
                ServerRequest *req = [self.uploadQueue objectAtIndex:0];
                if (req.postData && [req.postData objectForKey:@"identity"]) {
                    [PreferenceHelper setUserIdentity:[req.postData objectForKey:@"identity"]];
                }
            }
            
            if (self.installparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.installparamLoadCallback) self.installparamLoadCallback([self getInstallReferringParams]);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_COMPLETE_ACTION] || [requestTag isEqualToString:REQ_TAG_PROFILE_DATA] || [requestTag isEqualToString:REQ_TAG_REGISTER_CLOSE] || [requestTag isEqualToString:REQ_TAG_REDEEM_REWARDS]) {
            [self.uploadQueue removeObjectAtIndex:0];
        }
        
        if (!retry) {
            dispatch_async(self.asyncQueue, ^{
                [self processNextQueueItem];
            });
        }
    }
}

@end

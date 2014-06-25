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

@interface Branch() <ServerInterfaceDelegate>

@property (strong, nonatomic) BranchServerInterface *bServerInterface;

@property (nonatomic) BOOL isInit;

@property (strong, nonatomic) NSMutableArray *uploadQueue;
@property (nonatomic) dispatch_semaphore_t processing_sema;
@property (nonatomic) dispatch_queue_t asyncQueue;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger networkCount;
@property (strong, nonatomic) callbackWithStatus pointLoadCallback;
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
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        currInstance.retryCount = 0;
        currInstance.networkCount = 0;
        [PreferenceHelper setAppKey:key];
    }
    return currInstance;
}

+ (Branch *)getInstance {
    if (!currInstance) {
        NSLog(@"Branch Warning: getInstance called before getInstance with key. Please init");
    }
    return currInstance;
}

- (void)resetUserSession {
    if (self) {
        self.isInit = NO;
    }
}

- (void)initUserSession {
    [self initUserSessionWithCallback:nil];
}

- (void)initUserSessionWithCallback:(callbackWithParams)callback {
    self.sessionparamLoadCallback = callback;
    if (!self.isInit) {
        self.isInit = YES;
        [self initSession];
    } else if (![self installInQueue]) {
        if (self.sessionparamLoadCallback) self.sessionparamLoadCallback([self getReferringParams]);
    }
}

- (void)identifyUser:(NSString *)userId withCallback:(callbackWithParams)callback {
    self.installparamLoadCallback = callback;
    [self identifyUser:userId];
}

- (void)identifyUser:(NSString *)userId {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_IDENTIFY;
        NSDictionary *post = [[NSDictionary alloc] initWithObjects:@[userId, [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[@"identity", @"app_id", @"identity_id"]];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)clearUser {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_LOGOUT;
        NSDictionary *post = [[NSDictionary alloc] initWithObjects:@[[PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[@"app_id", @"session_id"]];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)loadPointsWithCallback:(callbackWithStatus)callback {
    self.pointLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_REFERRALS;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)creditUserForReferralAction:(NSString *)action withCredits:(NSInteger)credits {
    dispatch_async(self.asyncQueue, ^{
        NSInteger creditsToAdd = 0;
        NSInteger total = [PreferenceHelper getActionTotalCount:action];
        NSInteger prevCredits = [PreferenceHelper getActionCreditCount:action];
        if ((prevCredits+credits) > total) {
            creditsToAdd = total - prevCredits;
        } else {
            creditsToAdd = credits;
        }
        
        if (creditsToAdd > 0) {
            ServerRequest *req = [[ServerRequest alloc] init];
            req.tag = REQ_TAG_CREDIT_ACTION;
            NSDictionary *post = [[NSDictionary alloc] initWithObjects:@[action, [NSNumber numberWithInteger:credits], [PreferenceHelper getAppKey], [PreferenceHelper getIdentityID]] forKeys:@[@"event", @"credit", @"app_id", @"identity_id"]];
            req.postData = post;
            [self.uploadQueue addObject:req];
            [self processNextQueueItem];
        }
    });
}

- (void)userCompletedAction:(NSString *)action {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_COMPLETE_ACTION;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] initWithObjects:@[action, [PreferenceHelper getAppKey], [PreferenceHelper getSessionID]] forKeys:@[@"event", @"app_id", @"session_id"]];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (NSInteger)getTotalPointsForAction:(NSString *)action {
    return [PreferenceHelper getActionTotalCount:action];
}

- (NSInteger)getCreditsForAction:(NSString *)action {
    return [PreferenceHelper getActionCreditCount:action];
}

- (NSInteger)getBalanceOfPointsForAction:(NSString *)action {
    return [PreferenceHelper getActionBalanceCount:action];
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
    return [self generateLongUrl:nil andParams:[PreferenceHelper base64EncodeStringToString:[BranchServerInterface encodePostToUniversalString:params]]];
}

- (NSString *)getLongURLWithTag:(NSString *)tag {
    return [self generateLongUrl:tag andParams:nil];
}

- (NSString *)getLongURLWithParams:(NSDictionary *)params andTag:(NSString *)tag {
    return [self generateLongUrl:tag andParams:[PreferenceHelper base64EncodeStringToString:[BranchServerInterface encodePostToUniversalString:params]]];
}

- (void)getShortURLWithCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andParams:nil andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:nil andParams:[BranchServerInterface encodePostToUniversalString:params] andCallback:callback];
}

- (void)getShortURLWithTag:(NSString *)tag andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tag andParams:nil andCallback:callback];
}

- (void)getShortURLWithParams:(NSDictionary *)params andTag:(NSString *)tag andCallback:(callbackWithUrl)callback {
    [self generateShortUrl:tag andParams:[BranchServerInterface encodePostToUniversalString:params] andCallback:callback];
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

- (void)generateShortUrl:(NSString *)tag andParams:(NSString *)params andCallback:(callbackWithUrl)callback {
    self.urlLoadCallback = callback;
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_GET_CUSTOM_URL;
        NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
        [post setObject:[PreferenceHelper getAppKey] forKey:@"app_id"];
        [post setObject:[PreferenceHelper getIdentityID] forKey:@"identity_id"];
        if (tag)
            [post setObject:tag forKey:@"tag"];
        if (params)
            [post setObject:params forKey:@"data"];
        req.postData = post;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}

- (void)applicationDidBecomeActive {
    dispatch_async(self.asyncQueue, ^{
        ServerRequest *req = [[ServerRequest alloc] init];
        req.tag = REQ_TAG_REGISTER_OPEN;
        [self.uploadQueue addObject:req];
        [self processNextQueueItem];
    });
}
- (void)applicationWillResignActive {
     dispatch_async(self.asyncQueue, ^{
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)processNextQueueItem {
    dispatch_semaphore_wait(self.processing_sema, DISPATCH_TIME_FOREVER);
    if (self.networkCount == 0 && [self.uploadQueue count] > 0) {
        self.networkCount = 1;
        dispatch_semaphore_signal(self.processing_sema);
        
        ServerRequest *req = [self.uploadQueue objectAtIndex:0];
        
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            if (LOG) NSLog(@"calling register install");
            [self.bServerInterface registerInstall];
        } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_OPEN] && [self hasUser]) {
            if (LOG) NSLog(@"calling register open");
            [self.bServerInterface registerOpen];
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRALS] && [self hasUser]) {
            if (LOG) NSLog(@"calling get referrals");
            [self.bServerInterface getReferrals];
        } else if ([req.tag isEqualToString:REQ_TAG_CREDIT_ACTION] && [self hasUser]) {
            if (LOG) NSLog(@"calling credit referrals");
            [self.bServerInterface creditUserForReferrals:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_COMPLETE_ACTION] && [self hasUser]) {
            if (LOG) NSLog(@"calling completed action");
            [self.bServerInterface userCompletedAction:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL] && [self hasUser]) {
            if (LOG) NSLog(@"calling create custom url");
            [self.bServerInterface createCustomUrl:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_IDENTIFY] && [self hasUser]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface identifyUser:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_LOGOUT] && [self hasUser]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface logoutUser:req.postData];
        } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_CLOSE] && [self hasUser]) {
            if (LOG) NSLog(@"calling identify user");
            [self.bServerInterface registerClose];
        } else if (![self hasUser]) {
            NSLog(@"Branch Warning: User session not init yet. Please call initUserSession");
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
        } else if ([req.tag isEqualToString:REQ_TAG_GET_REFERRALS]) {
            if (self.pointLoadCallback) self.pointLoadCallback(NO);
        } else if ([req.tag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            if (self.urlLoadCallback) self.urlLoadCallback(@"Trouble reaching server. Please try again in a few minutes");
        } else if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            NSDictionary *errorDict = [[NSDictionary alloc] initWithObjects:@[@"Trouble reaching server. Please try again in a few minutes"] forKeys:@[@"error"]];
            if (self.installparamLoadCallback) self.installparamLoadCallback(errorDict);
        }
        [self.uploadQueue removeObjectAtIndex:0];
        self.retryCount = 0;
    } else {
        [NSThread sleepForTimeInterval:RETRY_INTERVAL];
    }
}


- (BOOL)installInQueue {
    for (ServerRequest *req in self.uploadQueue) {
        if ([req.tag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
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

- (BOOL)hasUser {
    return ![[PreferenceHelper getIdentityID] isEqualToString:NO_STRING_VALUE];
}

- (void)registerInstall {
    if (![self installInQueue]) {
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
    BOOL updateListener = false;
    
    for (NSString *key in returnedData) {
        if ([key isEqualToString:kpServerStatusCode] || [key isEqualToString:kpServerRequestTag])
            continue;
        
        NSDictionary *counts = [returnedData objectForKey:key];
        NSInteger total = [[counts objectForKey:@"total"] integerValue];
        NSInteger credits = [[counts objectForKey:@"credits"] integerValue];
        if (total != [PreferenceHelper getActionTotalCount:key] || credits != [PreferenceHelper getActionCreditCount:key]) {
            updateListener = YES;
        }
        [PreferenceHelper setActionTotalCount:key withCount:total];
        [PreferenceHelper setActionCreditCount:key withCount:credits];
        [PreferenceHelper setActionBalanceCount:key withCount:MAX(0, total-credits)];
    }
    if (self.pointLoadCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.pointLoadCallback(updateListener);
        });
    }
}

- (void)serverCallback:(NSDictionary *)returnedData {
    if (returnedData) {
        NSInteger status = [[returnedData objectForKey:kpServerStatusCode] integerValue];
        NSString *requestTag = [returnedData objectForKey:kpServerRequestTag];
        
        
        self.networkCount = 0;
        if (status != 200) {
            [self retryLastRequest];
        } else if ([requestTag isEqualToString:REQ_TAG_REGISTER_INSTALL]) {
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            [PreferenceHelper setDeviceFingerprintID:[returnedData objectForKey:@"device_fingerprint_id"]];
            [PreferenceHelper setUserURL:[returnedData objectForKey:@"link"]];
            [PreferenceHelper setSessionID:[returnedData objectForKey:@"session_id"]];
            
            ServerRequest *req = [self.uploadQueue objectAtIndex:0];
            if (req.postData && ![req.postData objectForKey:@"update"]) {
                if ([returnedData objectForKey:@"data"]) {
                    [PreferenceHelper setInstallParams:[returnedData objectForKey:@"data"]];
                } else {
                    [PreferenceHelper setInstallParams:NO_STRING_VALUE];
                }
            }
            
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
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                     self.sessionparamLoadCallback([self getReferringParams]);
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
            if ([returnedData objectForKey:@"data"]) {
                [PreferenceHelper setSessionParams:[returnedData objectForKey:@"data"]];
            } else {
                [PreferenceHelper setSessionParams:NO_STRING_VALUE];
            }
            if (self.sessionparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.sessionparamLoadCallback([self getReferringParams]);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_REFERRALS]) {
            [self processReferralCounts:returnedData];
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_CREDIT_ACTION]) {
            ServerRequest *req = [self.uploadQueue objectAtIndex:0];
            NSString *action = [req.postData objectForKey:@"event"];
            int credits = [[req.postData objectForKey:@"credit"] intValue];
            [PreferenceHelper setActionCreditCount:action withCount:[PreferenceHelper getActionCreditCount:action] + credits];
            [PreferenceHelper setActionBalanceCount:action withCount:MAX(0, [PreferenceHelper getActionTotalCount:action]-[PreferenceHelper getActionCreditCount:action])];
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_GET_CUSTOM_URL]) {
            NSString *url = [returnedData objectForKey:@"url"];
            if (self.urlLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.urlLoadCallback(url);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_LOGOUT]) {
            [PreferenceHelper setSessionID:[returnedData objectForKey:@"session_id"]];
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_IDENTIFY]) {
            [PreferenceHelper setIdentityID:[returnedData objectForKey:@"identity_id"]];
            if ([returnedData objectForKey:@"data"]) {
                [PreferenceHelper setInstallParams:[returnedData objectForKey:@"data"]];
            } else {
                [PreferenceHelper setInstallParams:NO_STRING_VALUE];
            }
            if (self.installparamLoadCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.installparamLoadCallback([self getInstallReferringParams]);
                });
            }
            [self.uploadQueue removeObjectAtIndex:0];
        } else if ([requestTag isEqualToString:REQ_TAG_COMPLETE_ACTION] || [requestTag isEqualToString:REQ_TAG_IDENTIFY] || [requestTag isEqualToString:REQ_TAG_PROFILE_DATA] || [requestTag isEqualToString:REQ_TAG_REGISTER_CLOSE]) {
            [self.uploadQueue removeObjectAtIndex:0];
        }
        
        dispatch_async(self.asyncQueue, ^{
            [self processNextQueueItem];
        });
    }
}

@end

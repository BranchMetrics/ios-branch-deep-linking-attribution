//
//  BNCPreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCConfig.h"
#import "Branch.h"

static const NSInteger DEFAULT_TIMEOUT = 3;
static const NSInteger DEFAULT_RETRY_INTERVAL = 3;
static const NSInteger DEFAULT_RETRY_COUNT = 5;
static const NSInteger APP_READ_INTERVAL = 520000;

static NSString *KEY_APP_KEY = @"bnc_app_key";
static NSString *KEY_APP_VERSION = @"bnc_app_version";
static NSString *KEY_LAST_RUN_BRANCH_KEY = @"bnc_last_run_branch_key";

static NSString *KEY_DEVICE_FINGERPRINT_ID = @"bnc_device_fingerprint_id";
static NSString *KEY_SESSION_ID = @"bnc_session_id";
static NSString *KEY_IDENTITY_ID = @"bnc_identity_id";
static NSString *KEY_IDENTITY = @"bnc_identity";
static NSString *KEY_LINK_CLICK_IDENTIFIER = @"bnc_link_click_identifier";
static NSString *KEY_LINK_CLICK_ID = @"bnc_link_click_id";
static NSString *KEY_SESSION_PARAMS = @"bnc_session_params";
static NSString *KEY_INSTALL_PARAMS = @"bnc_install_params";
static NSString *KEY_USER_URL = @"bnc_user_url";
static NSString *KEY_IS_REFERRABLE = @"bnc_is_referrable";
static NSString *KEY_APP_LIST_CHECK = @"bnc_app_list_check";

static NSString *KEY_CREDITS = @"bnc_credits";
static NSString *KEY_CREDIT_BASE = @"bnc_credit_base_";

static NSString *KEY_COUNTS = @"bnc_counts";
static NSString *KEY_TOTAL_BASE = @"bnc_total_base_";
static NSString *KEY_UNIQUE_BASE = @"bnc_unique_base_";

@interface BNCPreferenceHelper ()

@property (strong, nonatomic) NSString *branchKey;
@property (assign, nonatomic) BOOL isUsingLiveKey;
@property (assign, nonatomic) BOOL isDebugMode;
@property (assign, nonatomic) BOOL isConnectedToRemoteDebug;

@end

@implementation BNCPreferenceHelper

- (id)init {
    if (self = [super init]) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
        
        _isDebugMode = NO;
        _isConnectedToRemoteDebug = NO;
    }
    
    return self;
}

+ (BNCPreferenceHelper *)getInstance {
    static BNCPreferenceHelper *preferenceHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[BNCPreferenceHelper alloc] init];
    });
    
    return preferenceHelper;
}


#pragma mark - Debug methods

+ (void)setDebug:(BOOL)debug {
    [BNCPreferenceHelper getInstance].isDebugMode = debug;
}

+ (void)clearDebug {
    [BNCPreferenceHelper getInstance].isDebugMode = NO;
    [BNCPreferenceHelper getInstance].isConnectedToRemoteDebug = NO;
}

+ (BOOL)isDebug {
    return [BNCPreferenceHelper getInstance].isDebugMode;
}

+ (void)setConnectedToRemoteDebug:(BOOL)connectedToRemoteDebug {
    [BNCPreferenceHelper getInstance].isConnectedToRemoteDebug = connectedToRemoteDebug;
}

+ (BOOL)isConnectedToRemoteDebug {
    return [BNCPreferenceHelper getInstance].isConnectedToRemoteDebug;
}

+ (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if ([BNCPreferenceHelper getInstance].isDebugMode) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
        
        if ([BNCPreferenceHelper getInstance].isConnectedToRemoteDebug) {
            [[Branch getInstance] log:log];
        }
    }
}

+ (NSString *)getAPIBaseURL {
    return [NSString stringWithFormat:@"%@/%@/", BNC_API_BASE_URL, BNC_API_VERSION];
}

+ (NSString *)getAPIURL:(NSString *) endpoint {
    return [[BNCPreferenceHelper getAPIBaseURL] stringByAppendingString:endpoint];
}

#pragma mark - Preference Storage

+ (void)setTimeout:(NSInteger)timeout {
    [BNCPreferenceHelper getInstance].timeout = timeout;
}

+ (NSInteger)getTimeout {
    return [BNCPreferenceHelper getInstance].timeout;
}

+ (void)setRetryInterval:(NSInteger)retryInterval {
    [BNCPreferenceHelper getInstance].retryInterval = retryInterval;
}

+ (NSInteger)getRetryInterval {
    return [BNCPreferenceHelper getInstance].retryInterval;
}

+ (void)setRetryCount:(NSInteger)retryCount {
    [BNCPreferenceHelper getInstance].retryCount = retryCount;
}

+ (NSInteger)getRetryCount {
    return [BNCPreferenceHelper getInstance].retryCount;
}

+ (NSString *)getAppKey {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_APP_KEY];
}

+ (void)setAppKey:(NSString *)appKey {
    NSLog(@"Usage of App Key is deprecated, please move toward using a Branch key");
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_KEY value:appKey];
}

+ (NSString *)getBranchKey:(BOOL)isLive {
    BNCPreferenceHelper *instance = [BNCPreferenceHelper getInstance];
    NSString *key = instance.branchKey;
    
    if (key && isLive == instance.isUsingLiveKey) {
        return key;
    }
    
    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"branch_key"];
    if (ret) {
        if ([ret isKindOfClass:[NSString class]]) {
            key = ret;
        }
        else if ([ret isKindOfClass:[NSDictionary class]]) {
            key = isLive ? ret[@"live"] : ret[@"test"];
        }
    }
    
    [BNCPreferenceHelper setBranchKey:key];
    instance.isUsingLiveKey = isLive;
    
    return key;
}

+ (void)setBranchKey:(NSString *)branchKey {
    [BNCPreferenceHelper getInstance].branchKey = branchKey;
}

+ (NSString *)getLastRunBranchKey {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_LAST_RUN_BRANCH_KEY];
}

+ (void)setLastRunBranchKey:(NSString *)lastRunBranchKey {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LAST_RUN_BRANCH_KEY value:lastRunBranchKey];
}

+(NSString *)getAppVersion {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_APP_VERSION];
}

+(void)setAppVersion:(NSString *)appVersion {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_VERSION value:appVersion];
}

+ (void)setDeviceFingerprintID:(NSString *)deviceID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_DEVICE_FINGERPRINT_ID value:deviceID];
}

+ (NSString *)getDeviceFingerprintID {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_DEVICE_FINGERPRINT_ID];
}

+ (void)setSessionID:(NSString *)sessionID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_ID value:sessionID];
}

+ (NSString *)getSessionID {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_ID];
}

+ (void)setIdentityID:(NSString *)identityID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY_ID value:identityID];
}

+ (NSString *)getIdentityID {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY_ID];
}

+ (void)setUserIdentity:(NSString *)userIdentity {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY value:userIdentity];
}

+ (NSString *)getUserIdentity {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY];
}

+ (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
}

+ (NSString *)getLinkClickIdentifier {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_IDENTIFIER];
}

+ (void)setLinkClickID:(NSString *)linkClickId {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_ID value:linkClickId];
}

+ (NSString *)getLinkClickID {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_ID];
}

+ (void)setSessionParams:(NSString *)sessionParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_PARAMS value:sessionParams];
}

+ (NSString *)getSessionParams {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_PARAMS];
}

+ (void)setInstallParams:(NSString *)installParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_INSTALL_PARAMS value:installParams];
}

+ (NSString *)getInstallParams {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_INSTALL_PARAMS];
}

+ (void)setUserURL:(NSString *)userUrl {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_USER_URL value:userUrl];
}

+ (NSString *)getUserURL {
    return [BNCPreferenceHelper readStringFromDefaults:KEY_USER_URL];
}

+ (BOOL)getIsReferrable {
    return [BNCPreferenceHelper readBoolFromDefaults:KEY_IS_REFERRABLE];
}

+ (void)setIsReferrable {
    [BNCPreferenceHelper writeBoolToDefaults:KEY_IS_REFERRABLE value:YES];
}

+ (void)clearIsReferrable {
    [BNCPreferenceHelper writeBoolToDefaults:KEY_IS_REFERRABLE value:NO];
}

+ (void)setAppListCheckDone {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_LIST_CHECK value:[NSDate date]];
}

+ (BOOL)getNeedAppListCheck {
    NSDate *lastDate = (NSDate *)[self readObjectFromDefaults:KEY_APP_LIST_CHECK];
    if (lastDate) {
        NSDate *currDate = [NSDate date];
        NSTimeInterval diff = [currDate timeIntervalSinceDate:lastDate];
        if (diff < APP_READ_INTERVAL) {
            return NO;
        }
    }
    return YES;
}

+ (void)clearUserCreditsAndCounts {
    [BNCPreferenceHelper setCreditsDictionary:[[NSDictionary alloc] init]];
    [BNCPreferenceHelper setCountsDictionary:[[NSDictionary alloc] init]];
}

#pragma mark - Credit Storage

+ (NSDictionary *)getCreditsDictionary {
    NSDictionary *dict = (NSDictionary *)[BNCPreferenceHelper readObjectFromDefaults:KEY_CREDITS];
    if (!dict)
        dict = [[NSDictionary alloc] init];
    return dict;
}

+ (void)setCreditsDictionary:(NSDictionary *)credits {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_CREDITS value:credits];
}

+ (void)setCreditCount:(NSInteger)count {
    [self setCreditCount:count forBucket:@"default"];
}

+ (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket {
    NSMutableDictionary *creditDict = [[BNCPreferenceHelper getCreditsDictionary] mutableCopy];
    [creditDict setObject:[NSNumber numberWithInteger:count] forKey:[KEY_CREDIT_BASE stringByAppendingString:bucket]];
    [BNCPreferenceHelper setCreditsDictionary:creditDict];
}

+ (NSInteger)getCreditCount {
    return [self getCreditCountForBucket:@"default"];
}

+ (NSInteger)getCreditCountForBucket:(NSString *)bucket {
    NSDictionary *creditDict = [BNCPreferenceHelper getCreditsDictionary];
    return [[creditDict objectForKey:[KEY_CREDIT_BASE stringByAppendingString:bucket]] integerValue];
}

#pragma mark - Count Storage

+ (NSDictionary *)getCountsDictionary {
    NSDictionary *dict = (NSDictionary *)[BNCPreferenceHelper readObjectFromDefaults:KEY_COUNTS];
    if (!dict)
        dict = [[NSDictionary alloc] init];
    return dict;
}

+ (void)setCountsDictionary:(NSDictionary *)counts {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_COUNTS value:counts];
}

+ (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    NSMutableDictionary *counts = [[BNCPreferenceHelper getCountsDictionary] mutableCopy];
    [counts setObject:[NSNumber numberWithInteger:count] forKey:[KEY_TOTAL_BASE stringByAppendingString:action]];
    [BNCPreferenceHelper setCountsDictionary:counts];
}

+ (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count {
    NSMutableDictionary *counts = [[BNCPreferenceHelper getCountsDictionary] mutableCopy];
    [counts setObject:[NSNumber numberWithInteger:count] forKey:[KEY_UNIQUE_BASE stringByAppendingString:action]];
    [BNCPreferenceHelper setCountsDictionary:counts];
}

+ (NSInteger)getActionTotalCount:(NSString *)action {
    NSDictionary *counts = [BNCPreferenceHelper getCountsDictionary];
    return [[counts objectForKey:[KEY_TOTAL_BASE stringByAppendingString:action]] integerValue];
}

+ (NSInteger)getActionUniqueCount:(NSString *)action {
    NSDictionary *counts = [BNCPreferenceHelper getCountsDictionary];
    return [[counts objectForKey:[KEY_UNIQUE_BASE stringByAppendingString:action]] integerValue];
}

#pragma mark - Writing To Defaults

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

#pragma mark - Reading From Defaults

+ (NSObject *)readObjectFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *obj = [defaults objectForKey:key];
    return obj;
}

+ (NSString *)readStringFromDefaults:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *str = [defaults stringForKey:key];
    return str;
}

+ (BOOL)readBoolFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL boo = [defaults boolForKey:key];
    return boo;
}

+ (NSInteger)readIntegerFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *number = [defaults objectForKey:key];
    
    if (number) {
        return [number integerValue];
    }
    
    return NSNotFound;
}

@end

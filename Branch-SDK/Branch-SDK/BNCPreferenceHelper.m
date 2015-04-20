//
//  BNCPreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BranchServerInterface.h"
#import "BNCConfig.h"

static const NSInteger DEFAULT_TIMEOUT = 3;
static const NSInteger DEFAULT_RETRY_INTERVAL = 3;
static const NSInteger DEFAULT_RETRY_COUNT = 5;
static const NSInteger APP_READ_INTERVAL = 520000;

static NSString *KEY_APP_KEY = @"bnc_app_key";
static NSString *KEY_APP_VERSION = @"bnc_app_version";

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

static BOOL BNC_Debug = NO;
static BOOL BNC_Dev_Debug = NO;
static BOOL BNC_Remote_Debug = NO;

static dispatch_queue_t bnc_asyncLogQueue = nil;
static id<BNCDebugConnectionDelegate> bnc_asyncDebugConnectionDelegate = nil;
static BranchServerInterface *serverInterface = nil;

static id<BNCTestDelegate> bnc_testDelegate = nil;

static NSString *Branch_Key = nil;

@implementation BNCPreferenceHelper

- (id)init {
    if (self = [super init]) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
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

+ (void)setDebug {
    BNC_Debug = YES;
    
    serverInterface = [[BranchServerInterface alloc] init];
    bnc_asyncLogQueue = dispatch_queue_create("bnc_log_queue", NULL);

    [serverInterface connectToDebugWithCallback:^(BNCServerResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Failed to connect to debug: %@", error);
        }
        else {
            BNC_Remote_Debug = YES;
            [bnc_asyncDebugConnectionDelegate bnc_debugConnectionEstablished];
        }
    }];
}

+ (void)setDevDebug {
    BNC_Dev_Debug = YES;
}

+ (BOOL)getDevDebug {
    return BNC_Dev_Debug;
}

+ (void)clearDebug {
    BNC_Debug = NO;
    
    if (BNC_Remote_Debug) {
        BNC_Remote_Debug = NO;
        
        [serverInterface disconnectFromDebugWithCallback:NULL];
    }
}

+ (BOOL)isDebug {
    return BNC_Debug;
}

+ (BOOL)isRemoteDebug {
    return BNC_Remote_Debug;
}

+ (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if (BNC_Debug || BNC_Dev_Debug) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
        
        if (BNC_Remote_Debug) {
            [serverInterface sendLog:log callback:NULL];
        }
    }
}

+ (void)keepDebugAlive {
    if (BNC_Remote_Debug) {
        [serverInterface sendLog:@"" callback:NULL];
    }
}

+ (void)sendScreenshot:(NSData *)data {
    if (BNC_Remote_Debug) {
        [serverInterface sendScreenshot:data callback:NULL];
    }
}

+ (void)setDebugConnectionDelegate:(id<BNCDebugConnectionDelegate>) debugConnectionDelegate {
    bnc_asyncDebugConnectionDelegate = debugConnectionDelegate;
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
    NSString *ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_APP_KEY];
    if (!ret || ret.length == 0) {
        // for backward compatibility
        ret = [BNCPreferenceHelper readStringFromDefaults:KEY_APP_KEY];
        if (!ret) {
            ret = NO_STRING_VALUE;
        }
    }
    return ret;
}

+ (void)setAppKey:(NSString *)appKey {
    NSLog(@"Usage of App Key is deprecated, please move toward using a Branch key");
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_KEY value:appKey];
}

+ (NSString *)getBranchKey {
    if (!Branch_Key) {
        Branch_Key = [BNCPreferenceHelper getBranchKey:YES];
    }
    
    return Branch_Key;
}

+ (NSString *)getBranchKey:(BOOL)isLive {
    NSString *key = nil;
    
    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_BRANCH_KEY];
    if (ret) {
        if ([ret isKindOfClass:[NSString class]]) {
            key = ret;
        } else if ([ret isKindOfClass:[NSDictionary class]]) {
            key = isLive ? ret[@"live"] : ret[@"test"];
        }
    }
    
    if (!key || key.length == 0) {
        key = NO_STRING_VALUE;
    }
    
    [BNCPreferenceHelper setBranchKey:key];
    
    return key;
}

+ (void)setBranchKey:(NSString *)branchKey {
    Branch_Key = branchKey;
}

+(NSString *)getAppVersion {
    NSString *appVersion = [BNCPreferenceHelper readStringFromDefaults:KEY_APP_VERSION];
    return appVersion;
}

+(void)setAppVersion:(NSString *)appVersion {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_VERSION value:appVersion];
}

+ (void)setDeviceFingerprintID:(NSString *)deviceID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_DEVICE_FINGERPRINT_ID value:deviceID];
}

+ (NSString *)getDeviceFingerprintID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_DEVICE_FINGERPRINT_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setSessionID:(NSString *)sessionID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_ID value:sessionID];
}

+ (NSString *)getSessionID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setIdentityID:(NSString *)identityID {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY_ID value:identityID];
}

+ (NSString *)getIdentityID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserIdentity:(NSString *)userIdentity {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY value:userIdentity];
}
+ (NSString *)getUserIdentity {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;

}

+ (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];

}
+ (NSString *)getLinkClickIdentifier {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_IDENTIFIER];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setLinkClickID:(NSString *)linkClickId {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_ID value:linkClickId];
}

+ (NSString *)getLinkClickID {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_ID];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setSessionParams:(NSString *)sessionParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_PARAMS value:sessionParams];
}

+ (NSString *)getSessionParams {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_PARAMS];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setInstallParams:(NSString *)installParams {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_INSTALL_PARAMS value:installParams];
}

+ (NSString *)getInstallParams {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_INSTALL_PARAMS];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
}

+ (void)setUserURL:(NSString *)userUrl {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_USER_URL value:userUrl];
}

+ (NSString *)getUserURL {
    NSString *ret = [BNCPreferenceHelper readStringFromDefaults:KEY_USER_URL];
    if (!ret)
        ret = NO_STRING_VALUE;
    return ret;
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

+ (void)setTestDelegate:(id<BNCTestDelegate>) testDelegate {
    bnc_testDelegate = testDelegate;
}

+ (void)simulateInitFinished {
    [bnc_testDelegate simulateInitFinished];
}

@end

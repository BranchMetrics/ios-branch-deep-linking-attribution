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

static const NSInteger DEFAULT_TIMEOUT = 5;
static const NSInteger DEFAULT_RETRY_INTERVAL = 0;
static const NSInteger DEFAULT_RETRY_COUNT = 1;
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

@property (strong, nonatomic) NSMutableDictionary *countsDictionary;
@property (strong, nonatomic) NSMutableDictionary *creditsDictionary;
@property (assign, nonatomic) BOOL isUsingLiveKey;

@end

@implementation BNCPreferenceHelper

+ (BNCPreferenceHelper *)preferenceHelper {
    static BNCPreferenceHelper *preferenceHelper;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[BNCPreferenceHelper alloc] init];
    });
    
    return preferenceHelper;
}

- (id)init {
    if (self = [super init]) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
        
        _isDebug = NO;
        _isConnectedToRemoteDebug = NO;
        _isReferrable = [BNCPreferenceHelper readBoolFromDefaults:KEY_IS_REFERRABLE];
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

- (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if (self.isDebug) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
        
        if (self.isConnectedToRemoteDebug) {
            [[Branch getInstance] log:log];
        }
    }
}

- (NSString *)getAPIBaseURL {
    return [NSString stringWithFormat:@"%@/%@/", BNC_API_BASE_URL, BNC_API_VERSION];
}

- (NSString *)getAPIURL:(NSString *) endpoint {
    return [[self getAPIBaseURL] stringByAppendingString:endpoint];
}

#pragma mark - Preference Storage

- (NSString *)getAppKey {
    if (!_appKey) {
        _appKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_APP_KEY];
    }
    
    return _appKey;
}

- (void)setAppKey:(NSString *)appKey {
    NSLog(@"Usage of App Key is deprecated, please move toward using a Branch key");
    
    if (![_appKey isEqualToString:appKey]) {
        _appKey = appKey;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_KEY value:appKey];
    }
}

- (NSString *)getBranchKey:(BOOL)isLive {
    // Already loaded a key, and it's the same state (live/test)
    if (_branchKey && isLive == self.isUsingLiveKey) {
        return _branchKey;
    }
    
    self.isUsingLiveKey = isLive;

    id ret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"branch_key"];
    if (ret) {
        if ([ret isKindOfClass:[NSString class]]) {
            self.branchKey = ret;
        }
        else if ([ret isKindOfClass:[NSDictionary class]]) {
            self.branchKey = isLive ? ret[@"live"] : ret[@"test"];
        }
    }
    
    return _branchKey;
}

- (void)setBranchKey:(NSString *)branchKey {
    _branchKey = branchKey;
}

- (NSString *)getLastRunBranchKey {
    if (!_lastRunBranchKey) {
        _lastRunBranchKey = [BNCPreferenceHelper readStringFromDefaults:KEY_LAST_RUN_BRANCH_KEY];
    }
    
    return _lastRunBranchKey;
}

- (void)setLastRunBranchKey:(NSString *)lastRunBranchKey {
    if (![_lastRunBranchKey isEqualToString:lastRunBranchKey]) {
        _lastRunBranchKey = lastRunBranchKey;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_LAST_RUN_BRANCH_KEY value:lastRunBranchKey];
    }
}

- (NSString *)getAppVersion {
    if (!_appVersion) {
        _appVersion = [BNCPreferenceHelper readStringFromDefaults:KEY_APP_VERSION];
    }
    
    return _appVersion;
}

- (void)setAppVersion:(NSString *)appVersion {
    if (![_appVersion isEqualToString:appVersion]) {
        _appVersion = appVersion;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_VERSION value:appVersion];
    }
}

- (NSString *)getDeviceFingerprintID {
    if (!_deviceFingerprintID) {
        _deviceFingerprintID = [BNCPreferenceHelper readStringFromDefaults:KEY_DEVICE_FINGERPRINT_ID];
    }
    
    return _deviceFingerprintID;
}

- (void)setDeviceFingerprintID:(NSString *)deviceFingerprintID {
    if (![_deviceFingerprintID isEqualToString:deviceFingerprintID]) {
        _deviceFingerprintID = deviceFingerprintID;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_DEVICE_FINGERPRINT_ID value:deviceFingerprintID];
    }
}

- (NSString *)getSessionID {
    if (!_sessionID) {
        _sessionID = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_ID];
    }
    
    return _sessionID;
}

- (void)setSessionID:(NSString *)sessionID {
    if (![_sessionID isEqualToString:sessionID]) {
        _sessionID = sessionID;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_ID value:sessionID];
    }
}

- (NSString *)getIdentityID {
    if (!_identityID) {
        _identityID = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY_ID];
    }
    
    return _identityID;
}

- (void)setIdentityID:(NSString *)identityID {
    if (![_identityID isEqualToString:identityID]) {
        _identityID = identityID;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY_ID value:identityID];
    }
}

- (NSString *)getUserIdentity {
    if (_userIdentity) {
        _userIdentity = [BNCPreferenceHelper readStringFromDefaults:KEY_IDENTITY];
    }

    return _userIdentity;
}

- (void)setUserIdentity:(NSString *)userIdentity {
    if (![_userIdentity isEqualToString:userIdentity]) {
        _userIdentity = userIdentity;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_IDENTITY value:userIdentity];
    }
}

- (NSString *)getLinkClickIdentifier {
    if (!_linkClickIdentifier) {
        _linkClickIdentifier = [BNCPreferenceHelper readStringFromDefaults:KEY_LINK_CLICK_IDENTIFIER];
    }

    return _linkClickIdentifier;
}

- (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    if (![_linkClickIdentifier isEqualToString:linkClickIdentifier]) {
        _linkClickIdentifier = linkClickIdentifier;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
    }
}

- (NSString *)getSessionParams {
    if (_sessionParams) {
        _sessionParams = [BNCPreferenceHelper readStringFromDefaults:KEY_SESSION_PARAMS];
    }
    
    return _sessionParams;
}

- (void)setSessionParams:(NSString *)sessionParams {
    if (![_sessionParams isEqualToString:sessionParams]) {
        _sessionParams = sessionParams;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_SESSION_PARAMS value:sessionParams];
    }
}

- (NSString *)getInstallParams {
    if (!_installParams) {
        _installParams = [BNCPreferenceHelper readStringFromDefaults:KEY_INSTALL_PARAMS];
    }
    
    return _installParams;
}

- (void)setInstallParams:(NSString *)installParams {
    if (![_installParams isEqualToString:installParams]) {
        _installParams = installParams;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_INSTALL_PARAMS value:installParams];
    }
}

- (NSString *)getUserURL {
    if (!_userUrl) {
        _userUrl = [BNCPreferenceHelper readStringFromDefaults:KEY_USER_URL];
    }
    
    return _userUrl;
}

- (void)setUserURL:(NSString *)userUrl {
    if (![_userUrl isEqualToString:userUrl]) {
        _userUrl = userUrl;
        [BNCPreferenceHelper writeObjectToDefaults:KEY_USER_URL value:userUrl];
    }
}

- (BOOL)getIsReferrable {
    return _isReferrable;
}

- (void)setIsReferrable:(BOOL)isReferrable {
    if (_isReferrable != isReferrable) {
        _isReferrable = isReferrable;
        [BNCPreferenceHelper writeBoolToDefaults:KEY_IS_REFERRABLE value:isReferrable];
    }
}

- (void)setAppListCheckDone {
    [BNCPreferenceHelper writeObjectToDefaults:KEY_APP_LIST_CHECK value:[NSDate date]];
}

- (BOOL)getNeedAppListCheck {
    NSDate *lastDate = (NSDate *)[BNCPreferenceHelper readObjectFromDefaults:KEY_APP_LIST_CHECK];
    if (lastDate) {
        NSDate *currDate = [NSDate date];
        NSTimeInterval diff = [currDate timeIntervalSinceDate:lastDate];
        if (diff < APP_READ_INTERVAL) {
            return NO;
        }
    }
    return YES;
}

- (void)clearUserCreditsAndCounts {
    self.creditsDictionary = [[NSMutableDictionary alloc] init];
    self.countsDictionary = [[NSMutableDictionary alloc] init];
}

#pragma mark - Credit Storage

- (NSDictionary *)getCreditsDictionary {
    if (!_creditsDictionary) {
        _creditsDictionary = [[BNCPreferenceHelper readObjectFromDefaults:KEY_CREDITS] mutableCopy];
        
        if (_creditsDictionary) {
            _creditsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _creditsDictionary;
}

- (void)setCreditCount:(NSInteger)count {
    [self setCreditCount:count forBucket:@"default"];
}

- (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket {
    self.creditsDictionary[[KEY_CREDIT_BASE stringByAppendingString:bucket]] = @(count);

    [BNCPreferenceHelper writeObjectToDefaults:KEY_CREDITS value:self.creditsDictionary];
}

- (NSInteger)getCreditCount {
    return [self getCreditCountForBucket:@"default"];
}

- (NSInteger)getCreditCountForBucket:(NSString *)bucket {
    return [self.creditsDictionary[[KEY_CREDIT_BASE stringByAppendingString:bucket]] integerValue];
}

#pragma mark - Count Storage

- (NSDictionary *)getCountsDictionary {
    if (!_countsDictionary) {
        _countsDictionary = [[BNCPreferenceHelper readObjectFromDefaults:KEY_COUNTS] mutableCopy];
        
        if (_countsDictionary) {
            _countsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _countsDictionary;
}

- (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[KEY_TOTAL_BASE stringByAppendingString:action]] = @(count);
    
    [BNCPreferenceHelper writeObjectToDefaults:KEY_COUNTS value:self.countsDictionary];
}

- (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[KEY_UNIQUE_BASE stringByAppendingString:action]] = @(count);

    [BNCPreferenceHelper writeObjectToDefaults:KEY_COUNTS value:self.countsDictionary];
}

- (NSInteger)getActionTotalCount:(NSString *)action {
    return [self.countsDictionary[[KEY_TOTAL_BASE stringByAppendingString:action]] integerValue];
}

- (NSInteger)getActionUniqueCount:(NSString *)action {
    return [self.countsDictionary[[KEY_UNIQUE_BASE stringByAppendingString:action]] integerValue];
}

#pragma mark - Writing To Defaults

+ (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:key];
    [defaults synchronize];
}

+ (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
}

+ (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

#pragma mark - Reading From Defaults

+ (NSObject *)readObjectFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *obj = [defaults objectForKey:key];
    return obj;
}

+ (NSString *)readStringFromDefaults:(NSString *)key {
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

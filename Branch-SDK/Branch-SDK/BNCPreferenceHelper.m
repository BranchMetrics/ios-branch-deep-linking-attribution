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

static const NSTimeInterval DEFAULT_TIMEOUT = 5.5;
static const NSTimeInterval DEFAULT_RETRY_INTERVAL = 0;
static const NSInteger DEFAULT_RETRY_COUNT = 3;

NSString * const BRANCH_PREFS_FILE = @"BNCPreferences";

NSString * const BRANCH_PREFS_KEY_APP_KEY = @"bnc_app_key";
NSString * const BRANCH_PREFS_KEY_APP_VERSION = @"bnc_app_version";
NSString * const BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY = @"bnc_last_run_branch_key";
NSString * const BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE = @"bnc_strong_match_created_date";
NSString * const BRANCH_PREFS_KEY_DEVICE_FINGERPRINT_ID = @"bnc_device_fingerprint_id";
NSString * const BRANCH_PREFS_KEY_SESSION_ID = @"bnc_session_id";
NSString * const BRANCH_PREFS_KEY_IDENTITY_ID = @"bnc_identity_id";
NSString * const BRANCH_PREFS_KEY_IDENTITY = @"bnc_identity";
NSString * const BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER = @"bnc_link_click_identifier";
NSString * const BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER = @"bnc_spotlight_identifier";
NSString * const BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL = @"bnc_universal_link_url";
NSString * const BRANCH_PREFS_KEY_SESSION_PARAMS = @"bnc_session_params";
NSString * const BRANCH_PREFS_KEY_INSTALL_PARAMS = @"bnc_install_params";
NSString * const BRANCH_PREFS_KEY_USER_URL = @"bnc_user_url";
NSString * const BRANCH_PREFS_KEY_IS_REFERRABLE = @"bnc_is_referrable";
NSString * const BRANCH_PREFS_KEY_BRANCH_UNIVERSAL_LINK_DOMAINS = @"branch_universal_link_domains";
NSString * const BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI = @"external_intent_uri";

NSString * const BRANCH_PREFS_KEY_CREDITS = @"bnc_credits";
NSString * const BRANCH_PREFS_KEY_CREDIT_BASE = @"bnc_credit_base_";

NSString * const BRANCH_PREFS_KEY_COUNTS = @"bnc_counts";
NSString * const BRANCH_PREFS_KEY_TOTAL_BASE = @"bnc_total_base_";
NSString * const BRANCH_PREFS_KEY_UNIQUE_BASE = @"bnc_unique_base_";

@interface BNCPreferenceHelper ()

@property (strong, nonatomic) NSMutableDictionary *persistenceDict;
@property (strong, nonatomic) NSMutableDictionary *countsDictionary;
@property (strong, nonatomic) NSMutableDictionary *creditsDictionary;
@property (assign, nonatomic) BOOL isUsingLiveKey;

@end

@implementation BNCPreferenceHelper

@synthesize branchKey = _branchKey,
            appKey = _appKey,
            lastRunBranchKey = _lastRunBranchKey,
            appVersion = _appVersion,
            deviceFingerprintID = _deviceFingerprintID,
            sessionID = _sessionID,
            spotlightIdentifier = _spotlightIdentifier,
            identityID = _identityID,
            linkClickIdentifier = _linkClickIdentifier,
            userUrl = _userUrl,
            userIdentity = _userIdentity,
            sessionParams = _sessionParams,
            installParams = _installParams,
            universalLinkUrl = _universalLinkUrl,
            externalIntentURI = _externalIntentURI,
            isReferrable = _isReferrable,
            isDebug = _isDebug,
            isContinuingUserActivity = _isContinuingUserActivity,
            retryCount = _retryCount,
            retryInterval = _retryInterval,
            timeout = _timeout,
            lastStrongMatchDate = _lastStrongMatchDate;

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
        _explicitlyRequestedReferrable = NO;
        _isReferrable = [self readBoolFromDefaults:BRANCH_PREFS_KEY_IS_REFERRABLE];
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

- (NSOperationQueue *)persistPrefsQueue {
    static NSOperationQueue *persistPrefsQueue;
    static dispatch_once_t persistOnceToken;
    
    dispatch_once(&persistOnceToken, ^{
        persistPrefsQueue = [[NSOperationQueue alloc] init];
        persistPrefsQueue.maxConcurrentOperationCount = 1;
    });

    return persistPrefsQueue;
}

#pragma mark - Debug methods

- (void)log:(NSString *)filename line:(int)line message:(NSString *)format, ... {
    if (self.isDebug) {
        va_list args;
        va_start(args, format);
        NSString *log = [NSString stringWithFormat:@"[%@:%d] %@", filename, line, [[NSString alloc] initWithFormat:format arguments:args]];
        va_end(args);
        NSLog(@"%@", log);
    }
}

- (NSString *)getAPIBaseURL {
    return [NSString stringWithFormat:@"%@/%@/", BNC_API_BASE_URL, BNC_API_VERSION];
}

- (NSString *)getAPIURL:(NSString *) endpoint {
    return [[self getAPIBaseURL] stringByAppendingString:endpoint];
}

#pragma mark - Preference Storage

- (NSString *)appKey {
    if (!_appKey) {
        _appKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:BRANCH_PREFS_KEY_APP_KEY];
    }
    
    return _appKey;
}

- (void)setAppKey:(NSString *)appKey {
    NSLog(@"Usage of App Key is deprecated, please move toward using a Branch key");
    
    if (![_appKey isEqualToString:appKey]) {
        _appKey = appKey;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_APP_KEY value:appKey];
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

- (NSString *)lastRunBranchKey {
    if (!_lastRunBranchKey) {
        _lastRunBranchKey = [self readStringFromDefaults:BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY];
    }
    
    return _lastRunBranchKey;
}

- (void)setLastRunBranchKey:(NSString *)lastRunBranchKey {
    if (![_lastRunBranchKey isEqualToString:lastRunBranchKey]) {
        _lastRunBranchKey = lastRunBranchKey;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY value:lastRunBranchKey];
    }
}

- (NSDate *)lastStrongMatchDate {
    if (!_lastStrongMatchDate) {
        _lastStrongMatchDate = (NSDate *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE];
    }
    
    return _lastStrongMatchDate;
}

- (void)setLastStrongMatchDate:(NSDate *)lastStrongMatchDate {
    if (![_lastStrongMatchDate isEqualToDate:lastStrongMatchDate]) {
        _lastStrongMatchDate = lastStrongMatchDate;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE value:lastStrongMatchDate];
    }
}

- (NSString *)appVersion {
    if (!_appVersion) {
        _appVersion = [self readStringFromDefaults:BRANCH_PREFS_KEY_APP_VERSION];
    }
    
    return _appVersion;
}

- (void)setAppVersion:(NSString *)appVersion {
    if (![_appVersion isEqualToString:appVersion]) {
        _appVersion = appVersion;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_APP_VERSION value:appVersion];
    }
}

- (NSString *)deviceFingerprintID {
    if (!_deviceFingerprintID) {
        _deviceFingerprintID = [self readStringFromDefaults:BRANCH_PREFS_KEY_DEVICE_FINGERPRINT_ID];
    }
    
    return _deviceFingerprintID;
}

- (void)setDeviceFingerprintID:(NSString *)deviceFingerprintID {
    if (![_deviceFingerprintID isEqualToString:deviceFingerprintID]) {
        _deviceFingerprintID = deviceFingerprintID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_DEVICE_FINGERPRINT_ID value:deviceFingerprintID];
    }
}

- (NSString *)sessionID {
    if (!_sessionID) {
        _sessionID = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_ID];
    }
    
    return _sessionID;
}

- (void)setSessionID:(NSString *)sessionID {
    if (![_sessionID isEqualToString:sessionID]) {
        _sessionID = sessionID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_ID value:sessionID];
    }
}

- (NSString *)identityID {
    if (!_identityID) {
        _identityID = [self readStringFromDefaults:BRANCH_PREFS_KEY_IDENTITY_ID];
    }
    
    return _identityID;
}

- (void)setIdentityID:(NSString *)identityID {
    if (![_identityID isEqualToString:identityID]) {
        _identityID = identityID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_IDENTITY_ID value:identityID];
    }
}

- (NSString *)userIdentity {
    if (!_userIdentity) {
        _userIdentity = [self readStringFromDefaults:BRANCH_PREFS_KEY_IDENTITY];
    }

    return _userIdentity;
}

- (void)setUserIdentity:(NSString *)userIdentity {
    if (![_userIdentity isEqualToString:userIdentity]) {
        _userIdentity = userIdentity;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_IDENTITY value:userIdentity];
    }
}

- (NSString *)linkClickIdentifier {
    if (!_linkClickIdentifier) {
        _linkClickIdentifier = [self readStringFromDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER];
    }

    return _linkClickIdentifier;
}

- (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    if (![_linkClickIdentifier isEqualToString:linkClickIdentifier]) {
        _linkClickIdentifier = linkClickIdentifier;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
    }
}

- (NSString *)spotlightIdentifier {
    if (!_spotlightIdentifier) {
        _spotlightIdentifier = [self readStringFromDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER];
    }
    
    return _spotlightIdentifier;
}

- (void)setSpotlightIdentifier:(NSString *)spotlightIdentifier {
    if (![_spotlightIdentifier isEqualToString:spotlightIdentifier]) {
        _spotlightIdentifier = spotlightIdentifier;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER value:spotlightIdentifier];
    }
}

- (NSString *)externalIntentURI {
    if (!_externalIntentURI) {
        _externalIntentURI = [self readStringFromDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI];
    }
    return _externalIntentURI;
}

- (void)setExternalIntentURI:(NSString *)externalIntentURI {
    if (![_externalIntentURI isEqualToString:externalIntentURI]) {
        _externalIntentURI = externalIntentURI;
        [self writeObjectToDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI value:externalIntentURI];
    }
}

- (NSString *)universalLinkUrl {
    if (!_universalLinkUrl) {
        _universalLinkUrl = [self readStringFromDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL];
    }
    
    return _universalLinkUrl;
}

- (void)setUniversalLinkUrl:(NSString *)universalLinkUrl {
    if (![_universalLinkUrl isEqualToString:universalLinkUrl]) {
        _universalLinkUrl = universalLinkUrl;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL value:universalLinkUrl];
    }
}

- (NSString *)sessionParams {
    if (_sessionParams) {
        _sessionParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS];
    }
    
    return _sessionParams;
}

- (void)setSessionParams:(NSString *)sessionParams {
    if (![_sessionParams isEqualToString:sessionParams]) {
        _sessionParams = sessionParams;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS value:sessionParams];
    }
}

- (NSString *)installParams {
    if (!_installParams) {
        _installParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS];
    }
    
    return _installParams;
}

- (void)setInstallParams:(NSString *)installParams {
    if (![_installParams isEqualToString:installParams]) {
        _installParams = installParams;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:installParams];
    }
}

- (NSString *)userUrl {
    if (!_userUrl) {
        _userUrl = [self readStringFromDefaults:BRANCH_PREFS_KEY_USER_URL];
    }
    
    return _userUrl;
}

- (void)setUserUrl:(NSString *)userUrl {
    if (![_userUrl isEqualToString:userUrl]) {
        _userUrl = userUrl;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_USER_URL value:userUrl];
    }
}

- (BOOL)isReferrable {
    BOOL hasIdentity = self.identityID != nil;
    
    // If referrable is set, but they already have an identity, they should only
    // still be referrable if the dev has explicitly set always referrable.
    if (_isReferrable && hasIdentity) {
        return _explicitlyRequestedReferrable;
    }
    
    // If not referrable, or no identity yet, whatever isReferrable has is fine to return.
    return _isReferrable;
}

- (void)setIsReferrable:(BOOL)isReferrable {
    if (_isReferrable != isReferrable) {
        _isReferrable = isReferrable;
        [self writeBoolToDefaults:BRANCH_PREFS_KEY_IS_REFERRABLE value:isReferrable];
    }
}

- (void)clearUserCreditsAndCounts {
    self.creditsDictionary = [[NSMutableDictionary alloc] init];
    self.countsDictionary = [[NSMutableDictionary alloc] init];
}

- (id)getBranchUniversalLinkDomains {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:BRANCH_PREFS_KEY_BRANCH_UNIVERSAL_LINK_DOMAINS];
}

#pragma mark - Credit Storage

- (NSMutableDictionary *)creditsDictionary {
    if (!_creditsDictionary) {
        _creditsDictionary = [[self readObjectFromDefaults:BRANCH_PREFS_KEY_CREDITS] mutableCopy];
        
        if (!_creditsDictionary) {
            _creditsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _creditsDictionary;
}

- (void)setCreditCount:(NSInteger)count {
    [self setCreditCount:count forBucket:@"default"];
}

- (void)setCreditCount:(NSInteger)count forBucket:(NSString *)bucket {
    self.creditsDictionary[[BRANCH_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]] = @(count);

    [self writeObjectToDefaults:BRANCH_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

- (void)removeCreditCountForBucket:(NSString *)bucket {
    NSMutableDictionary *dictToWrite = self.creditsDictionary;
    [dictToWrite removeObjectForKey:[BRANCH_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]];

    [self writeObjectToDefaults:BRANCH_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

- (NSDictionary *)getCreditDictionary {
    NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];
    for(NSString *key in self.creditsDictionary) {
        NSString *cleanKey = [key stringByReplacingOccurrencesOfString:BRANCH_PREFS_KEY_CREDIT_BASE
                                                                                     withString:@""];
        returnDictionary[cleanKey] = self.creditsDictionary[key];
    }
    return returnDictionary;
}

- (NSInteger)getCreditCount {
    return [self getCreditCountForBucket:@"default"];
}

- (NSInteger)getCreditCountForBucket:(NSString *)bucket {
    return [self.creditsDictionary[[BRANCH_PREFS_KEY_CREDIT_BASE stringByAppendingString:bucket]] integerValue];
}

- (void)clearUserCredits {
    self.creditsDictionary = [[NSMutableDictionary alloc] init];
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_CREDITS value:self.creditsDictionary];
}

#pragma mark - Count Storage

- (NSMutableDictionary *)countsDictionary {
    if (!_countsDictionary) {
        _countsDictionary = [[self readObjectFromDefaults:BRANCH_PREFS_KEY_COUNTS] mutableCopy];
        
        if (!_countsDictionary) {
            _countsDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _countsDictionary;
}

- (void)setActionTotalCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[BRANCH_PREFS_KEY_TOTAL_BASE stringByAppendingString:action]] = @(count);
    
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_COUNTS value:self.countsDictionary];
}

- (void)setActionUniqueCount:(NSString *)action withCount:(NSInteger)count {
    self.countsDictionary[[BRANCH_PREFS_KEY_UNIQUE_BASE stringByAppendingString:action]] = @(count);

    [self writeObjectToDefaults:BRANCH_PREFS_KEY_COUNTS value:self.countsDictionary];
}

- (NSInteger)getActionTotalCount:(NSString *)action {
    return [self.countsDictionary[[BRANCH_PREFS_KEY_TOTAL_BASE stringByAppendingString:action]] integerValue];
}

- (NSInteger)getActionUniqueCount:(NSString *)action {
    return [self.countsDictionary[[BRANCH_PREFS_KEY_UNIQUE_BASE stringByAppendingString:action]] integerValue];
}

#pragma mark - Writing To Persistence

- (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value {
    self.persistenceDict[key] = @(value);
    [self persistPrefsToDisk];
}

- (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value {
    self.persistenceDict[key] = @(value);
    [self persistPrefsToDisk];
}

- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value {
    if (value) {
        self.persistenceDict[key] = value;
    }
    else {
        [self.persistenceDict removeObjectForKey:key];
    }

    [self persistPrefsToDisk];
}

- (void)persistPrefsToDisk {
    NSDictionary *persistenceDict = [self.persistenceDict copy];
    NSBlockOperation *newPersistOp = [NSBlockOperation blockOperationWithBlock:^{
        if (![NSKeyedArchiver archiveRootObject:persistenceDict toFile:[self prefsFile]]) {
            NSLog(@"[Branch Warning] Failed to persist preferences to disk");
        }
    }];
    [self.persistPrefsQueue addOperation:newPersistOp];
}

#pragma mark - Reading From Persistence

- (NSMutableDictionary *)persistenceDict {
    if (!_persistenceDict) {
        NSDictionary *persistenceDict = nil;
        @try {
            persistenceDict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self prefsFile]];
        }
        @catch (NSException *exception) {
            NSLog(@"[Branch Warning] Failed to load preferences from disk");
        }

        if (persistenceDict) {
            _persistenceDict = [persistenceDict mutableCopy];
        }
        else {
            _persistenceDict = [[NSMutableDictionary alloc] init];
        }
    }
    
    return _persistenceDict;
}

- (NSObject *)readObjectFromDefaults:(NSString *)key {
    NSObject *obj = self.persistenceDict[key];
    return obj;
}

- (NSString *)readStringFromDefaults:(NSString *)key {
    id str = self.persistenceDict[key];
    
    if ([str isKindOfClass:[NSNumber class]]) {
        str = [str stringValue];
    }
    
    return str;
}

- (BOOL)readBoolFromDefaults:(NSString *)key {
    BOOL boo = [self.persistenceDict[key] boolValue];
    return boo;
}

- (NSInteger)readIntegerFromDefaults:(NSString *)key {
    NSNumber *number = self.persistenceDict[key];
    
    if (number) {
        return [number integerValue];
    }
    
    return NSNotFound;
}

- (NSString *)prefsFile {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:BRANCH_PREFS_FILE];
}

@end

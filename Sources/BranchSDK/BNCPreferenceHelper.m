//
//  BNCPreferenceHelper.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/6/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BNCConfig.h"
#import "Branch.h"
#import "BranchLogger.h"
#import "BranchConstants.h"
#import "NSString+Branch.h"
#import "BNCSKAdNetwork.h"

static const NSTimeInterval DEFAULT_TIMEOUT = 5.5;
static const NSTimeInterval DEFAULT_RETRY_INTERVAL = 0;
static const NSInteger DEFAULT_RETRY_COUNT = 3;
static const NSTimeInterval DEFAULT_REFERRER_GBRAID_WINDOW = 2592000; // 30 days = 2,592,000 seconds
static const NSTimeInterval DEFAULT_ODM_INFO_VALIDITY_WINDOW = 15552000; // 180 days = 15,552,000 seconds

static NSString * const BRANCH_PREFS_FILE = @"BNCPreferences";

static NSString * const BRANCH_PREFS_KEY_APP_VERSION = @"bnc_app_version";
static NSString * const BRANCH_PREFS_KEY_LAST_RUN_BRANCH_KEY = @"bnc_last_run_branch_key";
static NSString * const BRANCH_PREFS_KEY_LAST_STRONG_MATCH_DATE = @"bnc_strong_match_created_date";

static NSString * const BRANCH_PREFS_KEY_PATTERN_LIST_URL = @"bnc_pattern_list_url";

static NSString * const BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN = @"bnc_randomized_device_token";
static NSString * const BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN = @"bnc_randomized_bundle_token";

static NSString * const BRANCH_PREFS_KEY_SESSION_ID = @"bnc_session_id";
static NSString * const BRANCH_PREFS_KEY_IDENTITY = @"bnc_identity";
static NSString * const BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER = @"bnc_link_click_identifier";
static NSString * const BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER = @"bnc_spotlight_identifier";
static NSString * const BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL = @"bnc_universal_link_url";
static NSString * const BRANCH_PREFS_KEY_LOCAL_URL = @"bnc_local_url";
static NSString * const BRANCH_PREFS_KEY_INITIAL_REFERRER = @"bnc_initial_referrer";
static NSString * const BRANCH_PREFS_KEY_SESSION_PARAMS = @"bnc_session_params";
static NSString * const BRANCH_PREFS_KEY_INSTALL_PARAMS = @"bnc_install_params";
static NSString * const BRANCH_PREFS_KEY_USER_URL = @"bnc_user_url";

static NSString * const BRANCH_PREFS_KEY_BRANCH_VIEW_USAGE_CNT = @"bnc_branch_view_usage_cnt_";
static NSString * const BRANCH_PREFS_KEY_ANALYTICAL_DATA = @"bnc_branch_analytical_data";
static NSString * const BRANCH_PREFS_KEY_ANALYTICS_MANIFEST = @"bnc_branch_analytics_manifest";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID = @"bnc_referrer_gbraid";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW = @"bnc_referrer_gbraid_window";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE = @"bnc_referrer_gbraid_init_date";
static NSString * const BRANCH_PREFS_KEY_ODM_INFO = @"bnc_odm_info";
static NSString * const BRANCH_PREFS_KEY_ODM_INFO_VALIDITY_WINDOW = @"bnc_odm_info_validity_window";
static NSString * const BRANCH_PREFS_KEY_ODM_INFO_INIT_DATE = @"bnc_odm_info_init_date";
static NSString * const BRANCH_PREFS_KEY_REFERRER_GCLID = @"bnc_referrer_gclid";
static NSString * const BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW = @"bnc_skan_current_window";
static NSString * const BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME = @"bnc_first_app_launch_time";
static NSString * const BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT = @"bnc_skan_send_highest_conv_value";
static NSString * const BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP = @"bnc_invoke_register_app";
                                                                
static NSString * const BRANCH_PREFS_KEY_USE_EU_SERVERS = @"bnc_use_EU_servers";

static NSString * const BRANCH_PREFS_KEY_REFFERING_URL_QUERY_PARAMETERS = @"bnc_referring_url_query_parameters";

static NSString * const BRANCH_PREFS_KEY_LOG_IAP_AS_EVENTS = @"bnc_log_iap_as_events";

static NSString * const BRANCH_PREFS_KEY_DMA_EEA = @"bnc_dma_eea";
static NSString * const BRANCH_PREFS_KEY_DMA_AD_PERSONALIZATION = @"bnc_dma_ad_personalization";
static NSString * const BRANCH_PREFS_KEY_DMA_AD_USER_DATA = @"bnc_dma_ad_user_data";

static NSString * const BRANCH_PREFS_KEY_ATTRIBUTION_LEVEL = @"bnc_attribution_level";

static NSString * const BRANCH_PREFS_KEY_UX_TYPE = @"bnc_ux_type";
static NSString * const BRANCH_PREFS_KEY_URL_LOAD_MS = @"bnc_url_load_ms";

NSURL* /* _Nonnull */ BNCURLForBranchDirectory_Unthreaded(void);

@interface BNCPreferenceHelper () {
    NSOperationQueue *_persistPrefsQueue;
    NSString         *_lastSystemBuildVersion;
    NSString         *_browserUserAgentString;
    NSString         *_referringURL;
}

@property (strong, nonatomic) NSMutableDictionary *persistenceDict;
@property (strong, nonatomic) NSMutableDictionary *requestMetadataDictionary;
@property (strong, nonatomic) NSMutableDictionary *instrumentationDictionary;

// unit tests run in parallel, causing issues with data stored to disk
@property (nonatomic, assign, readwrite) BOOL useStorage;

@end

@implementation BNCPreferenceHelper

// since we override both setter and getter, these properties do not auto synthesize
@synthesize
    lastRunBranchKey = _lastRunBranchKey,
    appVersion = _appVersion,
    randomizedDeviceToken = _randomizedDeviceToken,
    sessionID = _sessionID,
    spotlightIdentifier = _spotlightIdentifier,
    randomizedBundleToken = _randomizedBundleToken,
    linkClickIdentifier = _linkClickIdentifier,
    userUrl = _userUrl,
    userIdentity = _userIdentity,
    sessionParams = _sessionParams,
    installParams = _installParams,
    universalLinkUrl = _universalLinkUrl,
    initialReferrer = _initialReferrer,
    localUrl = _localUrl,
    externalIntentURI = _externalIntentURI,
    isDebug = _isDebug,
    retryCount = _retryCount,
    retryInterval = _retryInterval,
    timeout = _timeout,
    lastStrongMatchDate = _lastStrongMatchDate,
    requestMetadataDictionary = _requestMetadataDictionary,
    instrumentationDictionary = _instrumentationDictionary,
    referrerGBRAID = _referrerGBRAID,
    referrerGBRAIDValidityWindow = _referrerGBRAIDValidityWindow,
    odmInfo = _odmInfo,
    odmInfoValidityWindow = _odmInfoValidityWindow,
    odmInfoInitDate = _odmInfoInitDate,
    skanCurrentWindow = _skanCurrentWindow,
    firstAppLaunchTime = _firstAppLaunchTime,
    highestConversionValueSent = _highestConversionValueSent,
    referringURLQueryParameters = _referringURLQueryParameters,
    anonID = _anonID,
    patternListURL = _patternListURL,
    eeaRegion = _eeaRegion,
    adPersonalizationConsent = _adPersonalizationConsent,
    adUserDataUsageConsent = _adUserDataUsageConsent,
    attributionLevel = _attributionLevel,
    uxType = _uxType,
    urlLoadMs = _urlLoadMs;

+ (BNCPreferenceHelper *)sharedInstance {
    static BNCPreferenceHelper *preferenceHelper = nil;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        preferenceHelper = [[BNCPreferenceHelper alloc] init];
        
        // the shared version read/writes data to storage
        preferenceHelper.useStorage = YES;
    });
    
    return preferenceHelper;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeout = DEFAULT_TIMEOUT;
        _retryCount = DEFAULT_RETRY_COUNT;
        _retryInterval = DEFAULT_RETRY_INTERVAL;
        _odmInfoValidityWindow = DEFAULT_ODM_INFO_VALIDITY_WINDOW;
        _isDebug = NO;
        _persistPrefsQueue = [[NSOperationQueue alloc] init];
        _persistPrefsQueue.maxConcurrentOperationCount = 1;

        self.disableAdNetworkCallouts = NO;
        self.useStorage = NO;
    }
    return self;
}

- (void) synchronize {
    [_persistPrefsQueue waitUntilAllOperationsAreFinished];
}

- (void) dealloc {
    [self synchronize];
}

#pragma mark - API methods

- (void)setPatternListURL:(NSString *)url {
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] ){
        @synchronized (self) {
            _patternListURL = url;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_PATTERN_LIST_URL value:url];
        }
    } else {
        [[BranchLogger shared] logWarning:@"Ignoring invalid custom CDN URL" error:nil];
    }
}

- (NSString *)patternListURL {
    @synchronized (self) {
        if (!_patternListURL) {
            _patternListURL =  [self readStringFromDefaults:BRANCH_PREFS_KEY_PATTERN_LIST_URL];
        }

        // When no custom URL is found, return the default
        if (_patternListURL == nil || [_patternListURL isEqualToString:@""]) {
            _patternListURL = BNC_CDN_URL;
        }

        return _patternListURL;
    }
}

#pragma mark - Preference Storage

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
    if (lastStrongMatchDate == nil || ![_lastStrongMatchDate isEqualToDate:lastStrongMatchDate]) {
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

- (NSString *)randomizedDeviceToken {
    if (!_randomizedDeviceToken) {
        NSString *tmp = [self readStringFromDefaults:BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN];
    
        // check deprecated location
        if (!tmp) {
            tmp = [self readStringFromDefaults:@"bnc_device_fingerprint_id"];
        }
        
        _randomizedDeviceToken = tmp;
    }
    
    return _randomizedDeviceToken;
}

- (void)setRandomizedDeviceToken:(NSString *)randomizedDeviceToken {
    if (randomizedDeviceToken == nil || ![_randomizedDeviceToken isEqualToString:randomizedDeviceToken]) {
        _randomizedDeviceToken = randomizedDeviceToken;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_RANDOMIZED_DEVICE_TOKEN value:randomizedDeviceToken];
    }
}

- (NSString *)anonID {
    if (!_anonID) {
        _anonID = [self readStringFromDefaults:@"bnc_anon_id"];
    }
    return _anonID;
}

- (void)setAnonID:(NSString *)anonID {
    if (![_anonID isEqualToString:anonID]) {
        _anonID = anonID;
        [self writeObjectToDefaults:@"bnc_anon_id" value:anonID];
    }
}

- (NSString *)sessionID {
    if (!_sessionID) {
        _sessionID = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_ID];
    }
    
    return _sessionID;
}

- (void)setSessionID:(NSString *)sessionID {
    if (sessionID == nil || ![_sessionID isEqualToString:sessionID]) {
        _sessionID = sessionID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_ID value:sessionID];
    }
}

- (NSString *)randomizedBundleToken {
    NSString *tmp = [self readStringFromDefaults:BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN];
    
    // check deprecated location
    if (!tmp) {
        tmp = [self readStringFromDefaults:@"bnc_identity_id"];
    }
    
    return tmp;
}

- (void)setRandomizedBundleToken:(NSString *)randomizedBundleToken {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_RANDOMIZED_BUNDLE_TOKEN value:randomizedBundleToken];
}

- (NSString *)userIdentity {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_IDENTITY];
}

- (void)setUserIdentity:(NSString *)userIdentity {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_IDENTITY value:userIdentity];
}

- (NSString *)linkClickIdentifier {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER];
}

- (void)setLinkClickIdentifier:(NSString *)linkClickIdentifier {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_LINK_CLICK_IDENTIFIER value:linkClickIdentifier];
}

- (NSString *)spotlightIdentifier {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER];
}

- (void)setSpotlightIdentifier:(NSString *)spotlightIdentifier {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_SPOTLIGHT_IDENTIFIER value:spotlightIdentifier];
}

- (NSString *)externalIntentURI {
    @synchronized(self) {
        if (!_externalIntentURI) {
            _externalIntentURI = [self readStringFromDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI];
        }
        return _externalIntentURI;
    }
}

- (void)setExternalIntentURI:(NSString *)externalIntentURI {
    @synchronized(self) {
        if (externalIntentURI == nil || ![_externalIntentURI isEqualToString:externalIntentURI]) {
            _externalIntentURI = externalIntentURI;
            [self writeObjectToDefaults:BRANCH_REQUEST_KEY_EXTERNAL_INTENT_URI value:externalIntentURI];
        }
    }
}

- (NSString*) referringURL {
    @synchronized (self) {
        if (!_referringURL) _referringURL = [self readStringFromDefaults:@"referringURL"];
        return _referringURL;
    }
}

- (void) setReferringURL:(NSString *)referringURL {
    @synchronized (self) {
        _referringURL = [referringURL copy];
        [self writeObjectToDefaults:@"referringURL" value:_referringURL];
    }
}

- (NSString *)universalLinkUrl {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL];
}

- (void)setUniversalLinkUrl:(NSString *)universalLinkUrl {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_UNIVERSAL_LINK_URL value:universalLinkUrl];
}

- (NSString *)localUrl {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_LOCAL_URL];
}

- (void)setLocalUrl:(NSString *)localURL {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_LOCAL_URL value:localURL];
}

- (NSString *)initialReferrer {
    return [self readStringFromDefaults:BRANCH_REQUEST_KEY_INITIAL_REFERRER];
}

- (void)setInitialReferrer:(NSString *)initialReferrer {
    [self writeObjectToDefaults:BRANCH_REQUEST_KEY_INITIAL_REFERRER value:initialReferrer];
}

- (NSString *)sessionParams {
    @synchronized (self) {
        if (!_sessionParams) {
            _sessionParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS];
        }
        return _sessionParams;
    }
}

- (void)setSessionParams:(NSString *)sessionParams {
    @synchronized (self) {
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Setting session params %@", sessionParams] error:nil];
        if (sessionParams == nil || ![_sessionParams isEqualToString:sessionParams]) {
            _sessionParams = sessionParams;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_SESSION_PARAMS value:sessionParams];
            [[BranchLogger shared] logVerbose:@"Params set" error:nil];
        }
    }
}

- (NSString *)installParams {
    @synchronized(self) {
        if (!_installParams) {
            id installParamsFromCache = [self readStringFromDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS];
            if ([installParamsFromCache isKindOfClass:[NSString class]]) {
                _installParams = [self readStringFromDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS];
            }
            else if ([installParamsFromCache isKindOfClass:[NSDictionary class]]) {
                [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:nil];
            }
        }
        return _installParams;
    }
}

- (void)setInstallParams:(NSString *)installParams {
    @synchronized(self) {
        if ([installParams isKindOfClass:[NSDictionary class]]) {
            _installParams = [BNCEncodingUtils encodeDictionaryToJsonString:(NSDictionary *)installParams];
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:_installParams];
            return;
        }
        if (installParams == nil || ![_installParams isEqualToString:installParams]) {
            _installParams = installParams;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_INSTALL_PARAMS value:installParams];
        }
    }
}

- (void)setAppleAttributionTokenChecked:(BOOL)appleAttributionTokenChecked {
    [self writeBoolToDefaults:@"_appleAttributionTokenChecked" value:appleAttributionTokenChecked];
}

- (BOOL)appleAttributionTokenChecked {
    return [self readBoolFromDefaults:@"_appleAttributionTokenChecked"];
}

- (void)setHasOptedInBefore:(BOOL)hasOptedInBefore {
    [self writeBoolToDefaults:@"_hasOptedInBefore" value:hasOptedInBefore];
}

- (BOOL)hasOptedInBefore {
    return [self readBoolFromDefaults:@"_hasOptedInBefore"];
}

- (void)setHasCalledHandleATTAuthorizationStatus:(BOOL)hasCalledHandleATTAuthorizationStatus {
    [self writeBoolToDefaults:@"_hasCalledHandleATTAuthorizationStatus" value:hasCalledHandleATTAuthorizationStatus];
}

- (BOOL)hasCalledHandleATTAuthorizationStatus {
    return [self readBoolFromDefaults:@"_hasCalledHandleATTAuthorizationStatus"];
}

- (NSString*) lastSystemBuildVersion {
    if (!_lastSystemBuildVersion) {
        _lastSystemBuildVersion = [self readStringFromDefaults:@"_lastSystemBuildVersion"];
    }
    return _lastSystemBuildVersion;
}

- (void) setLastSystemBuildVersion:(NSString *)lastSystemBuildVersion {
    if (![_lastSystemBuildVersion isEqualToString:lastSystemBuildVersion]) {
        _lastSystemBuildVersion = lastSystemBuildVersion;
        [self writeObjectToDefaults:@"_lastSystemBuildVersion" value:_lastSystemBuildVersion];
    }
}

- (NSString*) browserUserAgentString {
    if (!_browserUserAgentString) {
        _browserUserAgentString = [self readStringFromDefaults:@"_browserUserAgentString"];
    }
    return _browserUserAgentString;
}

- (void) setBrowserUserAgentString:(NSString *)browserUserAgentString {
    if (![_browserUserAgentString isEqualToString:browserUserAgentString]) {
        _browserUserAgentString = browserUserAgentString;
        [self writeObjectToDefaults:@"_browserUserAgentString" value:_browserUserAgentString];
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

- (NSMutableString*) sanitizedMutableBaseURL:(NSString*)baseUrl_ {
    NSMutableString *baseUrl = [baseUrl_ mutableCopy];
    if (self.trackingDisabled) {
        NSString *id_string = [NSString stringWithFormat:@"%%24randomized_bundle_token=%@", self.randomizedBundleToken];
        NSRange range = [baseUrl rangeOfString:id_string];
        if (range.location != NSNotFound) [baseUrl replaceCharactersInRange:range withString:@""];
    } else
    if ([baseUrl hasSuffix:@"&"] || [baseUrl hasSuffix:@"?"]) {
    } else
    if ([baseUrl containsString:@"?"]) {
        [baseUrl appendString:@"&"];
    }
    else {
        [baseUrl appendString:@"?"];
    }
    return baseUrl;
}

- (NSMutableDictionary *)requestMetadataDictionary {
    if (!_requestMetadataDictionary) {
        _requestMetadataDictionary = [NSMutableDictionary dictionary];
    }
    return _requestMetadataDictionary;
}

- (void)setRequestMetadataKey:(NSString *)key value:(NSObject *)value {
    if (!key) {
        return;
    }
    if ([self.requestMetadataDictionary objectForKey:key] && !value) {
        [self.requestMetadataDictionary removeObjectForKey:key];
    }
    else if (value) {
        [self.requestMetadataDictionary setObject:value forKey:key];
    }
}

- (NSDictionary *)instrumentationParameters {
    @synchronized (self) {
        if (_instrumentationDictionary.count == 0) {
            return nil; // this avoids the .count check in prepareParamDict
        }
        return [[NSDictionary alloc] initWithDictionary:_instrumentationDictionary];
    }
}

- (NSMutableDictionary *)instrumentationDictionary {
    @synchronized (self) {
        if (!_instrumentationDictionary) {
            _instrumentationDictionary = [NSMutableDictionary dictionary];
        }
        return _instrumentationDictionary;
    }
}

- (void)addInstrumentationDictionaryKey:(NSString *)key value:(NSString *)value {
    @synchronized (self) {
        if (key && value) {
            [self.instrumentationDictionary setObject:value forKey:key];
        }
    }
}

- (void)clearInstrumentationDictionary {
    @synchronized (self) {
        [_instrumentationDictionary removeAllObjects];
    }
}

- (BOOL) limitFacebookTracking {
    @synchronized (self) {
        return [self readBoolFromDefaults:@"_limitFacebookTracking"];
    }
}

- (void) setLimitFacebookTracking:(BOOL)limitFacebookTracking {
    @synchronized (self) {
        [self writeBoolToDefaults:@"_limitFacebookTracking" value:limitFacebookTracking];
    }
}

- (NSDate*) previousAppBuildDate {
    @synchronized (self) {
        NSDate *date = (NSDate*) [self readObjectFromDefaults:@"_previousAppBuildDate"];
        if ([date isKindOfClass:[NSDate class]]) return date;
        return nil;
    }
}

- (void) setPreviousAppBuildDate:(NSDate*)date {
    @synchronized (self) {
        if (date == nil || [date isKindOfClass:[NSDate class]])
            [self writeObjectToDefaults:@"_previousAppBuildDate" value:date];
    }
}

- (NSArray<NSString*>*) savedURLPatternList {
    @synchronized(self) {
        id a = [self readObjectFromDefaults:@"URLPatternList"];
        if ([a isKindOfClass:NSArray.class]) return a;
        return nil;
    }
}

- (void) setSavedURLPatternList:(NSArray<NSString *> *)URLPatternList {
    @synchronized(self) {
        [self writeObjectToDefaults:@"URLPatternList" value:URLPatternList];
    }
}

- (NSInteger) savedURLPatternListVersion {
    @synchronized(self) {
        return [self readIntegerFromDefaults:@"URLPatternListVersion"];
    }
}

- (void) setSavedURLPatternListVersion:(NSInteger)URLPatternListVersion {
    @synchronized(self) {
        [self writeIntegerToDefaults:@"URLPatternListVersion" value:URLPatternListVersion];
    }
}

- (BOOL) dropURLOpen {
    @synchronized(self) {
        return [self readBoolFromDefaults:@"dropURLOpen"];
    }
}

- (void) setDropURLOpen:(BOOL)value {
    @synchronized(self) {
        [self writeBoolToDefaults:@"dropURLOpen" value:value];
    }
}

- (BOOL) trackingDisabled {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:@"trackingDisabled"];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return false;
    }
}

- (void) setTrackingDisabled:(BOOL)disabled {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:disabled];
        [self writeObjectToDefaults:@"trackingDisabled" value:b];
        if (disabled) [self clearTrackingInformation];
    }
}

- (void)setReferringURLQueryParameters:(NSMutableDictionary *)parameters {
    @synchronized(self) {
        _referringURLQueryParameters = parameters;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFFERING_URL_QUERY_PARAMETERS value:parameters];
    }
}

- (NSMutableDictionary *)referringURLQueryParameters {
    @synchronized(self) {
        if (!_referringURLQueryParameters) {
            _referringURLQueryParameters = (NSMutableDictionary *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_REFFERING_URL_QUERY_PARAMETERS];
        }
    }
    return _referringURLQueryParameters;
}


- (NSString *) referrerGBRAID {
    @synchronized(self) {
        if (!_referrerGBRAID) {
            _referrerGBRAID = [self readStringFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID];
        }
        return _referrerGBRAID;
    }
}

- (void) setReferrerGBRAID:(NSString *)referrerGBRAID {
    if (![_referrerGBRAID isEqualToString:referrerGBRAID]) {
        _referrerGBRAID = referrerGBRAID;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID value:referrerGBRAID];
        self.referrerGBRAIDInitDate = [NSDate date];
    }
}

- (NSTimeInterval) referrerGBRAIDValidityWindow {
    @synchronized (self) {
        _referrerGBRAIDValidityWindow = [self readDoubleFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW];
        if (_referrerGBRAIDValidityWindow == NSNotFound) {
            _referrerGBRAIDValidityWindow = DEFAULT_REFERRER_GBRAID_WINDOW;
        }
        return _referrerGBRAIDValidityWindow;
    }
}

- (void) setReferrerGBRAIDValidityWindow:(NSTimeInterval)validityWindow {
    @synchronized (self) {
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_WINDOW value:@(validityWindow)];
    }
}

- (NSDate*) referrerGBRAIDInitDate {
    @synchronized (self) {
        NSDate* initdate = (NSDate*)[self readObjectFromDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE];
        if ([initdate isKindOfClass:[NSDate class]]) return initdate;
        return nil;
    }
}

- (void)setReferrerGBRAIDInitDate:(NSDate *)initDate {
    @synchronized (self) {
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_REFERRER_GBRAID_INIT_DATE value:initDate];
    }
}


- (NSString *) odmInfo {
    if (!_odmInfo) {
        _odmInfo = [self readStringFromDefaults:BRANCH_PREFS_KEY_ODM_INFO];
    }
    return _odmInfo;
}

- (void) setOdmInfo:(NSString *)odmInfo {
    @synchronized(self) {
        if (![_odmInfo isEqualToString:odmInfo]) {
            _odmInfo = odmInfo;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_ODM_INFO value:odmInfo];
        }
    }
}

- (NSDate*) odmInfoInitDate {
    @synchronized (self) {
        if (!_odmInfoInitDate) {
            _odmInfoInitDate = (NSDate*)[self readObjectFromDefaults:BRANCH_PREFS_KEY_ODM_INFO_INIT_DATE];
            if ([_odmInfoInitDate isKindOfClass:[NSDate class]]) return _odmInfoInitDate;
            return nil;
        }
        return _odmInfoInitDate;
    }
}

- (void) setOdmInfoInitDate:(NSDate *)initDate {
    @synchronized (self) {
        if (![_odmInfoInitDate isEqualToDate:initDate]) {
            _odmInfoInitDate = initDate;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_ODM_INFO_INIT_DATE value:initDate];
        }
    }
}

- (NSInteger) skanCurrentWindow {
    @synchronized (self) {
        _skanCurrentWindow = [self readIntegerFromDefaults:BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW];
        if(_skanCurrentWindow == NSNotFound)
            return BranchSkanWindowInvalid;
        return _skanCurrentWindow;
    }
}

- (void) setSkanCurrentWindow:(NSInteger) window {
    @synchronized (self) {
        [self writeIntegerToDefaults:BRANCH_PREFS_KEY_SKAN_CURRENT_WINDOW value:window];
    }
}


- (NSDate *) firstAppLaunchTime {
    @synchronized (self) {
        if(!_firstAppLaunchTime) {
            _firstAppLaunchTime = (NSDate *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME];
        }
        return _firstAppLaunchTime;
    }
}

- (void) setFirstAppLaunchTime:(NSDate *) launchTime {
    @synchronized (self) {
        _firstAppLaunchTime = launchTime;
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_FIRST_APP_LAUNCH_TIME value:launchTime];
    }
}

- (NSInteger) highestConversionValueSent {
    @synchronized (self) {
        _highestConversionValueSent = [self readIntegerFromDefaults:BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT];
        if(_highestConversionValueSent == NSNotFound)
            return 0;
        return _highestConversionValueSent;
    }
}

- (void) setHighestConversionValueSent:(NSInteger)value {
    @synchronized (self) {
        [self writeIntegerToDefaults:BRANCH_PREFS_KEY_SKAN_HIGHEST_CONV_VALUE_SENT value:value];
    }
}

- (BOOL) invokeRegisterApp {
    @synchronized (self) {
        NSNumber *b = (id) [self readObjectFromDefaults:BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return false;
    }
}

- (void) setInvokeRegisterApp:(BOOL)invoke {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:invoke];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_SKAN_INVOKE_REGISTER_APP value:b];
    }
}

- (BOOL) eeaRegionInitialized {
    @synchronized(self) {
        if([self readObjectFromDefaults:BRANCH_PREFS_KEY_DMA_EEA])
            return YES;
        return NO;
    }
}

- (BOOL) eeaRegion {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:BRANCH_PREFS_KEY_DMA_EEA];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return NO;
    }
}

- (void) setEeaRegion:(BOOL)isEEARegion {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:isEEARegion];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_DMA_EEA value:b];
    }
}

- (BOOL) adPersonalizationConsent {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:BRANCH_PREFS_KEY_DMA_AD_PERSONALIZATION];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return NO;
    }
}

- (void) setAdPersonalizationConsent:(BOOL)hasConsent {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:hasConsent];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_DMA_AD_PERSONALIZATION value:b];
    }
}

- (BOOL) adUserDataUsageConsent {
    @synchronized(self) {
        NSNumber *b = (id) [self readObjectFromDefaults:BRANCH_PREFS_KEY_DMA_AD_USER_DATA];
        if ([b isKindOfClass:NSNumber.class]) return [b boolValue];
        return NO;
    }
}

- (void) setAdUserDataUsageConsent:(BOOL)hasConsent {
    @synchronized(self) {
        NSNumber *b = [NSNumber numberWithBool:hasConsent];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_DMA_AD_USER_DATA value:b];
    }
}

- (BOOL) attributionLevelInitialized {
    @synchronized(self) {
        if([self readObjectFromDefaults:BRANCH_PREFS_KEY_ATTRIBUTION_LEVEL])
            return YES;
        return NO;
    }
}

- (BranchAttributionLevel)attributionLevel {
    return [self readStringFromDefaults:BRANCH_PREFS_KEY_ATTRIBUTION_LEVEL];
}

- (void)setAttributionLevel:(BranchAttributionLevel)level {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_ATTRIBUTION_LEVEL value:level];
}

- (NSString *) uxType {
    if (!_uxType) {
        _uxType = [self readStringFromDefaults:BRANCH_PREFS_KEY_UX_TYPE];
    }
    return _uxType;
}

- (void) setUxType:(NSString *)uxType {
    @synchronized(self) {
        if (![_uxType isEqualToString:uxType]) {
            _uxType = uxType;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_UX_TYPE value:uxType];
        }
    }
}

- (NSDate*) urlLoadMs {
    @synchronized (self) {
        if (!_urlLoadMs) {
            _urlLoadMs = (NSDate*)[self readObjectFromDefaults:BRANCH_PREFS_KEY_URL_LOAD_MS];
            if ([_urlLoadMs isKindOfClass:[NSDate class]]) return _urlLoadMs;
            return nil;
        }
        return _urlLoadMs;
    }
}

- (void) setUrlLoadMs:(NSDate *)urlLoadMs {
    @synchronized (self) {
        if (![_urlLoadMs isEqualToDate:urlLoadMs]) {
            _urlLoadMs = urlLoadMs;
            [self writeObjectToDefaults:BRANCH_PREFS_KEY_URL_LOAD_MS value:urlLoadMs];
        }
    }
}


- (void) clearTrackingInformation {
    @synchronized(self) {
        /*
         // Don't clear these
         self.randomizedDeviceToken = nil;
         self.randomizedBundleToken = nil;
         */
        self.sessionID = nil;
        self.linkClickIdentifier = nil;
        self.spotlightIdentifier = nil;
        self.referringURL = nil;
        self.universalLinkUrl = nil;
        self.initialReferrer = nil;
        self.installParams = nil;
        self.sessionParams = nil;
        self.externalIntentURI = nil;
        self.savedAnalyticsData = nil;
        self.previousAppBuildDate = nil;
        self.requestMetadataDictionary = nil;
        self.lastStrongMatchDate = nil;
        self.userIdentity = nil;
        self.referringURLQueryParameters = nil;
        self.anonID = nil;
        [[BranchLogger shared] logVerbose:@"Tracking information cleared" error:nil];
    }
}

#pragma mark - Count Storage

- (void)saveBranchAnalyticsData:(NSDictionary *)analyticsData {
    if (_sessionID) {
        if (!_savedAnalyticsData) {
            _savedAnalyticsData = [self getBranchAnalyticsData];
        }
        NSMutableArray *viewDataArray = [_savedAnalyticsData objectForKey:_sessionID];
        if (!viewDataArray) {
            viewDataArray = [[NSMutableArray alloc] init];
            [_savedAnalyticsData setObject:viewDataArray forKey:_sessionID];
        }
        [viewDataArray addObject:analyticsData];
        [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA value:_savedAnalyticsData];
    }
}

- (void)clearBranchAnalyticsData {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA value:nil];
    _savedAnalyticsData = nil;
}

- (NSMutableDictionary *)getBranchAnalyticsData {
    NSMutableDictionary *analyticsDataObj = _savedAnalyticsData;
    if (!analyticsDataObj) {
        analyticsDataObj = (NSMutableDictionary *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_ANALYTICAL_DATA];
        if (!analyticsDataObj) {
            analyticsDataObj = [[NSMutableDictionary alloc] init];
        }
    }
    return analyticsDataObj;
}

- (void)saveContentAnalyticsManifest:(NSDictionary *)cdManifest {
    [self writeObjectToDefaults:BRANCH_PREFS_KEY_ANALYTICS_MANIFEST value:cdManifest];
}

- (NSDictionary *)getContentAnalyticsManifest {
    return (NSDictionary *)[self readObjectFromDefaults:BRANCH_PREFS_KEY_ANALYTICS_MANIFEST];
}

#pragma mark - Writing To Persistence

- (void)writeIntegerToDefaults:(NSString *)key value:(NSInteger)value {
    [self writeObjectToDefaults:key value:@(value)];
}

- (void)writeBoolToDefaults:(NSString *)key value:(BOOL)value {
    [self writeObjectToDefaults:key value:@(value)];
}

- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value {
    @synchronized (self) {
        if (value) {
            self.persistenceDict[key] = value;
        } else {
            [self.persistenceDict removeObjectForKey:key];
        }
        [self persistPrefsToDisk];
    }
}

- (void)persistPrefsToDisk {
    if (self.useStorage) {
        @synchronized (self) {
            if (!self.persistenceDict) return;
            
            NSData *data = [self serializePrefDict:self.persistenceDict];
            if (!data) return;
            
            NSURL *prefsURL = [self.class.URLForPrefsFile copy];
            NSBlockOperation *newPersistOp = [NSBlockOperation blockOperationWithBlock:^ {
                NSError *error = nil;
                [data writeToURL:prefsURL options:NSDataWritingAtomic error:&error];
                if (error) {
                    [[BranchLogger shared] logWarning:@"Failed to persist preferences" error:error];
                }
            }];
            [_persistPrefsQueue addOperation:newPersistOp];
        }
    }
}

- (NSData *)serializePrefDict:(NSMutableDictionary *)dict {
    if (dict == nil) return nil;
    
    NSData *data = nil;
    @try {
        data = [NSKeyedArchiver archivedDataWithRootObject:dict requiringSecureCoding:YES error:NULL];
    } @catch (NSException *exception) {
        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Exception serializing preferences dict: %@.", exception] error:nil];
    }
    return data;
}

+ (void) clearAll {
    NSURL *prefsURL = [self.URLForPrefsFile copy];
    if (prefsURL) [[NSFileManager defaultManager] removeItemAtURL:prefsURL error:nil];
}

#pragma mark - Reading From Persistence

- (NSMutableDictionary *)persistenceDict {
    @synchronized(self) {
        if (!_persistenceDict) {
            if (self.useStorage) {
                _persistenceDict = [self deserializePrefDictFromData:[self loadPrefData]];
            } else {
                _persistenceDict = [[NSMutableDictionary alloc] init];
            }
        }
        return _persistenceDict;
    }
}

- (NSData *)loadPrefData {
    NSData *data = nil;
    @try {
        NSError *error = nil;
        data = [NSData dataWithContentsOfURL:self.class.URLForPrefsFile options:0 error:&error];
        if (error || !data) {
            [[BranchLogger shared] logWarning:@"Failed to load preferences from storage. This is expected on first run." error:error];
        }
    } @catch (NSException *exception) {
        [[BranchLogger shared] logError:[NSString stringWithFormat:@"Exception loading preferences dict: %@.", exception] error:nil];
    }
    return data;
}

- (NSMutableDictionary *)deserializePrefDictFromData:(NSData *)data {
    NSDictionary *dict = nil;
    if (data) {
        NSError *error = nil;
        NSSet *classes = [[NSMutableSet alloc] initWithArray:@[ NSNumber.class, NSString.class, NSDate.class, NSArray.class, NSDictionary.class ]];

        dict = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
        if (error) {
            [[BranchLogger shared] logWarning:@"Failed to load preferences from storage." error:error];
        }
    }
    
    // NSKeyedUnarchiver returns an NSDictionary, convert to NSMutableDictionary
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        return [dict mutableCopy];
    } else {
        
        // if nothing was loaded, default to an empty dictionary
        return [[NSMutableDictionary alloc] init];
    }
}

- (NSObject *)readObjectFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSObject *obj = self.persistenceDict[key];
        return obj;
    }
}

- (NSString *)readStringFromDefaults:(NSString *)key {
    @synchronized(self) {
        id str = self.persistenceDict[key];
        
        // protect against NSNumber
        if ([str isKindOfClass:[NSNumber class]]) {
            str = [str stringValue];
        }
        
        // protect against anything else
        if (![str isKindOfClass:[NSString class]]) {
            str = nil;
        }
        
        return str;
    }
}

- (BOOL)readBoolFromDefaults:(NSString *)key {
    @synchronized(self) {
        BOOL boo = NO;

        NSNumber *boolean = self.persistenceDict[key];
        if ([boolean respondsToSelector:@selector(boolValue)]) {
            boo = [boolean boolValue];
        }
        
        return boo;
    }
}

- (NSInteger)readIntegerFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSNumber *number = self.persistenceDict[key];
        if (number != nil && [number respondsToSelector:@selector(integerValue)]) {
            return [number integerValue];
        }
        return NSNotFound;
    }
}

- (double)readDoubleFromDefaults:(NSString *)key {
    @synchronized(self) {
        NSNumber *number = self.persistenceDict[key];
        if (number != nil && [number respondsToSelector:@selector(doubleValue)]){
            return [number doubleValue];
        }
        return NSNotFound;
    }
}

#pragma mark - Preferences File URL

+ (NSURL* _Nonnull) URLForPrefsFile {
    NSURL *URL = BNCURLForBranchDirectory();
    URL = [URL URLByAppendingPathComponent:BRANCH_PREFS_FILE isDirectory:NO];
    return URL;
}

@end

#pragma mark - BNCURLForBranchDirectory

NSURL* _Null_unspecified BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(NSSearchPathDirectory directory) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:directory inDomains:NSUserDomainMask | NSLocalDomainMask];

    for (NSURL *URL in URLs) {
        NSError *error = nil;
        NSURL *branchURL = [[NSURL alloc] initWithString:@"io.branch" relativeToURL:URL];
        BOOL success =
            [fileManager
                createDirectoryAtURL:branchURL
                withIntermediateDirectories:YES
                attributes:nil
                error:&error];
        if (success) {
            [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Using storage URL %@", branchURL] error:error];
            return branchURL;
        } else  {
            [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Failed to create URL %@", branchURL] error:error];
        }
    }
    return nil;
}

NSURL* _Nonnull BNCURLForBranchDirectory_Unthreaded(void) {
    #if TARGET_OS_TV
    // tvOS only allows the caches or temp directory
    NSArray *kSearchDirectories = @[
        @(NSCachesDirectory)
    ];
    #else
    NSArray *kSearchDirectories = @[
        @(NSApplicationSupportDirectory),
        @(NSLibraryDirectory),
        @(NSCachesDirectory),
        @(NSDocumentDirectory),
    ];
    #endif
    
    for (NSNumber *directory in kSearchDirectories) {
        NSSearchPathDirectory directoryValue = [directory unsignedLongValue];
        NSURL *URL = BNCCreateDirectoryForBranchURLWithSearchPath_Unthreaded(directoryValue);
        if (URL) return URL;
    }

    //  Worst case backup plan.  This does NOT work on tvOS.
    NSString *path = [@"~/Library/io.branch" stringByExpandingTildeInPath];
    NSURL *branchURL = [NSURL fileURLWithPath:path isDirectory:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL success =
        [fileManager
            createDirectoryAtURL:branchURL
            withIntermediateDirectories:YES
            attributes:nil
            error:&error];
    if (success) {
        [[BranchLogger shared] logVerbose:[NSString stringWithFormat:@"Using storage URL %@", branchURL] error:error];
    } else {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Failed to create URL %@", branchURL] error:error];
        [[BranchLogger shared] logError:@"Failed all attempts to create URLs to BNCPreferenceHelper storage." error:nil];
    }
    return branchURL;
}

NSURL* _Nonnull BNCURLForBranchDirectory(void) {
    static NSURL *urlForBranchDirectory = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^ {
        urlForBranchDirectory = BNCURLForBranchDirectory_Unthreaded();
    });
    return urlForBranchDirectory;
}

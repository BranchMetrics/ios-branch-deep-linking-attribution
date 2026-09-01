//
//  BranchConfiguration.m
//  BranchSDK
//
//  Created by Brandon Boothe on 7/21/26.
//

#import "BranchConfiguration.h"
#import "BranchConfiguration+Private.h"
#import "NSError+Branch.h"

// Defaults mirror BNCPreferenceHelper (DEFAULT_TIMEOUT, DEFAULT_RETRY_COUNT, DEFAULT_RETRY_INTERVAL).
static const NSTimeInterval BranchConfigurationDefaultNetworkTimeout = 5.5;
static const NSInteger      BranchConfigurationDefaultRetryCount     = 3;
static const NSTimeInterval BranchConfigurationDefaultRetryInterval  = 0;

// Mirrors BNCPreferenceHelper's DEFAULT_THIRD_PARTY_APIS_TIMEOUT (500ms).
static const NSTimeInterval BranchConfigurationDefaultThirdPartyAPIsWaitTime = 0.5;

// Network timeout ceiling, matching the Android builder's 60s cap.
static const NSTimeInterval BranchConfigurationMaxNetworkTimeout = 60;

// Ceiling for the third-party API wait time, matching +[Branch setSDKWaitTimeForThirdPartyAPIs:].
static const NSTimeInterval BranchConfigurationMaxThirdPartyAPIsWaitTime = 10;

@interface BranchConfiguration ()
@property (nonatomic, copy, readwrite) NSString *branchKey;
@property (nonatomic, assign, readwrite) BOOL logLevelWasSet;
@property (nonatomic, assign, readwrite) BOOL euEndpointWasSet;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableAllowedSchemes;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableUrlPatternsToIgnore;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableRequestMetadata;
@end

@implementation BranchConfiguration

- (instancetype)initWithKey:(NSString *)branchKey {
    self = [super init];
    if (!self) return self;

    _branchKey = [branchKey copy];

    // Identity & environment
    _testMode = NO;
    _apiUrl = nil;
    _safeTrackAPIUrl = nil;
    _cdnBaseUrl = nil;
    _euEndpoint = NO;
    _euEndpointWasSet = NO;

    // Logging
    _logLevel = BranchLogLevelError;
    _logLevelWasSet = NO;
    _loggingCallback = nil;
    _requestTracingCallback = nil;

    // Network
    _networkTimeout = BranchConfigurationDefaultNetworkTimeout;
    _retryCount = BranchConfigurationDefaultRetryCount;
    _retryInterval = BranchConfigurationDefaultRetryInterval;
    _remoteInterface = nil;
    _thirdPartyAPIsWaitTime = BranchConfigurationDefaultThirdPartyAPIsWaitTime;

    // Privacy & attribution
    _attributionLevel = nil;
    _limitFacebookAttribution = NO;
    _adNetworkCalloutsDisabled = NO;
    _dmaParameters = nil;

    // Collections
    _mutableAllowedSchemes = [NSMutableArray array];
    _mutableUrlPatternsToIgnore = [NSMutableArray array];
    _mutableRequestMetadata = [NSMutableDictionary dictionary];

    // Open tracking
    _automaticOpenEvents = YES;

    // Pasteboard
    _checkPasteboardOnInstall = NO;

    // App Clip
    _appClipAppGroup = nil;

    // Debugging
    _deepLinkDebugParams = nil;

    return self;
}

#pragma mark - Logging

// BranchLogLevel is a non-optional enum whose first case, BranchLogLevelVerbose, is 0, so the value
// alone cannot distinguish "never set" from "set to Verbose". Record the assignment instead.
- (void)setLogLevel:(BranchLogLevel)logLevel {
    _logLevel = logLevel;
    _logLevelWasSet = YES;
}

#pragma mark - Identity & environment

// A BOOL cannot distinguish "never set" from "set to NO", so an unset euEndpoint would leave
// -[Branch useEUEndpoints] as the only way to reach EU routing and no way at all to turn it back
// off. Record the assignment so `euEndpoint = NO` is honored as an explicit choice.
- (void)setEuEndpoint:(BOOL)euEndpoint {
    _euEndpoint = euEndpoint;
    _euEndpointWasSet = YES;
}

#pragma mark - Factory helpers

+ (instancetype)debug:(NSString *)branchKey {
    BranchConfiguration *config = [[self alloc] initWithKey:branchKey];
    config.logLevel = BranchLogLevelVerbose;
    config.testMode = YES;
    return config;
}

+ (instancetype)production:(NSString *)branchKey {
    BranchConfiguration *config = [[self alloc] initWithKey:branchKey];
    config.logLevel = BranchLogLevelWarning;
    return config;
}

+ (instancetype)compliance:(NSString *)branchKey {
    BranchConfiguration *config = [[self alloc] initWithKey:branchKey];
    config.attributionLevel = BranchAttributionLevelMinimal;
    return config;
}

#pragma mark - Collection accessors

- (NSArray<NSString *> *)allowedSchemes {
    return [self.mutableAllowedSchemes copy];
}

- (NSArray<NSString *> *)urlPatternsToIgnore {
    return [self.mutableUrlPatternsToIgnore copy];
}

- (NSDictionary<NSString *, NSString *> *)requestMetadata {
    return [self.mutableRequestMetadata copy];
}

- (void)addAllowedScheme:(NSString *)scheme {
    if (scheme) {
        [self.mutableAllowedSchemes addObject:scheme];
    }
}

- (void)addMetadataWithKey:(NSString *)key value:(NSString *)value {
    if (key && value) {
        self.mutableRequestMetadata[key] = value;
    }
}

// The collection setters replace the backing store outright rather than merging, so assigning after
// -addAllowedScheme: / -addMetadataWithKey:value: discards those entries. Assigning nil clears the
// collection instead of leaving a nil store, keeping the readonly-style getters non-nil.
- (void)setAllowedSchemes:(nullable NSArray<NSString *> *)allowedSchemes {
    self.mutableAllowedSchemes = [allowedSchemes mutableCopy] ?: [NSMutableArray array];
}

- (void)setRequestMetadata:(nullable NSDictionary<NSString *, NSString *> *)requestMetadata {
    self.mutableRequestMetadata = [requestMetadata mutableCopy] ?: [NSMutableDictionary dictionary];
}

- (void)setUrlPatternsToIgnore:(NSArray<NSString *> *)urlPatternsToIgnore {
    self.mutableUrlPatternsToIgnore = [urlPatternsToIgnore mutableCopy] ?: [NSMutableArray array];
}

#pragma mark - Validation

- (BOOL)validate:(NSError *_Nullable *_Nullable)error {
    if (self.branchKey.length == 0) {
        return [self failValidation:@"Branch key cannot be empty. Get your key from dashboard.branch.io/settings."
                              error:error];
    }
    if (self.networkTimeout <= 0) {
        return [self failValidation:[NSString stringWithFormat:@"Network timeout must be a positive number of seconds (got %.2f).", self.networkTimeout]
                              error:error];
    }
    if (self.networkTimeout > BranchConfigurationMaxNetworkTimeout) {
        return [self failValidation:[NSString stringWithFormat:@"Network timeout cannot exceed 60 seconds (got %.2f).", self.networkTimeout]
                              error:error];
    }
    if (self.retryCount < 0) {
        return [self failValidation:[NSString stringWithFormat:@"Retry count must be >= 0 (got %ld).", (long)self.retryCount]
                              error:error];
    }
    if (self.retryInterval < 0) {
        return [self failValidation:[NSString stringWithFormat:@"Retry interval must be >= 0 seconds (got %.2f).", self.retryInterval]
                              error:error];
    }
    if (self.thirdPartyAPIsWaitTime <= 0 || self.thirdPartyAPIsWaitTime > BranchConfigurationMaxThirdPartyAPIsWaitTime) {
        return [self failValidation:[NSString stringWithFormat:@"Third-party APIs wait time must be > 0 and <= 10 seconds (got %.2f).", self.thirdPartyAPIsWaitTime]
                              error:error];
    }
    if (self.remoteInterface && ![self.remoteInterface conformsToProtocol:@protocol(BNCNetworkServiceProtocol)]) {
        return [self failValidation:[NSString stringWithFormat:@"remoteInterface class '%@' must conform to BNCNetworkServiceProtocol.",
                                     NSStringFromClass(self.remoteInterface)]
                              error:error];
    }
    if (self.apiUrl && !([self.apiUrl hasPrefix:@"http://"] || [self.apiUrl hasPrefix:@"https://"])) {
        return [self failValidation:[NSString stringWithFormat:@"A custom apiUrl must either have a prefix of http:// or https:// (got '%@').", self.apiUrl]
                              error:error];
    }
    if (self.safeTrackAPIUrl && !([self.safeTrackAPIUrl hasPrefix:@"http://"] || [self.safeTrackAPIUrl hasPrefix:@"https://"])) {
        return [self failValidation:[NSString stringWithFormat:@"A custom safeTrackAPIUrl must either have a prefix of http:// or https:// (got '%@').", self.safeTrackAPIUrl]
                              error:error];
    }
    return YES;
}

// Fills the caller's out-param, when supplied, with a BNCInvalidConfigurationError carrying `message`
// as its failure reason. Always returns NO so each check above can `return [self failValidation:…]`.
- (BOOL)failValidation:(NSString *)message error:(NSError *_Nullable *_Nullable)error {
    NSError *validationError = [NSError branchErrorWithCode:BNCInvalidConfigurationError localizedMessage:message];
    [[BranchLogger shared] logError:message error:validationError];
    if (error) {
        *error = validationError;
    }
    return NO;
}

@end

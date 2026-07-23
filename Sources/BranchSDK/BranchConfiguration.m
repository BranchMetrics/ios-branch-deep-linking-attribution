//
//  BranchConfiguration.m
//  BranchSDK
//
//  Created by Brandon Boothe on 7/21/26.
//

#import "BranchConfiguration.h"

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

    // Logging
    _logLevel = BranchLogLevelError;
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

- (void)setUrlPatternsToIgnore:(NSArray<NSString *> *)urlPatternsToIgnore {
    self.mutableUrlPatternsToIgnore = [urlPatternsToIgnore mutableCopy] ?: [NSMutableArray array];
}

#pragma mark - Validation

- (void)validate {
    if (self.branchKey.length == 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Branch key cannot be empty. Get your key from dashboard.branch.io/settings."];
    }
    if (self.networkTimeout <= 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Network timeout must be a positive number of seconds (got %.2f).", self.networkTimeout];
    }
    if (self.networkTimeout > BranchConfigurationMaxNetworkTimeout) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Network timeout cannot exceed 60 seconds (got %.2f).", self.networkTimeout];
    }
    if (self.retryCount < 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Retry count must be >= 0 (got %ld).", (long)self.retryCount];
    }
    if (self.retryInterval < 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Retry interval must be >= 0 seconds (got %.2f).", self.retryInterval];
    }
    if (self.thirdPartyAPIsWaitTime <= 0 || self.thirdPartyAPIsWaitTime > BranchConfigurationMaxThirdPartyAPIsWaitTime) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Third-party APIs wait time must be > 0 and <= 10 seconds (got %.2f).", self.thirdPartyAPIsWaitTime];
    }
    if (self.remoteInterface && ![self.remoteInterface conformsToProtocol:@protocol(BNCNetworkServiceProtocol)]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"remoteInterface class '%@' must conform to BNCNetworkServiceProtocol.",
                           NSStringFromClass(self.remoteInterface)];
    }
}

@end

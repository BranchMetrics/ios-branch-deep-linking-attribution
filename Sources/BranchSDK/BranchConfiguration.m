//
//  BranchConfiguration.m
//  BranchSDK
//
//  Created by Brandon Boothe on 7/20/26.
//

#import "BranchConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - BranchConfiguration

// Redeclare properties as readwrite internally so the builder can populate them.
@interface BranchConfiguration ()
@property (nonatomic, copy, readwrite) NSString *branchKey;
@property (nonatomic, assign, readwrite) BOOL useTestInstance;
@property (nonatomic, copy, readwrite, nullable) NSString *apiURL;
@property (nonatomic, assign, readwrite) BOOL useEUEndpoints;
@property (nonatomic, assign, readwrite) BranchLogLevel logLevel;
@property (nonatomic, copy, readwrite, nullable) BranchLogCallback logCallback;
@property (nonatomic, copy, readwrite, nullable) BranchAdvancedLogCallback advancedLogCallback;
@property (nonatomic, copy, readwrite, nullable) callbackForTracingRequests requestTracingCallback;
@property (nonatomic, strong, readwrite, nullable) NSNumber *networkTimeout;
@property (nonatomic, strong, readwrite, nullable) NSNumber *maxRetries;
@property (nonatomic, strong, readwrite, nullable) NSNumber *retryInterval;
@property (nonatomic, strong, readwrite, nullable) Class networkServiceClass;
@property (nonatomic, copy, readwrite, nullable) BranchAttributionLevel attributionLevel;
@property (nonatomic, strong, readwrite, nullable) NSNumber *dmaEEARegion;
@property (nonatomic, strong, readwrite, nullable) NSNumber *dmaAdPersonalizationConsent;
@property (nonatomic, strong, readwrite, nullable) NSNumber *dmaAdUserDataUsageConsent;
@end

@implementation BranchConfiguration
// Pure value object — no behavior. Branch reads these fields at initialize time.
@end

#pragma mark - Factories

@implementation BranchConfiguration (Factories)

+ (BranchConfiguration *)debugWithKey:(NSString *)branchKey {
    return [[[[BranchConfigurationBuilder alloc] initWithKey:branchKey]
             setUseTestInstance:YES]
             setLogLevel:BranchLogLevelVerbose].build;
}

+ (BranchConfiguration *)productionWithKey:(NSString *)branchKey {
    return [[[BranchConfigurationBuilder alloc] initWithKey:branchKey]
            setLogLevel:BranchLogLevelWarning].build;
}

+ (BranchConfiguration *)complianceWithKey:(NSString *)branchKey {
    return [[[BranchConfigurationBuilder alloc] initWithKey:branchKey]
            setAttributionLevel:BranchAttributionLevelMinimal].build;
}

@end

#pragma mark - BranchConfigurationBuilder

@interface BranchConfigurationBuilder ()
@property (nonatomic, copy) NSString *branchKey;
@property (nonatomic, assign) BOOL useTestInstance;
@property (nonatomic, copy, nullable) NSString *apiURL;
@property (nonatomic, assign) BOOL useEUEndpoints;
@property (nonatomic, assign) BranchLogLevel logLevel;
@property (nonatomic, copy, nullable) BranchLogCallback logCallback;
@property (nonatomic, copy, nullable) BranchAdvancedLogCallback advancedLogCallback;
@property (nonatomic, copy, nullable) callbackForTracingRequests requestTracingCallback;
@property (nonatomic, strong, nullable) NSNumber *networkTimeout;
@property (nonatomic, strong, nullable) NSNumber *maxRetries;
@property (nonatomic, strong, nullable) NSNumber *retryInterval;
@property (nonatomic, strong, nullable) Class networkServiceClass;
@property (nonatomic, copy, nullable) BranchAttributionLevel attributionLevel;
@property (nonatomic, strong, nullable) NSNumber *dmaEEARegion;
@property (nonatomic, strong, nullable) NSNumber *dmaAdPersonalizationConsent;
@property (nonatomic, strong, nullable) NSNumber *dmaAdUserDataUsageConsent;
@end

@implementation BranchConfigurationBuilder

- (instancetype)initWithKey:(NSString *)branchKey {
    self = [super init];
    if (self) {
        _branchKey = [branchKey copy];
        _logLevel = BranchLogLevelNone;
    }
    return self;
}

// Each setter only mutates the builder's own state and returns self.

- (instancetype)setUseTestInstance:(BOOL)useTestInstance {
    self.useTestInstance = useTestInstance;
    return self;
}

- (instancetype)setApiURL:(NSString *)apiURL {
    self.apiURL = apiURL;
    return self;
}

- (instancetype)setUseEUEndpoints:(BOOL)useEUEndpoints {
    self.useEUEndpoints = useEUEndpoints;
    return self;
}

- (instancetype)setLogLevel:(BranchLogLevel)logLevel {
    self.logLevel = logLevel;
    return self;
}

- (instancetype)setLogCallback:(BranchLogCallback)logCallback {
    self.logCallback = logCallback;
    return self;
}

- (instancetype)setAdvancedLogCallback:(BranchAdvancedLogCallback)advancedLogCallback {
    self.advancedLogCallback = advancedLogCallback;
    return self;
}

- (instancetype)setRequestTracingCallback:(callbackForTracingRequests)callback {
    self.requestTracingCallback = callback;
    return self;
}

- (instancetype)setNetworkTimeout:(NSTimeInterval)networkTimeout {
    self.networkTimeout = @(networkTimeout);
    return self;
}

- (instancetype)setMaxRetries:(NSInteger)maxRetries {
    self.maxRetries = @(maxRetries);
    return self;
}

- (instancetype)setRetryInterval:(NSTimeInterval)retryInterval {
    self.retryInterval = @(retryInterval);
    return self;
}

- (instancetype)setNetworkServiceClass:(Class)networkServiceClass {
    self.networkServiceClass = networkServiceClass;
    return self;
}

- (instancetype)setAttributionLevel:(BranchAttributionLevel)attributionLevel {
    self.attributionLevel = attributionLevel;
    return self;
}

- (instancetype)setDMAParamsForEEA:(BOOL)eeaRegion
          adPersonalizationConsent:(BOOL)adPersonalizationConsent
            adUserDataUsageConsent:(BOOL)adUserDataUsageConsent {
    self.dmaEEARegion = @(eeaRegion);
    self.dmaAdPersonalizationConsent = @(adPersonalizationConsent);
    self.dmaAdUserDataUsageConsent = @(adUserDataUsageConsent);
    return self;
}

- (BranchConfiguration *)build {
    [self validate];

    BranchConfiguration *config = [[BranchConfiguration alloc] init];
    config.branchKey = self.branchKey;
    config.useTestInstance = self.useTestInstance;
    config.apiURL = self.apiURL;
    config.useEUEndpoints = self.useEUEndpoints;
    config.logLevel = self.logLevel;
    config.logCallback = self.logCallback;
    config.advancedLogCallback = self.advancedLogCallback;
    config.requestTracingCallback = self.requestTracingCallback;
    config.networkTimeout = self.networkTimeout;
    config.maxRetries = self.maxRetries;
    config.retryInterval = self.retryInterval;
    config.networkServiceClass = self.networkServiceClass;
    config.attributionLevel = self.attributionLevel;
    config.dmaEEARegion = self.dmaEEARegion;
    config.dmaAdPersonalizationConsent = self.dmaAdPersonalizationConsent;
    config.dmaAdUserDataUsageConsent = self.dmaAdUserDataUsageConsent;
    return config;
}

- (void)validate {
    if (self.branchKey.length == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:@"BranchConfiguration requires a non-empty Branch key."
                                    userInfo:nil];
    }
    if (![self.branchKey hasPrefix:@"key_live_"] && ![self.branchKey hasPrefix:@"key_test_"]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:@"Branch key must begin with \"key_live_\" or \"key_test_\"."
                                    userInfo:nil];
    }
    if (self.networkTimeout && (self.networkTimeout.doubleValue < 0 || self.networkTimeout.doubleValue > 60)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:@"networkTimeout must be between 0 and 60 seconds."
                                    userInfo:nil];
    }
    if (self.retryInterval && (self.retryInterval.doubleValue < 0 || self.retryInterval.doubleValue > 60)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:@"retryInterval must be between 0 and 60 seconds."
                                    userInfo:nil];
    }
    if (self.maxRetries && self.maxRetries.integerValue < 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:@"maxRetries must be >= 0."
                                    userInfo:nil];
    }
}

@end

NS_ASSUME_NONNULL_END

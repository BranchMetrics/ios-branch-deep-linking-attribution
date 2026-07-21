//
//  BranchConfiguration.h
//  BranchSDK
//
//  Created by Brandon Boothe on 7/20/26.
//

#import <Foundation/Foundation.h>
#import "BranchLogger.h"
#import "BNCCallbacks.h"
#import "BNCNetworkServiceProtocol.h"

// BranchAttributionLevel is declared as an NS_STRING_ENUM in Branch.h.
typedef NSString * BranchAttributionLevel NS_STRING_ENUM;

NS_ASSUME_NONNULL_BEGIN

/**
 *  BranchConfiguration holds every pre-init decision for the SDK. It is an
 *  immutable value object: build one with BranchConfigurationBuilder (or a
 *  factory below) and pass it to +[Branch initializeWithConfiguration:] /
 *  +[Branch initializeWithScene:config:].
 *
 *  This object does no work. It never touches the network layer, logger, or
 *  Branch singleton — Branch reads these values at initialize time and applies
 *  them. Settings that legitimately change at runtime (user identity, per-request
 *  metadata, attribution level in response to a privacy choice) remain instance
 *  methods on Branch and are intentionally absent here.
 */
@interface BranchConfiguration : NSObject

// MARK: - Identity & environment
/// Required. Must begin with "key_live_" or "key_test_".
@property (nonatomic, copy, readonly) NSString *branchKey;
/// When YES, routes to the test environment.
@property (nonatomic, assign, readonly) BOOL useTestInstance;
/// Optional custom API base URL. nil = use the SDK default.
@property (nonatomic, copy, readonly, nullable) NSString *apiURL;
/// When YES, routes requests to Branch's EU region endpoints.
@property (nonatomic, assign, readonly) BOOL useEUEndpoints;

// MARK: - Logging
@property (nonatomic, assign, readonly) BranchLogLevel logLevel;
/// Optional custom log sink.
@property (nonatomic, copy, readonly, nullable) BranchLogCallback logCallback;
/// Optional advanced log sink (includes request/response).
@property (nonatomic, copy, readonly, nullable) BranchAdvancedLogCallback advancedLogCallback;
/// Optional per-request tracing hook.
@property (nonatomic, copy, readonly, nullable) callbackForTracingRequests requestTracingCallback;

// MARK: - Network
/// Optional. nil = SDK default. Boxed so "unset" is distinguishable from 0.
@property (nonatomic, strong, readonly, nullable) NSNumber *networkTimeout;   // NSTimeInterval (seconds)
@property (nonatomic, strong, readonly, nullable) NSNumber *maxRetries;       // NSInteger
@property (nonatomic, strong, readonly, nullable) NSNumber *retryInterval;    // NSTimeInterval (seconds)
/// Optional custom network layer conforming to BNCNetworkServiceProtocol.
@property (nonatomic, strong, readonly, nullable) Class networkServiceClass;

// MARK: - Privacy & attribution
/// Optional. nil = SDK default (Full).
@property (nonatomic, copy, readonly, nullable) BranchAttributionLevel attributionLevel;
/// Set to YES via -setDMAParamsForEEA:... on the builder; nil otherwise.
@property (nonatomic, strong, readonly, nullable) NSNumber *dmaEEARegion;              // BOOL
@property (nonatomic, strong, readonly, nullable) NSNumber *dmaAdPersonalizationConsent; // BOOL
@property (nonatomic, strong, readonly, nullable) NSNumber *dmaAdUserDataUsageConsent;   // BOOL

@end

#pragma mark - Builder

/**
 *  Mutable builder for BranchConfiguration. Chainable setters return self so
 *  configuration can be expressed as a fluent chain; -build validates and
 *  returns an immutable BranchConfiguration.
 */
@interface BranchConfigurationBuilder : NSObject

/// The only required input. Raises NSInvalidArgumentException at -build if empty/malformed.
- (instancetype)initWithKey:(NSString *)branchKey NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Identity & environment
- (instancetype)setUseTestInstance:(BOOL)useTestInstance;
- (instancetype)setApiURL:(NSString *)apiURL;
- (instancetype)setUseEUEndpoints:(BOOL)useEUEndpoints;

// Logging
- (instancetype)setLogLevel:(BranchLogLevel)logLevel;
- (instancetype)setLogCallback:(BranchLogCallback)logCallback;
- (instancetype)setAdvancedLogCallback:(BranchAdvancedLogCallback)advancedLogCallback;
- (instancetype)setRequestTracingCallback:(callbackForTracingRequests)callback;

// Network
- (instancetype)setNetworkTimeout:(NSTimeInterval)networkTimeout;
- (instancetype)setMaxRetries:(NSInteger)maxRetries;
- (instancetype)setRetryInterval:(NSTimeInterval)retryInterval;
- (instancetype)setNetworkServiceClass:(Class)networkServiceClass;

// Privacy & attribution
- (instancetype)setAttributionLevel:(BranchAttributionLevel)attributionLevel;
- (instancetype)setDMAParamsForEEA:(BOOL)eeaRegion
             adPersonalizationConsent:(BOOL)adPersonalizationConsent
              adUserDataUsageConsent:(BOOL)adUserDataUsageConsent;

/// Validates (non-empty key with valid prefix, timeouts within 0–60s, retries >= 0)
/// and returns an immutable BranchConfiguration. Raises NSInvalidArgumentException
/// with an actionable message on failure.
- (BranchConfiguration *)build;

@end

#pragma mark - Factories

@interface BranchConfiguration (Factories)
/// VERBOSE logging + test instance.
+ (BranchConfiguration *)debugWithKey:(NSString *)branchKey;
/// WARNING-level logging.
+ (BranchConfiguration *)productionWithKey:(NSString *)branchKey;
/// Minimal attribution level.
+ (BranchConfiguration *)complianceWithKey:(NSString *)branchKey;
@end

NS_ASSUME_NONNULL_END

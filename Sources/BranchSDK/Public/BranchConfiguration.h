//
//  BranchConfiguration.h
//  BranchSDK
//
//  Created by Brandon Boothe on 7/21/26.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import "BranchLogger.h"
#import "BNCCallbacks.h"
#import "BNCNetworkServiceProtocol.h"
#import "Branch.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `BranchConfiguration` collects every pre-init decision for the Branch SDK into a single object that
 is handed to `+[Branch initialize:]`. It is the iOS counterpart of the Android `BranchConfiguration.Builder`.

 Unlike Kotlin, Objective-C has no idiomatic inner-`Builder` / immutable-`val` pattern, so this class is a
 plain mutable configuration object: create it with a Branch key, set the properties you care about, then pass
 it to `+[Branch initialize:]`. Once you have called `initialize:`, mutating the configuration has no effect —
 `initialize:` reads a snapshot of the values.

 Only settings that are legitimately *pre-init* decisions live here. Settings that legitimately change at
 runtime — user identity, per-session partner parameters, per-request metadata, attribution level in response
 to a privacy choice — remain as instance methods on `Branch`.

 Note on parity with Android: several Android builder settings have no iOS SDK equivalent and are intentionally
 omitted here rather than added as no-ops:
   - `networkConnectTimeout` / `noConnectionRetryMax` — iOS has a single `networkTimeout` and `retryCount`.
   - `facebookAppId`, `preinstallCampaign`, `preinstallPartner`, `referringLinkAttributionForPreinstalledApps`
     — these are Android-only install-attribution features.
 */
@interface BranchConfiguration : NSObject

#pragma mark - Identity & environment

/// The Branch key (`key_live_...` or `key_test_...`). Required, must be non-empty.
@property (nonatomic, copy, readonly) NSString *branchKey;

/// When YES, Branch uses the test key found in your `Info.plist`. Default NO.
@property (nonatomic, assign) BOOL testMode;

/// Optional custom base URL for all calls to the Branch API. Must start with `http://` or `https://`.
@property (nonatomic, copy, nullable) NSString *apiUrl;

/// Optional custom base URL for non-linking ("safe track") calls to the Branch API. Must start with
/// `http://` or `https://`. Maps to `+[Branch setSafetrackAPIURL:]`.
@property (nonatomic, copy, nullable) NSString *safeTrackAPIUrl;

/// Optional custom base URL used for the CDN pattern list.
@property (nonatomic, copy, nullable) NSString *cdnBaseUrl;

/// When YES, requests are routed to Branch's EU endpoints. Must also be enabled server side. Default NO.
@property (nonatomic, assign) BOOL euEndpoint;

#pragma mark - Logging

/// Log-level threshold for the Branch logging subsystem. Default `BranchLogLevelError`.
@property (nonatomic, assign) BranchLogLevel logLevel;

/// Optional custom log sink invoked for every emitted message at or above `logLevel`.
@property (nonatomic, copy, nullable) BranchLogCallback loggingCallback;

/// Optional per-request tracing hook (URL, request, response, error). Useful for debugging.
@property (nonatomic, copy, nullable) callbackForTracingRequests requestTracingCallback;

#pragma mark - Network

/// Request timeout in seconds. Must be > 0 and <= 60. Default matches the SDK default (5.5s).
@property (nonatomic, assign) NSTimeInterval networkTimeout;

/// Max number of retries on a Branch server error. Must be >= 0. Default 3.
@property (nonatomic, assign) NSInteger retryCount;

/// Seconds to wait between retries. Must be >= 0. Default 0.
@property (nonatomic, assign) NSTimeInterval retryInterval;

/// Optional network service class (must conform to `BNCNetworkServiceProtocol`) overriding Branch's networking.
@property (nonatomic, strong, nullable) Class remoteInterface;

/// SDK wait time in seconds for third-party APIs (ODM info, Apple Attribution Token). Must be > 0 and <= 10.
/// Default matches the SDK default (0.5s). Maps to `+[Branch setSDKWaitTimeForThirdPartyAPIs:]`.
@property (nonatomic, assign) NSTimeInterval thirdPartyAPIsWaitTime;

#pragma mark - Privacy & attribution

/// Optional consumer-protection attribution level. When nil, the SDK default is used.
@property (nonatomic, copy, nullable) BranchAttributionLevel attributionLevel;

/// When YES, limits Facebook attribution/tracking. Default NO.
@property (nonatomic, assign) BOOL limitFacebookAttribution;

/// When YES, disables callouts to ad networks for all events. Default NO.
@property (nonatomic, assign) BOOL adNetworkCalloutsDisabled;

/// YES once `-setDMAParamsForEEA:adPersonalizationConsent:adUserDataUsageConsent:` has been called.
@property (nonatomic, assign, readonly) BOOL dmaParametersSet;

/// DMA: whether EEA regulations apply to this user. Only applied when `dmaParametersSet` is YES.
@property (nonatomic, assign, readonly) BOOL dmaEEARegion;

/// DMA: whether the user granted ads-personalization consent. Only applied when `dmaParametersSet` is YES.
@property (nonatomic, assign, readonly) BOOL dmaAdPersonalizationConsent;

/// DMA: whether the user granted consent for 3P transmission of user-level ad data. Only applied when set.
@property (nonatomic, assign, readonly) BOOL dmaAdUserDataUsageConsent;

#pragma mark - URL collection

/// URI schemes allowed to be tracked by Branch. Empty means all schemes (the default).
@property (nonatomic, copy, readonly) NSArray<NSString *> *allowedSchemes;

/// Regex patterns matching URLs that Branch should never transmit (e.g. URLs with sensitive tokens).
@property (nonatomic, copy, readonly) NSArray<NSString *> *urlPatternsToIgnore;

#pragma mark - Request metadata

/// Key-value pairs included in the metadata on every request.
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *requestMetadata;

#pragma mark - Open tracking

/// When NO, Branch does not automatically send an open on foreground; call `-[Branch sendOpen]` manually.
/// Default YES.
@property (nonatomic, assign) BOOL automaticOpenEvents;

#pragma mark - Pasteboard

/// When YES, Branch checks the pasteboard (clipboard) for a Branch Link on app install, which may present
/// the system paste-permission toast to the user. Equivalent to calling `-[Branch checkPasteboardOnInstall]`
/// before init. Default NO.
@property (nonatomic, assign) BOOL checkPasteboardOnInstall;

#pragma mark - App Clip

/// Optional App Group identifier used to share data between an App Clip and the full app. Maps to
/// `-[Branch setAppClipAppGroup:]`, which must be set before the first session begins.
@property (nonatomic, copy, nullable) NSString *appClipAppGroup;

#pragma mark - Debugging

/// Optional constant parameters merged into every deep-link response, for debugging. Maps to
/// `-[Branch setDeepLinkDebugMode:]`. Not for production use.
@property (nonatomic, copy, nullable) NSDictionary *deepLinkDebugParams;

#pragma mark - Initialization

/**
 Designated initializer.
 @param branchKey The Branch key. Must be non-empty; validated in `-validate`.
 */
- (instancetype)initWithKey:(NSString *)branchKey NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

#pragma mark - Factory helpers

/// Debug preset: verbose logging and test mode enabled.
+ (instancetype)debug:(NSString *)branchKey;

/// Production preset: warning-level logging.
+ (instancetype)production:(NSString *)branchKey;

/// Compliance preset: minimal attribution level.
+ (instancetype)compliance:(NSString *)branchKey;

#pragma mark - Mutators for collection / grouped settings

/// Add a single URI scheme to the allow list.
- (void)addAllowedScheme:(NSString *)scheme;

/// Add a single key/value pair to the per-request metadata.
- (void)addMetadataWithKey:(NSString *)key value:(NSString *)value;

/**
 Set the parameters required by Google Conversion APIs for DMA compliance in the EEA region.
 Calling this sets `dmaParametersSet` to YES.
 */
- (void)setDMAParamsForEEA:(BOOL)eeaRegion
    adPersonalizationConsent:(BOOL)adPersonalizationConsent
     adUserDataUsageConsent:(BOOL)adUserDataUsageConsent;

#pragma mark - Validation

/**
 Validates the configuration. Raises `NSInvalidArgumentException` with an actionable message if any field
 is invalid: empty key, non-positive or > 60s timeout, negative retry count, negative retry interval, or a
 third-party APIs wait time outside (0, 10] seconds. Called automatically by `+[Branch initialize:]`.
 */
- (void)validate;

@end

NS_ASSUME_NONNULL_END

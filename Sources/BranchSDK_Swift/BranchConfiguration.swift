//
//  BranchConfiguration.swift
//  BranchSDK
//
//  Swift port of the former Objective-C BranchConfiguration.
//
//  `@objc(BranchConfiguration)` and per-member @objc names are pinned so existing
//  Objective-C call sites (`+[Branch initialize:]`) and unit tests keep working unchanged.
//

import Foundation

#if SWIFT_PACKAGE
import BranchObjCSDK
#endif

/// `BranchConfiguration` collects every pre-init decision for the Branch SDK into a single object that
/// is handed to `+[Branch initialize:]`. It is the iOS counterpart of the Android
/// `BranchConfiguration.Builder`.
///
/// Create it with a Branch key, set the properties you care about, then pass it to `+[Branch initialize:]`.
/// Once `initialize:` has been called, mutating the configuration has no effect — `initialize:` reads a
/// snapshot of the values.
@objc(BranchConfiguration)
public class BranchConfiguration: NSObject {

    // Defaults mirror BNCPreferenceHelper (DEFAULT_TIMEOUT, DEFAULT_RETRY_COUNT, DEFAULT_RETRY_INTERVAL).
    private static let defaultNetworkTimeout: TimeInterval = 5.5
    private static let defaultRetryCount: Int = 3
    private static let defaultRetryInterval: TimeInterval = 0
    // Mirrors BNCPreferenceHelper's DEFAULT_THIRD_PARTY_APIS_TIMEOUT (500ms).
    private static let defaultThirdPartyAPIsWaitTime: TimeInterval = 0.5
    // Network timeout ceiling, matching the Android builder's 60s cap.
    private static let maxNetworkTimeout: TimeInterval = 60
    // Ceiling for the third-party API wait time, matching +[Branch setSDKWaitTimeForThirdPartyAPIs:].
    private static let maxThirdPartyAPIsWaitTime: TimeInterval = 10

    // MARK: - Identity & environment

    /// The Branch key (`key_live_...` or `key_test_...`). Required, must be non-empty.
    @objc public private(set) var branchKey: String

    /// When YES, Branch uses the test key found in your `Info.plist`. Default NO.
    @objc public var testMode: Bool = false

    /// Optional custom base URL for all calls to the Branch API. Must start with `http://` or `https://`.
    @objc public var apiUrl: String?

    /// Optional custom base URL for non-linking ("safe track") calls to the Branch API.
    @objc public var safeTrackAPIUrl: String?

    /// Optional custom base URL used for the CDN pattern list.
    @objc public var cdnBaseUrl: String?

    /// When YES, requests are routed to Branch's EU endpoints. Default NO.
    @objc public var euEndpoint: Bool = false

    // MARK: - Logging

    /// Log-level threshold for the Branch logging subsystem. Default `BranchLogLevelError`.
    @objc public var logLevel: BranchLogLevel = .error

    /// Optional custom log sink invoked for every emitted message at or above `logLevel`.
    @objc public var loggingCallback: BranchLogCallback?

    /// Optional per-request tracing hook (URL, request, response, error). Useful for debugging.
    @objc public var requestTracingCallback: callbackForTracingRequests?

    // MARK: - Network

    /// Request timeout in seconds. Must be > 0 and <= 60. Default matches the SDK default (5.5s).
    @objc public var networkTimeout: TimeInterval = BranchConfiguration.defaultNetworkTimeout

    /// Max number of retries on a Branch server error. Must be >= 0. Default 3.
    @objc public var retryCount: Int = BranchConfiguration.defaultRetryCount

    /// Seconds to wait between retries. Must be >= 0. Default 0.
    @objc public var retryInterval: TimeInterval = BranchConfiguration.defaultRetryInterval

    /// Optional network service class (must conform to `BNCNetworkServiceProtocol`).
    @objc public var remoteInterface: AnyClass?

    /// SDK wait time in seconds for third-party APIs. Must be > 0 and <= 10. Default 0.5s.
    @objc public var thirdPartyAPIsWaitTime: TimeInterval = BranchConfiguration.defaultThirdPartyAPIsWaitTime

    // MARK: - Privacy & attribution

    /// Optional consumer-protection attribution level. When nil, the SDK default is used.
    @objc public var attributionLevel: BranchAttributionLevel?

    /// When YES, limits Facebook attribution/tracking. Default NO.
    @objc public var limitFacebookAttribution: Bool = false

    /// When YES, disables callouts to ad networks for all events. Default NO.
    @objc public var adNetworkCalloutsDisabled: Bool = false

    /// Optional DMA (EEA) consent parameters. When nil, no DMA parameters are sent.
    @objc public var dmaParameters: BranchDMAParameters?

    // MARK: - URL collection

    private var mutableAllowedSchemes: [String] = []
    private var mutableUrlPatternsToIgnore: [String] = []
    private var mutableRequestMetadata: [String: String] = [:]

    /// URI schemes allowed to be tracked by Branch. Empty means all schemes (the default).
    @objc public var allowedSchemes: [String] { mutableAllowedSchemes }

    /// Regex patterns matching URLs that Branch should never transmit.
    ///
    /// Historically the Objective-C header declared this `readonly` while shipping an unreachable setter and
    /// documenting it as settable on `Branch.h`. It is now a genuinely settable property.
    @objc public var urlPatternsToIgnore: [String] {
        get { mutableUrlPatternsToIgnore }
        set { mutableUrlPatternsToIgnore = newValue }
    }

    // MARK: - Request metadata

    /// Key-value pairs included in the metadata on every request.
    @objc public var requestMetadata: [String: String] { mutableRequestMetadata }

    // MARK: - Open tracking

    /// When NO, Branch does not automatically send an open on foreground. Default YES.
    @objc public var automaticOpenEvents: Bool = true

    // MARK: - Pasteboard

    /// When YES, Branch checks the pasteboard for a Branch Link on app install. Default NO.
    @objc public var checkPasteboardOnInstall: Bool = false

    // MARK: - App Clip

    /// Optional App Group identifier used to share data between an App Clip and the full app.
    @objc public var appClipAppGroup: String?

    // MARK: - Debugging

    /// Optional constant parameters merged into every deep-link response, for debugging.
    @objc public var deepLinkDebugParams: [AnyHashable: Any]?

    /// The process-wide preference store. `BranchConfiguration` can seed itself from persisted values
    /// (`load(from:)`) and push its values into it (`apply(to:)`). Both are explicit — nothing is read
    /// or written implicitly at init/validate time, so a freshly created configuration keeps its
    /// documented defaults.
    private var preferenceHelper: BNCPreferenceHelper { BNCPreferenceHelper.sharedInstance() }

    // MARK: - Initialization

    /// Designated initializer.
    /// - Parameter branchKey: The Branch key. Must be non-empty; validated in `validate()`.
    @objc public init(key branchKey: String) {
        self.branchKey = branchKey
        super.init()
    }

    // MARK: - Factory helpers

    /// Debug preset: verbose logging and test mode enabled.
    @objc public class func debug(_ branchKey: String) -> BranchConfiguration {
        let config = BranchConfiguration(key: branchKey)
        config.logLevel = .verbose
        config.testMode = true
        return config
    }

    /// Production preset: warning-level logging.
    @objc public class func production(_ branchKey: String) -> BranchConfiguration {
        let config = BranchConfiguration(key: branchKey)
        config.logLevel = .warning
        return config
    }

    /// Compliance preset: minimal attribution level.
    @objc public class func compliance(_ branchKey: String) -> BranchConfiguration {
        let config = BranchConfiguration(key: branchKey)
        config.attributionLevel = .minimal
        return config
    }

    // MARK: - Mutators for collection / grouped settings

    /// Add a single URI scheme to the allow list.
    @objc public func addAllowedScheme(_ scheme: String) {
        mutableAllowedSchemes.append(scheme)
    }

    /// Add a single key/value pair to the per-request metadata.
    @objc public func addMetadata(key: String, value: String) {
        mutableRequestMetadata[key] = value
    }

    // MARK: - Validation

    /// Validates the configuration. Raises `NSInvalidArgumentException` with an actionable message if any
    /// field is invalid. Called automatically by `+[Branch initialize:]`.
    @objc public func validate() {
        if branchKey.isEmpty {
            raiseInvalidArgument("Branch key cannot be empty. Get your key from dashboard.branch.io/settings.")
        }
        if networkTimeout <= 0 {
            raiseInvalidArgument(String(format: "Network timeout must be a positive number of seconds (got %.2f).", networkTimeout))
        }
        if networkTimeout > BranchConfiguration.maxNetworkTimeout {
            raiseInvalidArgument(String(format: "Network timeout cannot exceed 60 seconds (got %.2f).", networkTimeout))
        }
        if retryCount < 0 {
            raiseInvalidArgument("Retry count must be >= 0 (got \(retryCount)).")
        }
        if retryInterval < 0 {
            raiseInvalidArgument(String(format: "Retry interval must be >= 0 seconds (got %.2f).", retryInterval))
        }
        if thirdPartyAPIsWaitTime <= 0 || thirdPartyAPIsWaitTime > BranchConfiguration.maxThirdPartyAPIsWaitTime {
            raiseInvalidArgument(String(format: "Third-party APIs wait time must be > 0 and <= 10 seconds (got %.2f).", thirdPartyAPIsWaitTime))
        }
        if let remoteInterface = remoteInterface,
           !remoteInterface.conforms(to: BNCNetworkServiceProtocol.self) {
            raiseInvalidArgument("remoteInterface class '\(NSStringFromClass(remoteInterface))' must conform to BNCNetworkServiceProtocol.")
        }
    }

    private func raiseInvalidArgument(_ reason: String) -> Never {
        NSException(name: .invalidArgumentException, reason: reason, userInfo: nil).raise()
        // NSException.raise() does not return; this is unreachable but satisfies the `Never` contract.
        fatalError(reason)
    }

    // MARK: - Preference-helper sync

    /// Writes the pre-init values that live in the shared preference store into it. Only the settings
    /// that `BNCPreferenceHelper` actually persists are pushed; URL/network endpoint and callback
    /// settings are applied elsewhere by `+[Branch initialize:]`. Call this explicitly — it is not
    /// invoked implicitly, so constructing a configuration never mutates process-wide state.
    @objc public func apply(to preferences: BNCPreferenceHelper) {
        preferences.timeout = networkTimeout
        preferences.retryCount = retryCount
        preferences.retryInterval = retryInterval
        preferences.thirdPartyAPIsWaitTime = thirdPartyAPIsWaitTime
        preferences.limitFacebookTracking = limitFacebookAttribution
        preferences.disableAdNetworkCallouts = adNetworkCalloutsDisabled

        if let attributionLevel = attributionLevel {
            // preferences.attributionLevel is declared as NSString; bridge explicitly.
            preferences.attributionLevel = attributionLevel as NSString
        }
        if let dmaParameters = dmaParameters {
            preferences.eeaRegion = dmaParameters.eeaRegion
            preferences.adPersonalizationConsent = dmaParameters.adPersonalizationConsent
            preferences.adUserDataUsageConsent = dmaParameters.adUserDataUsageConsent
        }
    }

    /// Convenience overload that targets the shared preference store.
    @objc public func applyToSharedPreferences() {
        apply(to: preferenceHelper)
    }

    /// Seeds this configuration from values already persisted in the preference store, so a caller can
    /// start from the SDK's current state and override selectively. Only fields the store round-trips
    /// are read; the rest keep their defaults.
    @objc public func load(from preferences: BNCPreferenceHelper) {
        networkTimeout = preferences.timeout
        retryCount = preferences.retryCount
        retryInterval = preferences.retryInterval
        thirdPartyAPIsWaitTime = preferences.thirdPartyAPIsWaitTime
        limitFacebookAttribution = preferences.limitFacebookTracking
        adNetworkCalloutsDisabled = preferences.disableAdNetworkCallouts

        // preferences.attributionLevel is an NSString; BranchAttributionLevel is an NS_STRING_ENUM
        // (a distinct Swift type), so bridge NSString -> String -> BranchAttributionLevel.
        let persistedLevel = preferences.attributionLevel as String?
        if let level = persistedLevel, !level.isEmpty {
            attributionLevel = BranchAttributionLevel(rawValue: level)
        }
        if preferences.eeaRegionInitialized() {
            dmaParameters = BranchDMAParameters.eeaRegion(preferences.eeaRegion,
                                                          adPersonalizationConsent: preferences.adPersonalizationConsent,
                                                          adUserDataUsageConsent: preferences.adUserDataUsageConsent)
        }
    }

    /// Convenience overload that reads from the shared preference store.
    @objc public func loadFromSharedPreferences() {
        load(from: preferenceHelper)
    }
}

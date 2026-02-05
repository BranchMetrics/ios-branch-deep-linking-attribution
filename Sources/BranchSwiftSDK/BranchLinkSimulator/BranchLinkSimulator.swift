//
//  BranchLinkSimulator.swift
//  Branch iOS SDK - Link Simulator for Development and Testing
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  A development tool that allows simulating Branch deep link scenarios
//  without requiring actual links to be created in the Branch dashboard.
//
//  iOS 12+ compatible using GCD patterns for thread safety.
//

import Foundation

#if canImport(BranchSDK)
    import BranchSDK
#endif

// swiftlint:disable file_length type_body_length

// MARK: - SimulatedLinkData

/// Configuration for a simulated Branch link.
///
/// Use this to define the expected behavior when a simulated link is "clicked".
@objc public class SimulatedLinkData: NSObject {
    /// The simulated link URL
    @objc public let url: URL

    /// Link parameters that would be returned by Branch
    @objc public var params: [String: Any] = [:]

    /// Campaign name for attribution
    @objc public var campaign: String?

    /// Channel for attribution (e.g., "facebook", "email")
    @objc public var channel: String?

    /// Feature name (e.g., "sharing", "referral")
    @objc public var feature: String?

    /// Stage in the user journey
    @objc public var stage: String?

    /// Custom tags for categorization
    @objc public var tags: [String] = []

    /// Simulated match type
    @objc public var matchType: LinkMatchType = .exact

    /// Simulated delay before returning link data (in seconds)
    @objc public var simulatedDelay: TimeInterval = 0.1

    /// Whether to simulate a Branch link match
    @objc public var clickedBranchLink: Bool = true

    @objc public init(url: URL) {
        self.url = url
        super.init()
    }

    /// Build the complete params dictionary for the link
    func buildParams() -> [String: Any] {
        var result = params

        // Add Branch metadata
        result["+clicked_branch_link"] = clickedBranchLink
        result["~referring_link"] = url.absoluteString

        if let campaign = campaign {
            result["~campaign"] = campaign
        }
        if let channel = channel {
            result["~channel"] = channel
        }
        if let feature = feature {
            result["~feature"] = feature
        }
        if let stage = stage {
            result["~stage"] = stage
        }
        if !tags.isEmpty {
            result["~tags"] = tags
        }

        result["+match_type"] = matchType.stringValue

        return result
    }
}

// MARK: - LinkMatchType

/// Match type for simulated links.
@objc public enum LinkMatchType: Int {
    case exact = 0
    case fuzzy = 1
    case deferred = 2

    var stringValue: String {
        switch self {
        case .exact: return "exact"
        case .fuzzy: return "fuzzy"
        case .deferred: return "deferred"
        }
    }
}

// MARK: - NetworkLogEntrySendable

/// Thread-safe network log entry for iOS 12+ compatibility.
@objc public class NetworkLogEntrySendable: NSObject {
    @objc public let id: UUID
    @objc public let timestamp: Date
    @objc public let url: String
    @objc public let requestBody: [String: Any]
    @objc public let responseBody: [String: Any]?
    @objc public let statusCode: NSNumber?
    @objc public let error: String?

    public init(
        id: UUID,
        timestamp: Date,
        url: String,
        requestBody: [String: Any],
        responseBody: [String: Any]?,
        statusCode: Int?,
        error: String?
    ) {
        self.id = id
        self.timestamp = timestamp
        self.url = url
        self.requestBody = requestBody
        self.responseBody = responseBody
        self.statusCode = statusCode.map { NSNumber(value: $0) }
        self.error = error
        super.init()
    }

    /// Convenience initializer for Objective-C compatibility
    @objc public convenience init(
        id: UUID,
        timestamp: Date,
        url: String,
        requestBody: [String: Any],
        responseBody: [String: Any]?,
        statusCodeNumber: NSNumber?,
        error: String?
    ) {
        self.init(
            id: id,
            timestamp: timestamp,
            url: url,
            requestBody: requestBody,
            responseBody: responseBody,
            statusCode: statusCodeNumber?.intValue,
            error: error
        )
    }

    /// Convenience initializer to convert from NetworkLogEntry.
    convenience init(from entry: NetworkLogEntry) {
        self.init(
            id: entry.id,
            timestamp: entry.timestamp,
            url: entry.url,
            requestBody: entry.requestBody,
            responseBody: entry.responseBody,
            statusCode: entry.statusCode,
            error: entry.error
        )
    }
}

// MARK: - BranchLinkSimulatorDelegate

/// Delegate protocol for BranchLinkSimulator events.
@objc public protocol BranchLinkSimulatorDelegate: AnyObject {
    /// Called when a simulated link is processed
    @objc optional func linkSimulator(
        _ simulator: BranchLinkSimulator,
        didProcessLink url: URL,
        withParams params: [String: Any]
    )

    /// Called when a network request is intercepted
    @objc optional func linkSimulator(
        _ simulator: BranchLinkSimulator,
        didInterceptRequest url: String,
        requestBody: [String: Any]
    )

    /// Called when a network response is captured
    @objc optional func linkSimulator(
        _ simulator: BranchLinkSimulator,
        didCaptureResponse url: String,
        statusCode: Int,
        responseBody: [String: Any]?
    )
}

// MARK: - BranchLinkSimulator

/// Development tool for simulating Branch deep link scenarios.
///
/// This class provides two main capabilities:
///
/// 1. **Network Logging**: Observe all Branch SDK network traffic for debugging
/// 2. **Link Simulation**: Test deep link handling without creating real links
///
/// ## Network Logging
///
/// ```swift
/// // Enable network logging
/// BranchLinkSimulator.shared.enableNetworkLogging()
///
/// // Observe logs
/// BranchLinkSimulator.shared.onNetworkLog = { entry in
///     print("[\(entry.url)] Status: \(entry.statusCode ?? 0)")
/// }
/// ```
///
/// ## Link Simulation
///
/// ```swift
/// // Register a simulated link
/// let linkData = SimulatedLinkData(url: URL(string: "https://example.app.link/test")!)
/// linkData.params = ["product_id": "12345"]
/// linkData.campaign = "summer_sale"
///
/// BranchLinkSimulator.shared.registerLink(linkData)
///
/// // Simulate opening the link
/// BranchLinkSimulator.shared.simulateOpen(url: linkData.url) { session, error in
///     // Handle result
/// }
/// ```
///
/// ## Integration with SessionManager
///
/// BranchLinkSimulator works alongside SessionManager, allowing you to:
/// - Test initialization flows with simulated links
/// - Debug "Double Open" scenarios
/// - Validate deep link parameter handling
///
@objc public final class BranchLinkSimulator: NSObject {
    // MARK: - Singleton

    @objc public static let shared = BranchLinkSimulator()

    // MARK: - Public Properties

    /// Delegate for simulator events
    @objc public weak var delegate: BranchLinkSimulatorDelegate?

    /// Whether simulator is enabled
    @objc public private(set) var isEnabled: Bool = false

    /// Whether network logging is enabled
    @objc public private(set) var isNetworkLoggingEnabled: Bool = false

    /// Callback for network log entries (alternative to delegate)
    public var onNetworkLog: ((NetworkLogEntrySendable) -> Void)?

    /// All captured network logs (thread-safe access)
    @objc public var networkLogs: [NetworkLogEntrySendable] {
        var logs: [NetworkLogEntrySendable] = []
        isolationQueue.sync {
            logs = _networkLogs
        }
        return logs
    }

    /// Maximum number of logs to retain (default: 100)
    @objc public var maxLogCount: Int = 100

    // MARK: - Private Properties

    private let isolationQueue = DispatchQueue(
        label: "io.branch.linksimulator.isolation",
        qos: .userInitiated
    )

    /// Internal storage for network logs
    private var _networkLogs: [NetworkLogEntrySendable] = []

    /// Registered simulated links (URL string -> SimulatedLinkData)
    private var registeredLinks: [String: SimulatedLinkData] = [:]

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Enable/Disable

    /// Enable the link simulator.
    @objc public func enable() {
        isolationQueue.async { [weak self] in
            self?.isEnabled = true
        }
    }

    /// Disable the link simulator.
    @objc public func disable() {
        isolationQueue.async { [weak self] in
            self?.isEnabled = false
            self?.registeredLinks.removeAll()
        }
    }

    // MARK: - Network Logging

    /// Enable network logging to observe all Branch SDK network traffic.
    ///
    /// This connects to the Branch network layer and captures all
    /// install, open, and other API calls for debugging purposes.
    @objc public func enableNetworkLogging() {
        guard !isNetworkLoggingEnabled else { return }

        isNetworkLoggingEnabled = true

        // Use callback-based logging (iOS 12+ compatible)
        startCallbackNetworkLogging()

        // Also set up static callback for additional logging
        setupLegacyNetworkLogging()
    }

    /// Disable network logging.
    @objc public func disableNetworkLogging() {
        isNetworkLoggingEnabled = false

        // Remove the callback from BranchNetworkLogger
        BranchNetworkLogger.shared.removeCallback()

        // Remove static callback
        DefaultBranchNetworkService.logCallback = nil
    }

    /// Clear all captured network logs.
    @objc public func clearNetworkLogs() {
        isolationQueue.async { [weak self] in
            self?._networkLogs.removeAll()
        }
    }

    /// Start callback-based network logging (iOS 12+ compatible).
    ///
    /// Uses BranchNetworkLogger's callback API to receive log entries.
    private func startCallbackNetworkLogging() {
        BranchNetworkLogger.shared.setCallback { [weak self] entry in
            guard let self = self, self.isNetworkLoggingEnabled else { return }

            // Convert to sendable version
            let sendableEntry = NetworkLogEntrySendable(
                id: entry.id,
                timestamp: entry.timestamp,
                url: entry.url,
                requestBody: entry.requestBody,
                responseBody: entry.responseBody,
                statusCode: entry.statusCode,
                error: entry.error
            )

            // Store log on isolation queue
            self.isolationQueue.async {
                self._networkLogs.append(sendableEntry)
                if self._networkLogs.count > self.maxLogCount {
                    self._networkLogs.removeFirst(self._networkLogs.count - self.maxLogCount)
                }
            }

            // Notify on main thread
            DispatchQueue.main.async {
                self.onNetworkLog?(sendableEntry)

                // Notify delegate
                if let response = sendableEntry.responseBody {
                    self.delegate?.linkSimulator?(
                        self,
                        didCaptureResponse: sendableEntry.url,
                        statusCode: sendableEntry.statusCode?.intValue ?? 0,
                        responseBody: response
                    )
                } else {
                    self.delegate?.linkSimulator?(
                        self,
                        didInterceptRequest: sendableEntry.url,
                        requestBody: sendableEntry.requestBody
                    )
                }
            }
        }
    }

    private func setupLegacyNetworkLogging() {
        // Setup static callback for additional network logging (iOS 12+ compatible)
        DefaultBranchNetworkService.logCallback = { [weak self] url, requestBody, responseBody, statusCode, error in
            guard let self = self, self.isNetworkLoggingEnabled else { return }

            let entry = NetworkLogEntrySendable(
                id: UUID(),
                timestamp: Date(),
                url: url,
                requestBody: requestBody,
                responseBody: responseBody,
                statusCode: statusCode,
                error: error?.localizedDescription
            )

            self.isolationQueue.async {
                self._networkLogs.append(entry)
                if self._networkLogs.count > self.maxLogCount {
                    self._networkLogs.removeFirst(self._networkLogs.count - self.maxLogCount)
                }
            }

            DispatchQueue.main.async {
                self.onNetworkLog?(entry)

                if let responseBody = responseBody {
                    self.delegate?.linkSimulator?(
                        self,
                        didCaptureResponse: url,
                        statusCode: statusCode ?? 0,
                        responseBody: responseBody
                    )
                } else {
                    self.delegate?.linkSimulator?(
                        self,
                        didInterceptRequest: url,
                        requestBody: requestBody
                    )
                }
            }
        }
    }

    // MARK: - Link Registration

    /// Register a simulated link.
    ///
    /// - Parameter linkData: The link configuration
    @objc public func registerLink(_ linkData: SimulatedLinkData) {
        isolationQueue.async { [weak self] in
            self?.registeredLinks[linkData.url.absoluteString] = linkData
        }
    }

    /// Unregister a simulated link.
    ///
    /// - Parameter url: The link URL to unregister
    @objc public func unregisterLink(_ url: URL) {
        isolationQueue.async { [weak self] in
            self?.registeredLinks.removeValue(forKey: url.absoluteString)
        }
    }

    /// Unregister all simulated links.
    @objc public func unregisterAllLinks() {
        isolationQueue.async { [weak self] in
            self?.registeredLinks.removeAll()
        }
    }

    /// Check if a URL is registered as a simulated link.
    ///
    /// - Parameter url: The URL to check
    /// - Returns: Whether the URL is registered
    @objc public func isLinkRegistered(_ url: URL) -> Bool {
        var result = false
        isolationQueue.sync {
            result = registeredLinks[url.absoluteString] != nil
        }
        return result
    }

    /// Get simulated link data for a URL.
    ///
    /// This is called by SessionManager to retrieve simulated params for registered links.
    ///
    /// - Parameter url: The URL to look up
    /// - Returns: The simulated link data if registered, nil otherwise
    @objc public func getSimulatedLinkData(for url: URL) -> SimulatedLinkData? {
        var result: SimulatedLinkData?
        isolationQueue.sync {
            result = registeredLinks[url.absoluteString]
        }
        return result
    }

    /// Check if a URL should be handled as a simulated link.
    ///
    /// Returns true if:
    /// 1. Simulator is enabled
    /// 2. URL is registered as a simulated link
    ///
    /// - Parameter url: The URL to check
    /// - Returns: Whether the URL should be simulated
    @objc public func shouldSimulateLink(_ url: URL) -> Bool {
        guard isEnabled else { return false }
        return isLinkRegistered(url)
    }

    /// Build a simulated session for a registered link.
    ///
    /// This creates a Session object with the simulated link's parameters,
    /// bypassing network calls entirely.
    ///
    /// - Parameters:
    ///   - url: The registered link URL
    ///   - isFirstSession: Whether this is the first session (install)
    /// - Returns: A Session populated with simulated params, or nil if not registered
    @objc public func buildSimulatedSession(for url: URL, isFirstSession: Bool) -> Session? {
        guard let linkData = getSimulatedLinkData(for: url) else { return nil }

        let params = linkData.buildParams()

        let session = Session(
            id: "simulated-\(UUID().uuidString)",
            createdAt: Date(),
            identityId: "simulated-identity-\(UUID().uuidString)",
            deviceFingerprintId: "simulated-fingerprint",
            isFirstSession: isFirstSession,
            userId: nil,
            params: params
        )

        // Notify delegate
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.linkSimulator?(self, didProcessLink: url, withParams: params)
        }

        return session
    }

    // MARK: - Link Simulation

    /// Simulate opening a registered link.
    ///
    /// This calls through to `SessionManager.shared.handleDeepLink` with the
    /// simulated link's configured parameters.
    ///
    /// - Parameters:
    ///   - url: The simulated link URL (must be registered)
    ///   - completion: Callback with session result
    @objc public func simulateOpen(
        url: URL,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isEnabled else {
                let error = NSError(
                    domain: "io.branch.linksimulator",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "BranchLinkSimulator is not enabled"]
                )
                DispatchQueue.main.async { completion(nil, error) }
                return
            }

            guard let linkData = self.registeredLinks[url.absoluteString] else {
                // Not a registered link - pass through to SessionManager
                SessionManager.shared.handleDeepLink(url, completion: completion)
                return
            }

            // Simulate delay
            let delay = linkData.simulatedDelay

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                // Build simulated params
                let params = linkData.buildParams()

                // Notify delegate
                DispatchQueue.main.async {
                    self.delegate?.linkSimulator?(self, didProcessLink: url, withParams: params)
                }

                // Pass through to SessionManager with the URL
                // The SessionManager will initialize or handle the deep link
                SessionManager.shared.handleDeepLink(url, completion: completion)
            }
        }
    }

    /// Simulate opening a link with custom parameters (without registration).
    ///
    /// - Parameters:
    ///   - url: The link URL
    ///   - params: Custom parameters to include
    ///   - completion: Callback with session result
    @objc public func simulateOpen(
        url: URL,
        params: [String: Any],
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        guard isEnabled else {
            let error = NSError(
                domain: "io.branch.linksimulator",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "BranchLinkSimulator is not enabled"]
            )
            DispatchQueue.main.async { completion(nil, error) }
            return
        }

        // Create temporary link data
        let linkData = SimulatedLinkData(url: url)
        linkData.params = params

        // Register and simulate
        registerLink(linkData)
        simulateOpen(url: url) { [weak self] session, error in
            self?.unregisterLink(url)
            completion(session, error)
        }
    }

    // MARK: - Scenario Simulation

    /// Simulate a "Double Open" scenario for testing task coalescing.
    ///
    /// This calls `SessionManager.initialize` twice in quick succession,
    /// simulating when `didFinishLaunchingWithOptions` and `continueUserActivity`
    /// both trigger initialization.
    ///
    /// - Parameters:
    ///   - firstURL: URL from first initialization (e.g., Universal Link)
    ///   - secondURL: URL from second initialization (e.g., URI Scheme)
    ///   - completion: Called after both initializations complete with the coalesced session
    @objc public func simulateDoubleOpen(
        firstURL: URL?,
        secondURL: URL,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        guard isEnabled else {
            let error = NSError(
                domain: "io.branch.linksimulator",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "BranchLinkSimulator is not enabled"]
            )
            DispatchQueue.main.async { completion(nil, error) }
            return
        }

        // Reset session to simulate cold start
        SessionManager.shared.reset()

        // First initialization (like didFinishLaunchingWithOptions)
        let firstOptions = InitializationOptions()
        firstOptions.url = firstURL

        // Second initialization (like continueUserActivity) - immediately after
        let secondOptions = InitializationOptions()
        secondOptions.url = secondURL

        // Launch both nearly simultaneously
        SessionManager.shared.initialize(options: firstOptions) { _, _ in
            // First callback - ignore (simulating app delegate not using it)
        }

        // Second call immediately
        SessionManager.shared.initialize(options: secondOptions) { session, error in
            // This should receive the coalesced result
            completion(session, error)
        }
    }

    /// Simulate a warm launch with a deep link.
    ///
    /// - Parameters:
    ///   - url: The deep link URL
    ///   - completion: Callback with session result
    @objc public func simulateWarmLaunch(
        url: URL,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        guard isEnabled else {
            let error = NSError(
                domain: "io.branch.linksimulator",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "BranchLinkSimulator is not enabled"]
            )
            DispatchQueue.main.async { completion(nil, error) }
            return
        }

        // Ensure session is initialized first
        if !SessionManager.shared.isInitialized {
            // Cold start - initialize first
            SessionManager.shared.initialize { [weak self] _, _ in
                // Now handle the deep link
                self?.simulateOpen(url: url, completion: completion)
            }
        } else {
            // Already initialized - just handle the link
            simulateOpen(url: url, completion: completion)
        }
    }
}

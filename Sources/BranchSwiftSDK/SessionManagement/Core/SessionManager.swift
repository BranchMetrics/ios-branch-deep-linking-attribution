//
//  SessionManager.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//
//  iOS 12+ compatible session manager using GCD synchronization patterns.
//  Implements task coalescing to prevent "Double Open" issue (INTENG-21106).
//

import Foundation

#if canImport(BranchSDK)
    import BranchSDK
#endif

// MARK: - SessionManagerDelegate

/// Delegate protocol for SessionManager callbacks.
@objc public protocol SessionManagerDelegate: AnyObject {
    /// Called when session initialization is about to start
    @objc optional func sessionManagerWillStartSession(_ manager: SessionManager, url: URL?)

    /// Called when session initialization succeeds
    @objc func sessionManager(_ manager: SessionManager, didInitializeWith session: Session)

    /// Called when session initialization fails
    @objc func sessionManager(_ manager: SessionManager, didFailWithError error: NSError)
}

// MARK: - SessionManager

/// Session manager with iOS 12 compatibility using GCD synchronization.
///
/// This class implements task coalescing to prevent the "Double Open" issue
/// using traditional GCD patterns instead of Swift Concurrency.
///
/// ## Task Coalescing
///
/// When multiple initialization calls occur concurrently (e.g., from
/// `didFinishLaunchingWithOptions` and `continueUserActivity`), only
/// one network request is made. All callers receive the same result.
///
/// ## Thread Safety
///
/// - State reads use `objc_sync_enter/exit` (same as `@synchronized`)
/// - All mutations happen on the serial `isolationQueue`
/// - Completion handlers are called on the main thread
///
/// ## Usage
///
/// ```swift
/// SessionManager.shared.initialize(options: options) { session, error in
///     if let session = session {
///         print("Session ID: \(session.id)")
///     }
/// }
/// ```
@objc public final class SessionManager: NSObject {
    // MARK: - Singleton

    @objc public static let shared = SessionManager()

    // MARK: - Public Properties

    /// Delegate for session callbacks
    @objc public weak var delegate: SessionManagerDelegate?

    /// Current session state (thread-safe read)
    @objc public var state: SessionState {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return _state
    }

    /// Current session (thread-safe read)
    @objc public var currentSession: Session? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return _currentSession
    }

    /// Whether initialization is in progress
    @objc public var isInitializing: Bool {
        state == .initializing
    }

    /// Whether SDK is fully initialized
    @objc public var isInitialized: Bool {
        state == .initialized
    }

    // MARK: - Private Properties

    /// Serial queue for isolation (like isolationQueue in Branch.m)
    private let isolationQueue = DispatchQueue(
        label: "io.branch.sessionmanager.isolation",
        qos: .userInitiated
    )

    private var _state: SessionState = .uninitialized
    private var _currentSession: Session?

    /// Task coalescing: pending completion handlers
    private var pendingCompletions: [(Session?, NSError?) -> Void] = []

    /// Task coalescing: URL that arrived during initialization
    private var pendingURL: URL?

    /// Track first session status
    private var isFirstSession: Bool = false

    /// Logger instance
    private let logger: Logging = BranchLoggerAdapter.shared

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Public API

    /// Initialize session with task coalescing support.
    ///
    /// Multiple concurrent calls coalesce into a single network request.
    /// URLs from subsequent calls are queued and merged into the final session.
    ///
    /// - Parameters:
    ///   - options: Initialization options
    ///   - completion: Callback with Session or error (called on main thread)
    @objc public func initialize(
        options: InitializationOptions?,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            // TASK COALESCING: Check if initialization is already in progress
            if self._state == .initializing {
                // Store URL for merging (Double Open Fix)
                if let url = options?.url {
                    self.pendingURL = url
                    self.log(.debug, "Coalescing: URL queued: \(url)")
                }

                // Queue completion handler
                self.pendingCompletions.append(completion)
                self.log(.debug, "Coalescing: completion queued (total: \(self.pendingCompletions.count))")
                return
            }

            // Already initialized - if URL provided, handle as deep link
            if self._state == .initialized, let url = options?.url {
                self.log(.debug, "Already initialized, handling URL as deep link: \(url)")
                self.handleDeepLinkInternal(url, completion: completion)
                return
            }

            // Store initial URL
            if let url = options?.url {
                self.pendingURL = url
            }

            // Store first completion handler
            self.pendingCompletions.append(completion)

            // CRITICAL: Mark Legacy SDK as initializing BEFORE any async work
            // This prevents applicationDidBecomeActive from triggering a duplicate /v1/open
            #if canImport(BranchSDK)
                Branch.markInitializationStarting()
            #endif

            // Transition to initializing
            self.transitionTo(.initializing, url: options?.url)

            // Perform actual initialization
            self.performInitialization(options: options)
        }
    }

    /// Handle deep link URL.
    ///
    /// If initialization is in progress, coalesces with pending initialization.
    @objc public func handleDeepLink(
        _ url: URL,
        completion: @escaping (Session?, NSError?) -> Void
    ) {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            // If initializing, coalesce with pending initialization
            if self._state == .initializing {
                self.pendingURL = url
                self.pendingCompletions.append(completion)
                self.log(.debug, "Deep link coalesced with pending initialization")
                return
            }

            // If not initialized, start initialization with URL
            guard self._state == .initialized else {
                self.log(.debug, "Not initialized, starting initialization with URL")
                let options = InitializationOptions()
                options.url = url
                self.pendingURL = url
                self.pendingCompletions.append(completion)
                self.transitionTo(.initializing, url: url)
                self.performInitialization(options: options)
                return
            }

            // Already initialized - resolve link
            self.handleDeepLinkInternal(url, completion: completion)
        }
    }

    /// Reset session to uninitialized state.
    @objc public func reset() {
        isolationQueue.async { [weak self] in
            guard let self = self else { return }

            self.log(.debug, "Resetting session manager")

            objc_sync_enter(self)
            self._currentSession = nil
            self._state = .uninitialized
            objc_sync_exit(self)

            self.pendingURL = nil
            self.pendingCompletions.removeAll()
        }
    }

    // MARK: - Private Methods

    private func performInitialization(options: InitializationOptions?) {
        log(.debug, "Starting initialization...")

        // Determine if first session
        isFirstSession = !hasInstalled()

        #if canImport(BranchSDK)
            // Use existing BNCRequestFactory for building request data
            performNetworkInitialization(options: options)
        #else
            // Standalone build - simulate success for testing
            simulateSuccessfulInitialization()
        #endif
    }

    #if canImport(BranchSDK)
        private func performNetworkInitialization(options _: InitializationOptions?) {
            // Build request using existing infrastructure
            let endpoint = isFirstSession ? "v1/install" : "v1/open"
            log(.debug, "Making \(endpoint) request (firstSession: \(isFirstSession))")

            // Use Branch's existing initialization mechanism
            // This bridges to the legacy network layer while our session manager handles coalescing
            let urlString = pendingURL?.absoluteString

            // Build complete request data using BNCRequestFactory (via Branch public API)
            // This includes all required fields: os, os_version, hardware_id, etc.
            let requestData: [String: Any]
            if isFirstSession {
                requestData = Branch.requestDataForInstall(withURLString: urlString) as? [String: Any] ?? [:]
            } else {
                requestData = Branch.requestDataForOpen(withURLString: urlString) as? [String: Any] ?? [:]
            }

            // Use direct URLSession request (simpler and more reliable than reflection)
            performCallbackBasedRequest(endpoint: endpoint, data: requestData)
        }

        private func performCallbackBasedRequest(endpoint: String, data: [String: Any]) {
            // Use configured API URL from Branch (delegates to BNCServerAPI)
            let serviceURL: String
            if endpoint.contains("install") {
                serviceURL = Branch.installServiceURL()
            } else {
                serviceURL = Branch.openServiceURL()
            }

            log(.debug, "Using service URL: \(serviceURL)")

            guard let fullURL = URL(string: serviceURL) else {
                let error = NSError(
                    domain: "io.branch.sdk",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
                )
                finishInitialization(session: nil, error: error)
                return
            }

            var request = URLRequest(url: fullURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let key = Branch.branchKey() {
                request.setValue(key, forHTTPHeaderField: "Branch-Key")
            }

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data)
            } catch {
                finishInitialization(session: nil, error: error as NSError)
                return
            }

            let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                guard let self = self else { return }

                self.isolationQueue.async {
                    if let error = error {
                        self.finishInitialization(session: nil, error: error as NSError)
                        return
                    }

                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    else {
                        let parseError = NSError(
                            domain: "io.branch.sdk",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]
                        )
                        self.finishInitialization(session: nil, error: parseError)
                        return
                    }

                    self.handleNetworkResponse(json)
                }
            }
            task.resume()
        }

        private func handleNetworkResponse(_ responseData: [String: Any]?) {
            guard let responseData = responseData else {
                let error = NSError(
                    domain: "io.branch.sdk",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Empty response from server"]
                )
                finishInitialization(session: nil, error: error)
                return
            }

            // Check for server error
            if let errorMessage = responseData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String
            {
                let error = NSError(
                    domain: "io.branch.sdk",
                    code: errorMessage["code"] as? Int ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: message]
                )
                finishInitialization(session: nil, error: error)
                return
            }

            // Parse response into BNCInitSessionResponse
            let response = BNCInitSessionResponse()
            var params = responseData

            // Merge pending URL into response
            if let pendingURL = pendingURL {
                params["~referring_link"] = pendingURL.absoluteString
            }

            response.params = params

            // Mark as installed
            if isFirstSession {
                markAsInstalled()
            }

            // Convert to Session (typed Swift API)
            let session = Session(from: response, isFirstSession: isFirstSession)
            log(.debug, "Session created: \(session.id)")

            finishInitialization(session: session, error: nil)
        }
    #endif

    private func simulateSuccessfulInitialization() {
        // For standalone builds without BranchSDK
        let session = Session(
            id: UUID().uuidString,
            createdAt: Date(),
            identityId: UUID().uuidString,
            deviceFingerprintId: UUID().uuidString,
            isFirstSession: isFirstSession,
            userId: nil,
            params: [:]
        )
        finishInitialization(session: session, error: nil)
    }

    private func finishInitialization(session: Session?, error: NSError?) {
        // Update state
        objc_sync_enter(self)
        if let session = session {
            _currentSession = session
            _state = .initialized
        } else {
            _state = .uninitialized
        }
        objc_sync_exit(self)

        // MARK: - Sync session data to BNCPreferenceHelper

        // This enables Legacy SDK features (events, links, QR codes) to work
        // by populating the required session tokens
        #if canImport(BranchSDK)
            if let session = session {
                syncSessionToPreferenceHelper(session)
            }
        #endif

        // Post notification
        let url = pendingURL
        pendingURL = nil

        // Call all pending completion handlers
        let completions = pendingCompletions
        pendingCompletions.removeAll()

        log(.debug, "Finishing initialization - session: \(session != nil), error: \(error?.localizedDescription ?? "none"), completions: \(completions.count)")

        for completion in completions {
            callCompletion(completion, session: session, error: error)
        }

        // Notify delegate and post notification
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let session = session {
                // Delegate callback
                self.delegate?.sessionManager(self, didInitializeWith: session)

                // Post notification
                var userInfo: [String: Any] = [
                    "session": session,
                    "params": session.params,
                ]
                if let url = url {
                    userInfo["BranchURLKey"] = url
                }
                NotificationCenter.default.post(
                    name: Notification.Name("BranchDidStartSessionNotification"),
                    object: self,
                    userInfo: userInfo
                )
            } else if let error = error {
                // Delegate callback
                self.delegate?.sessionManager(self, didFailWithError: error)

                // Post notification
                var userInfo: [String: Any] = ["BranchErrorKey": error]
                if let url = url {
                    userInfo["BranchURLKey"] = url
                }
                NotificationCenter.default.post(
                    name: Notification.Name("BranchDidStartSessionNotification"),
                    object: self,
                    userInfo: userInfo
                )
            }
        }
    }

    private func handleDeepLinkInternal(_ url: URL, completion: @escaping (Session?, NSError?) -> Void) {
        log(.debug, "Handling deep link: \(url)")

        // Check if BranchLinkSimulator should handle this URL
        if BranchLinkSimulator.shared.shouldSimulateLink(url) {
            log(.debug, "URL is registered in BranchLinkSimulator - using simulated response")
            handleSimulatedLink(url, completion: completion)
            return
        }

        #if canImport(BranchSDK)
            // Re-initialize with the new URL to get updated link data
            let options = InitializationOptions()
            options.url = url

            // Transition to re-initializing
            transitionTo(.initializing, url: url)
            pendingURL = url
            pendingCompletions.append(completion)

            performInitialization(options: options)
        #else
            // For standalone builds, return current session with updated URL
            if let session = _currentSession {
                callCompletion(completion, session: session, error: nil)
            } else {
                let error = NSError(
                    domain: "io.branch.sdk",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No session available"]
                )
                callCompletion(completion, session: nil, error: error)
            }
        #endif
    }

    /// Handle a simulated link from BranchLinkSimulator.
    ///
    /// This bypasses network calls and returns a session with simulated params.
    private func handleSimulatedLink(_ url: URL, completion: @escaping (Session?, NSError?) -> Void) {
        guard let linkData = BranchLinkSimulator.shared.getSimulatedLinkData(for: url) else {
            // Link not registered - should not happen if shouldSimulateLink returned true
            let error = NSError(
                domain: "io.branch.sdk.error",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Simulated link data not found"]
            )
            callCompletion(completion, session: nil, error: error)
            return
        }

        // Simulate delay if configured
        let delay = linkData.simulatedDelay

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            self.isolationQueue.async {
                // Build session with simulated params
                let isFirst = self.isFirstSession
                guard let session = BranchLinkSimulator.shared.buildSimulatedSession(for: url, isFirstSession: isFirst) else {
                    let error = NSError(
                        domain: "io.branch.sdk.error",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to build simulated session"]
                    )
                    self.callCompletion(completion, session: nil, error: error)
                    return
                }

                // Update current session
                objc_sync_enter(self)
                self._currentSession = session
                objc_sync_exit(self)

                self.log(.debug, "Simulated session created: \(session.id)")

                // Call completion
                self.callCompletion(completion, session: session, error: nil)

                // Notify delegate and post notification
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    self.delegate?.sessionManager(self, didInitializeWith: session)

                    var userInfo: [String: Any] = [
                        "session": session,
                        "params": session.params,
                        "BranchURLKey": url,
                    ]
                    userInfo["+simulated"] = true

                    NotificationCenter.default.post(
                        name: Notification.Name("BranchDidStartSessionNotification"),
                        object: self,
                        userInfo: userInfo
                    )
                }
            }
        }
    }

    private func transitionTo(_ newState: SessionState, url: URL?) {
        log(.debug, "State transition: \(_state) -> \(newState)")

        objc_sync_enter(self)
        _state = newState
        objc_sync_exit(self)

        // Post will-start notification
        if newState == .initializing {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                self.delegate?.sessionManagerWillStartSession?(self, url: url)

                var userInfo: [String: Any] = [:]
                if let url = url {
                    userInfo["BranchURLKey"] = url
                }
                NotificationCenter.default.post(
                    name: Notification.Name("BranchWillStartSessionNotification"),
                    object: self,
                    userInfo: userInfo
                )
            }
        }
    }

    private func callCompletion(
        _ completion: @escaping (Session?, NSError?) -> Void,
        session: Session?,
        error: NSError?
    ) {
        DispatchQueue.main.async {
            completion(session, error)
        }
    }

    // MARK: - Helper Methods

    private func hasInstalled() -> Bool {
        UserDefaults.standard.bool(forKey: "branch_has_installed")
    }

    private func markAsInstalled() {
        UserDefaults.standard.set(true, forKey: "branch_has_installed")
    }

    #if canImport(BranchSDK)
        /// Sync session data to BNCPreferenceHelper for Legacy SDK compatibility.
        ///
        /// This enables Legacy SDK features (BranchEvent, BranchUniversalObject,
        /// BranchQRCode) to work with the modern SessionManager by populating
        /// the required session tokens in BNCPreferenceHelper.
        ///
        /// The Legacy SDK's BranchRequestOperation.validateSession() requires:
        /// - randomizedDeviceToken (device_fingerprint_id)
        /// - sessionID (session_id)
        /// - randomizedBundleToken (identity_id / randomized_bundle_token)
        private func syncSessionToPreferenceHelper(_ session: Session) {
            guard let preferenceHelper = BNCPreferenceHelper.sharedInstance() else {
                log(.warning, "BNCPreferenceHelper not available - Legacy SDK features may not work")
                return
            }

            // Sync device fingerprint ID -> randomizedDeviceToken
            if !session.deviceFingerprintId.isEmpty {
                preferenceHelper.randomizedDeviceToken = session.deviceFingerprintId
                log(.debug, "Synced randomizedDeviceToken: \(session.deviceFingerprintId.prefix(8))...")
            }

            // Sync session ID -> sessionID
            if !session.id.isEmpty {
                preferenceHelper.sessionID = session.id
                log(.debug, "Synced sessionID: \(session.id.prefix(8))...")
            }

            // Sync identity ID -> randomizedBundleToken
            // The randomizedBundleToken is the identity_id from the server response
            if !session.identityId.isEmpty {
                preferenceHelper.randomizedBundleToken = session.identityId
                log(.debug, "Synced randomizedBundleToken: \(session.identityId.prefix(8))...")
            }

            // Mark Legacy SDK as initialized to prevent initSafetyCheck from
            // triggering another /v1/open request
            Branch.markInitializationComplete()

            log(.debug, "Session data synced to BNCPreferenceHelper for Legacy SDK compatibility")
        }
    #endif

    private func log(_ level: LogLevel, _ message: String) {
        logger.log(level, message, file: #file, function: #function, line: #line)
    }
}

// MARK: - Convenience Extension

public extension SessionManager {
    /// Initialize session with just a URL
    @objc func initialize(url: URL?, completion: @escaping (Session?, NSError?) -> Void) {
        let options = InitializationOptions()
        options.url = url
        initialize(options: options, completion: completion)
    }

    /// Initialize session without options
    @objc func initialize(completion: @escaping (Session?, NSError?) -> Void) {
        initialize(options: nil, completion: completion)
    }
}

// MARK: - Async/Await Extension (iOS 13+)

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension SessionManager {
    /// Initialize session with options using async/await.
    ///
    /// This wraps the completion-based API for modern Swift concurrency.
    ///
    /// - Parameter options: Initialization options
    /// - Returns: The initialized Session
    /// - Throws: NSError if initialization fails
    func initialize(options: InitializationOptions?) async throws -> Session {
        try await withCheckedThrowingContinuation { continuation in
            initialize(options: options) { session, error in
                if let session = session {
                    continuation.resume(returning: session)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let unknownError = NSError(
                        domain: "io.branch.sdk.error",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown initialization error"]
                    )
                    continuation.resume(throwing: unknownError)
                }
            }
        }
    }

    /// Initialize session with a URL using async/await.
    ///
    /// - Parameter url: Optional URL for deep link handling
    /// - Returns: The initialized Session
    /// - Throws: NSError if initialization fails
    func initialize(url: URL?) async throws -> Session {
        let options = InitializationOptions()
        options.url = url
        return try await initialize(options: options)
    }

    /// Initialize session without options using async/await.
    ///
    /// - Returns: The initialized Session
    /// - Throws: NSError if initialization fails
    func initialize() async throws -> Session {
        try await initialize(options: nil)
    }

    /// Handle deep link URL using async/await.
    ///
    /// - Parameter url: The deep link URL to handle
    /// - Returns: The updated Session with deep link data
    /// - Throws: NSError if handling fails
    func handleDeepLink(_ url: URL) async throws -> Session {
        try await withCheckedThrowingContinuation { continuation in
            handleDeepLink(url) { session, error in
                if let session = session {
                    continuation.resume(returning: session)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let unknownError = NSError(
                        domain: "io.branch.sdk.error",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown deep link error"]
                    )
                    continuation.resume(throwing: unknownError)
                }
            }
        }
    }
}

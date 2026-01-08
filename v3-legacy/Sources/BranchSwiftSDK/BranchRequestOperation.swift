//
//  BranchRequestOperation.swift
//  BranchSDK
//
//  Created by Branch SDK Team
//  Modern Swift Concurrency implementation for request processing
//

import Foundation

// Import BranchSDK when building as Swift Package
#if SWIFT_PACKAGE
import BranchSDK
#endif

// When building as part of Xcode project, types are available through module
// No additional import needed - Swift sees Objective-C through the module

/// Modern Swift Concurrency-based operation for processing Branch server requests.
/// This class provides a structured concurrency approach similar to Android's Kotlin Coroutines implementation,
/// replacing manual GCD dispatch queues with async/await patterns.
///
/// Key features:
/// - Structured concurrency with proper cancellation support
/// - Actor-based thread safety
/// - Automatic main thread dispatching for callbacks
/// - Session validation matching Android implementation
/// - Performance optimized with cooperative thread pool
@available(iOS 13.0, tvOS 13.0, *)
@objc(BranchRequestOperation)
public final class BranchRequestOperation: Operation, @unchecked Sendable {

    // MARK: - Properties

    /// The server request to be processed
    private let request: BNCServerRequest

    /// Server interface for network operations
    private let serverInterface: BNCServerInterface

    /// Branch API key
    private let branchKey: String

    /// Preference helper for session data
    private let preferenceHelper: BNCPreferenceHelper

    /// Task handle for async execution
    private var executionTask: Task<Void, Never>?

    // MARK: - Operation State Management

    private var _isExecuting = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }

    public override var isExecuting: Bool { _isExecuting }
    public override var isFinished: Bool { _isFinished }
    public override var isAsynchronous: Bool { true }

    // MARK: - Initialization

    /// Creates a new request operation with modern Swift Concurrency
    /// - Parameters:
    ///   - request: The server request to process
    ///   - serverInterface: Network interface for API calls
    ///   - branchKey: Branch API key
    ///   - preferenceHelper: Helper for accessing session preferences
    @objc(initWithRequest:serverInterface:branchKey:preferenceHelper:)
    public init(
        request: BNCServerRequest,
        serverInterface: BNCServerInterface,
        branchKey: String,
        preferenceHelper: BNCPreferenceHelper
    ) {
        self.request = request
        self.serverInterface = serverInterface
        self.branchKey = branchKey
        self.preferenceHelper = preferenceHelper
        super.init()
    }

    // MARK: - Operation Lifecycle

    public override func start() {
        guard !isCancelled else {
            BranchLogger.shared().logDebug(
                "Operation cancelled before starting: \(request.requestUUID ?? "unknown")",
                error: nil
            )
            finish()
            return
        }

        _isExecuting = true

        BranchLogger.shared().logVerbose(
            "BranchRequestOperation starting for request: \(request.requestUUID ?? "unknown")",
            error: nil
        )

        // Launch async task with structured concurrency
        executionTask = Task { [weak self] in
            await self?.executeRequest()
        }
    }

    public override func cancel() {
        executionTask?.cancel()
        super.cancel()

        if !isExecuting {
            BranchLogger.shared().logWarning(
                "BranchRequestOperation cancelled before execution for request: \(request.requestUUID ?? "unknown")",
                error: nil
            )
        } else {
            BranchLogger.shared().logWarning(
                "BranchRequestOperation cancelled during execution for request: \(request.requestUUID ?? "unknown")",
                error: nil
            )
        }
    }

    // MARK: - Request Execution (Swift Concurrency)

    /// Executes the request using modern async/await patterns
    /// Similar to Android's suspend fun executeRequest()
    private func executeRequest() async {
        // Early return if cancelled
        guard !Task.isCancelled else {
            finish()
            return
        }

        // Check if tracking is disabled
        guard !Branch.trackingDisabled() else {
            BranchLogger.shared().logDebug(
                "Tracking disabled. Skipping request: \(request.requestUUID ?? "unknown")",
                error: nil
            )
            finish()
            return
        }

        // Validate session (similar to Android session checks)
        guard validateSession() else {
            // BNCInitError code from NSError+Branch.h
            await processError(1001, message: "Session validation failed")
            finish()
            return
        }

        // Execute network request with continuation-based callback bridge
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            request.make(
                serverInterface,
                key: branchKey
            ) { [weak self] response, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                // Handle response on main thread (equivalent to Android's Dispatchers.Main)
                Task { @MainActor in
                    await self.handleResponse(response, error: error)
                    continuation.resume()
                }
            }
        }

        BranchLogger.shared().logVerbose(
            "BranchRequestOperation finished for request: \(request.requestUUID ?? "unknown")",
            error: nil
        )

        finish()
    }

    // MARK: - Session Validation

    /// Validates session requirements based on request type
    /// Matches Android's session validation logic in BranchRequestQueue.kt
    /// - Returns: true if session is valid for this request type
    private func validateSession() -> Bool {
        let requestClassName = String(describing: type(of: request))
        let requestUUID = request.requestUUID ?? "unknown"

        // Install requests only need bundle token
        if requestClassName.contains("BranchInstallRequest") {
            guard preferenceHelper.randomizedBundleToken != nil else {
                BranchLogger.shared().logError(
                    "User session not initialized (missing bundle token). Dropping request: \(requestUUID)",
                    error: nil
                )
                return false
            }
            return true
        }

        // Open requests need bundle token
        if requestClassName.contains("BranchOpenRequest") {
            guard preferenceHelper.randomizedBundleToken != nil else {
                BranchLogger.shared().logError(
                    "User session not initialized (missing bundle token). Dropping request: \(requestUUID)",
                    error: nil
                )
                return false
            }
            return true
        }

        // All other requests need full session (device token, session ID, bundle token)
        guard preferenceHelper.randomizedDeviceToken != nil,
              preferenceHelper.sessionID != nil,
              preferenceHelper.randomizedBundleToken != nil else {
            BranchLogger.shared().logError(
                "Missing session items (device token or session ID or bundle token). Dropping request: \(requestUUID)",
                error: nil
            )
            return false
        }

        return true
    }

    // MARK: - Response Handling

    /// Handles the server response on main thread
    /// Equivalent to Android's withContext(Dispatchers.Main) { handleResponse() }
    /// - Parameters:
    ///   - response: Server response (if successful)
    ///   - error: Error (if failed)
    @MainActor
    private func handleResponse(_ response: BNCServerResponse?, error: Error?) async {
        // Process response on main thread
        request.processResponse(response, error: error)

        // Handle event-specific callbacks
        // Check if request is BranchEventRequest by class name (Objective-C class)
        let requestClassName = String(describing: type(of: request))
        if requestClassName.contains("BranchEventRequest") {
            // Use dynamic method invocation for Objective-C callback
            let callbackMap = NSClassFromString("BNCCallbackMap")
            let sharedSelector = NSSelectorFromString("shared")
            if let callbackMapClass = callbackMap as? NSObject.Type,
               callbackMapClass.responds(to: sharedSelector),
               let shared = callbackMapClass.perform(sharedSelector)?.takeUnretainedValue() {
                let callSelector = NSSelectorFromString("callCompletionForRequest:withSuccessStatus:error:")
                if shared.responds(to: callSelector) {
                    // Perform with proper selector invocation
                    typealias CallCompletionFunc = @convention(c) (AnyObject, Selector, AnyObject, Bool, Error?) -> Void
                    let implementation = shared.method(for: callSelector)
                    let callCompletion = unsafeBitCast(implementation, to: CallCompletionFunc.self)
                    callCompletion(shared, callSelector, request as AnyObject, error == nil, error)

                }
            }
        }
    }

    /// Processes error and calls request failure handler on main thread
    /// - Parameters:
    ///   - errorCode: Branch error code (Int value)
    ///   - message: Error message
    @MainActor
    private func processError(_ errorCode: Int, message: String) async {
        // Create NSError with BNCInitError code
        let error = NSError(
            domain: "io.branch.sdk.error",
            code: errorCode,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        BranchLogger.shared().logError(message, error: error)
        request.processResponse(nil, error: error)
    }

    // MARK: - State Management

    /// Marks the operation as finished
    /// Triggers KVO notifications for operation queue management
    private func finish() {
        _isExecuting = false
        _isFinished = true
    }
}

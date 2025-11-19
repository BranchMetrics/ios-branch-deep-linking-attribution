//
//  BranchRequestQueue.swift
//  BranchSDK
//
//  Created by Branch SDK Team
//  Modern Actor-based request queue with Swift Concurrency
//

import Foundation

// Import BranchSDK when building as Swift Package
#if SWIFT_PACKAGE
import BranchSDK
#endif

// When building as part of Xcode project, types are available through module
// No additional import needed - Swift sees Objective-C through the module

/// Modern actor-based request queue using Swift Concurrency patterns.
/// This implementation replaces manual NSOperationQueue management with structured concurrency,
/// similar to Android's Kotlin Coroutines BranchRequestQueue.kt implementation.
///
/// Key features:
/// - Actor isolation for thread-safe queue management
/// - Serial request processing with structured concurrency
/// - Automatic request prioritization
/// - Session-aware request handling
/// - Modern async/await API
///
/// Architecture parallels:
/// - Android: CoroutineScope + Channel -> iOS: Actor + AsyncStream
/// - Android: Dispatchers.IO -> iOS: Task.detached
/// - Android: Dispatchers.Main -> iOS: MainActor
@available(iOS 13.0, tvOS 13.0, *)
public actor BranchRequestQueue {

    // MARK: - Properties

    /// Operation queue for managing request operations
    /// Serial execution (maxConcurrentOperationCount = 1) ensures proper request ordering
    private let operationQueue: OperationQueue

    /// Server interface for network operations
    private var serverInterface: BNCServerInterface?

    /// Branch API key
    private var branchKey: String?

    /// Preference helper for session management
    private var preferenceHelper: BNCPreferenceHelper?

    /// Processing channel for triggering queue processing
    /// Similar to Android's Channel<Unit> for processing triggers
    private let (processingStream, processingContinuation) = AsyncStream<Void>.makeStream()

    /// Queue state tracking
    private var isProcessing = false

    /// Singleton instance
    private static let _shared = BranchRequestQueue()

    // MARK: - Singleton Access

    /// Returns the shared instance of BranchRequestQueue
    /// Thread-safe singleton pattern using actor isolation
    public static func shared() -> BranchRequestQueue {
        return _shared
    }

    // MARK: - Initialization

    private init() {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1 // Serial execution
        operationQueue.name = "com.branch.sdk.requestQueue.modern"
        operationQueue.qualityOfService = .userInitiated

        BranchLogger.shared().logDebug("BranchRequestQueue (Swift Actor) initialized", error: nil)
    }

    // MARK: - Configuration

    /// Configures the queue with required dependencies
    /// - Parameters:
    ///   - serverInterface: Network interface for API calls
    ///   - branchKey: Branch API key
    ///   - preferenceHelper: Helper for session preferences
    public func configure(
        serverInterface: BNCServerInterface,
        branchKey: String,
        preferenceHelper: BNCPreferenceHelper
    ) {
        self.serverInterface = serverInterface
        self.branchKey = branchKey
        self.preferenceHelper = preferenceHelper

        BranchLogger.shared().logDebug(
            "BranchRequestQueue configured with key: \(branchKey.prefix(8))...",
            error: nil
        )
    }

    // MARK: - Queue Operations

    /// Enqueues a request with default priority
    /// - Parameter request: The server request to enqueue
    public func enqueue(_ request: BNCServerRequest) async {
        await enqueue(request, priority: .normal)
    }

    /// Enqueues a request with specified priority
    /// Similar to Android's enqueue() with priority handling
    /// - Parameters:
    ///   - request: The server request to enqueue
    ///   - priority: Operation queue priority
    public func enqueue(_ request: BNCServerRequest, priority: Operation.QueuePriority) async {
        guard let serverInterface = serverInterface,
              let branchKey = branchKey,
              let preferenceHelper = preferenceHelper else {
            BranchLogger.shared().logError(
                "BranchRequestQueue not configured. Call configure() first.",
                error: nil
            )
            return
        }

        guard let requestUUID = request.requestUUID else {
            BranchLogger.shared().logError("Request missing UUID. Cannot enqueue.", error: nil)
            return
        }

        // Create modern Swift operation
        let operation = BranchRequestOperation(
            request: request,
            serverInterface: serverInterface,
            branchKey: branchKey,
            preferenceHelper: preferenceHelper
        )
        operation.queuePriority = priority

        // Add to operation queue
        operationQueue.addOperation(operation)

        BranchLogger.shared().logVerbose(
            "Enqueued request: \(requestUUID). Current queue depth: \(queueDepth)",
            error: nil
        )

        // Trigger processing
        processingContinuation.yield()
    }

    /// Returns current queue depth
    /// Equivalent to Android's queueDepth property
    public var queueDepth: Int {
        return operationQueue.operationCount
    }

    /// Clears all pending operations from the queue
    /// Similar to Android's clearQueue()
    public func clearQueue() {
        BranchLogger.shared().logDebug(
            "Clearing all pending operations from queue. Current depth: \(queueDepth)",
            error: nil
        )
        operationQueue.cancelAllOperations()
    }

    // MARK: - Queue Inspection

    /// Checks if queue contains install or open request
    /// - Returns: true if install or open request is present
    public func containsInstallOrOpen() -> Bool {
        for operation in operationQueue.operations {
            if let requestOp = operation as? BranchRequestOperation,
               let mirror = Mirror(reflecting: requestOp).descendant("request"),
               let request = mirror as? BNCServerRequest {
                let requestClassName = String(describing: type(of: request))
                if requestClassName.contains("BranchOpenRequest") ||
                   requestClassName.contains("BranchInstallRequest") {
                    return true
                }
            }
        }
        return false
    }

    /// Finds existing install or open request in queue
    /// - Returns: The open request if found, nil otherwise (as AnyObject)
    public func findExistingInstallOrOpen() -> AnyObject? {
        for operation in operationQueue.operations {
            if let requestOp = operation as? BranchRequestOperation,
               let mirror = Mirror(reflecting: requestOp).descendant("request"),
               let request = mirror as? BNCServerRequest {
                let requestClassName = String(describing: type(of: request))
                if requestClassName.contains("BranchOpenRequest") ||
                   requestClassName.contains("BranchInstallRequest") {
                    return request
                }
            }
        }
        return nil
    }

    // MARK: - Queue State Description

    /// Returns detailed description of queue state
    /// Useful for debugging and logging
    public var description: String {
        let operations = operationQueue.operations
        let operationDescriptions = operations.compactMap { operation -> String? in
            if let requestOp = operation as? BranchRequestOperation,
               let mirror = Mirror(reflecting: requestOp).descendant("request"),
               let request = mirror as? BNCServerRequest,
               let uuid = request.requestUUID {
                if operation.isFinished || operation.isCancelled {
                    return "(Completed/Cancelled: \(uuid))"
                } else {
                    return uuid
                }
            }
            return nil
        }

        return """
        <BranchRequestQueue (Swift Actor)>
        Queue Depth: \(queueDepth)
        Operations: [\(operationDescriptions.joined(separator: ", "))]
        """
    }
}

// MARK: - Objective-C Bridge

/// Objective-C compatible wrapper for BranchRequestQueue
/// Provides seamless interop with existing Objective-C code
@available(iOS 13.0, tvOS 13.0, *)
@objc(BranchRequestQueueModern)
public class BranchRequestQueueBridge: NSObject {

    private let queue: BranchRequestQueue

    @objc public static let shared = BranchRequestQueueBridge()

    private override init() {
        queue = BranchRequestQueue.shared()
        super.init()
    }

    /// Configures the queue (Objective-C compatible)
    @objc public func configure(
        serverInterface: BNCServerInterface,
        branchKey: String,
        preferenceHelper: BNCPreferenceHelper
    ) {
        Task {
            await queue.configure(
                serverInterface: serverInterface,
                branchKey: branchKey,
                preferenceHelper: preferenceHelper
            )
        }
    }

    /// Enqueues a request with default priority (Objective-C compatible)
    @objc public func enqueue(_ request: BNCServerRequest) {
        Task {
            await queue.enqueue(request)
        }
    }

    /// Enqueues a request with priority (Objective-C compatible)
    @objc public func enqueue(_ request: BNCServerRequest, priority: Operation.QueuePriority) {
        Task {
            await queue.enqueue(request, priority: priority)
        }
    }

    /// Enqueues with completion callback (Objective-C compatible)
    @objc public func enqueue(_ request: BNCServerRequest, completion: @escaping (Error?) -> Void) {
        Task {
            await queue.enqueue(request)
            await MainActor.run {
                completion(nil)
            }
        }
    }

    /// Current queue depth (Objective-C compatible)
    @objc public var queueDepth: Int {
        var depth = 0
        Task {
            depth = await queue.queueDepth
        }
        return depth
    }

    /// Clears queue (Objective-C compatible)
    @objc public func clearQueue() {
        Task {
            await queue.clearQueue()
        }
    }

    /// Checks for install/open request (Objective-C compatible)
    @objc public func containsInstallOrOpen() -> Bool {
        var contains = false
        Task {
            contains = await queue.containsInstallOrOpen()
        }
        return contains
    }

    /// Finds install/open request (Objective-C compatible)
    @objc public func findExistingInstallOrOpen() -> AnyObject? {
        var openRequest: AnyObject?
        Task {
            openRequest = await queue.findExistingInstallOrOpen()
        }
        return openRequest
    }
}

//
//  BNCServerRequestQueue.swift
//  BranchSDK
//
//  Created by Nidhi Dixit on 7/18/25.
//

import Foundation

#if SWIFT_PACKAGE
import BranchObjCSDK
#endif


// Bridge the Objective-C BNCServerRequest to the Swift async/await world.
// This extension adds a new, await-able `makeRequest` method to BNCServerRequest.
extension BNCServerRequest {
    
    // The new async function that wraps the original Objective-C method with a completion handler.
    func makeRequest(_ serverInterface: BNCServerInterface, key: String) async throws -> BNCServerResponse? {
        // `withCheckedThrowingContinuation` is the core of the bridge.
        // It suspends the async function and provides a `continuation` object.
        return try await withCheckedThrowingContinuation { continuation in
            
            // Call the original Objective-C `make` method.
            // We provide a completion handler to be executed when the network request is done.
            self.make(serverInterface, key: key) { response, error in
                
                // When the completion handler is called, we resume the suspended async function.
                if let error = error {
                    // If there was an error, we resume by throwing the error.
                    continuation.resume(throwing: error)
                } else {
                    // If it was successful, we resume by returning the response.
                    continuation.resume(returning: response)
                }
            }
        }
    }
}



// MARK: - The Private `actor` (Core Logic)

/// This is the private, thread-safe core of the request queue.
/// Its methods are async and isolated, ensuring safe concurrent access.
actor BNCServerRequestQueuePrivate {
    
    // The singleton is only accessible internally within the wrapper.
    fileprivate static let shared = BNCServerRequestQueuePrivate()
    
    let serverInterface = BNCServerInterface()
    let key = "TODO" // To be set externally
    
    private var queue: [BNCServerRequest] = []
    private var continuation: AsyncStream<BNCServerRequest>.Continuation?
    
    private lazy var requestStream: AsyncStream<BNCServerRequest> = {
        return AsyncStream { cont in
            self.continuation = cont
        }
    }()
    
    // The main processing loop, which runs on the actor's context.
    private func processQueue() async {
        // ... (This method remains as you provided) ...
        for await _ in requestStream {
            while let nextRequest = queue.first {
                queue.removeFirst()
                guard Branch.trackingDisabled() == false else {
                    BranchLogger.shared().logVerbose("Tracking is disabled. Skipping request.", error: nil)
                    continue
                }
                
                // This is where you would call the actual network logic.
                do {
                    BranchLogger.shared().logVerbose("Executing network request.", error: nil)
                     let response = try await nextRequest.makeRequest(self.serverInterface, key: self.key)
                     nextRequest.processResponse(response, error: nil)
                } catch {
                    BranchLogger.shared().logError("Request failed: \(error.localizedDescription)", error: error)
                    // nextRequest.processResponse(nil, error: error)
                }
            }
        }
    }
    
    // The async method for enqueuing a request.
    func enqueue(_ request: BNCServerRequest) {
        self.queue.append(request)
        BranchLogger.shared().logVerbose("Standard request added to end.", error: nil)
        self.continuation?.yield(request)
    }
    
    // A method to get the queue depth.
    var queueDepth: Int {
        return self.queue.count
    }
}

// MARK: - The Public Wrapper Class

/// This public class serves as the bridge between Objective-C and the private actor.
/// It is marked `@objcMembers` to be fully accessible to Objective-C.
@objcMembers
public class BNCServerRequestQueue: NSObject {
    
    // The shared instance of the public wrapper class.
    public static let shared = BNCServerRequestQueue()
    
    // A private reference to the internal actor instance.
    private let privateQueue = BNCServerRequestQueuePrivate.shared
    
    // MARK: - Public API (Exposed to Objective-C)
    
    /// Enqueues a request from Objective-C.
    /// This method is non-isolated and non-async.
    public func enqueue(_ request: BNCServerRequest) {
        // The "fire-and-forget" pattern: start a Task to call the async actor method.
        Task {
            await self.privateQueue.enqueue(request)
        }
    }
    
    /// Returns the current number of requests in the queue.
    /// This method must block to get a value from the async actor.
    public var queueDepth: Int {
        var depth = 0
        // A temporary semaphore to block the thread until we get a result from the actor.
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            depth = await self.privateQueue.queueDepth
            semaphore.signal()
        }
        
        semaphore.wait()
        return depth
    }
}





/*


actor BNCServerRequestQueuePrivate {
    
    // MARK: - Singleton (Replaces getInstance)
    
    static let shared = BNCServerRequestQueue()
    let serverInterface = BNCServerInterface()
    let key = "" // TODO
    
    // Private initializer to enforce singleton pattern
    private init() {
        // Start the continuous processing task when the queue is initialized
        Task { await self.processQueue() }
    }
    
    // MARK: - Internal State and `AsyncStream`
    
    // The internal queue where requests are temporarily stored.
    private var queue: [BNCServerRequest] = []
    
    // The continuation allows us to "yield" requests to the stream.
    private var continuation: AsyncStream<BNCServerRequest>.Continuation?
    
    // The stream itself, which the `for await` loop will consume.
    private lazy var requestStream: AsyncStream<BNCServerRequest> = {
        return AsyncStream { cont in
            self.continuation = cont
        }
    }()
    
    // MARK: - Public API (Replaces Objective-C methods)
    
    /// Enqueues a request with prioritization logic.
    /// This is the producer part of the pattern.
    func enqueue(_ request: BNCServerRequest) {
        // Perform synchronization checks and prioritization logic on the internal queue
      /*  if request is BranchInstallRequest || request is BranchOpenRequest {
            // Check if a similar high-priority request is already pending
            let hasPendingInstallOrOpen = self.queue.contains {
                $0 is BranchInstallRequest || $0 is BranchOpenRequest
            }
            if !hasPendingInstallOrOpen {
                self.queue.insert(request, at: 0)
                BranchLogger.shared.logVerbose("Prioritized request added to front.", error: nil)
            } else {
                self.queue.append(request)
                BranchLogger.shared.logVerbose("High priority request added to end due to existing pending high priority request.", error: nil)
            }
        } else { */
            // All other requests are added to the end of the queue
            self.queue.append(request)
        BranchLogger.shared().logVerbose("Standard request added to end.", error: nil)
       // }
        
        // Signal the consumer that a new request is available.
        // We will `yield` a dummy item to trigger the loop.
        // The loop will then read from the internal `queue` array.
        continuation?.yield(request)
    }
    
    @objc(branchEnqueueRequest:)
        nonisolated func enqueueFromObjectiveC(_ request: BNCServerRequest) {
            // Create a new Task to run the async `enqueue` method.
            // This is a "fire-and-forget" pattern from the perspective of the caller.
            Task {
                await self.enqueue(request)
            }
        }
    
    /// Removes a specific request from the queue.
    func remove(_ request: BNCServerRequest) {
        self.queue.removeAll(where: { $0 === request })
    }
    
    /// Returns the number of requests in the queue.
    var queueDepth: Int {
        return self.queue.count
    }
    
    // MARK: - Internal Processing (Replaces processNextQueueItem)
    
    /// The continuous consumer loop. It processes requests one-by-one.
    private func processQueue() async {
        // The `for await` loop suspends and resumes automatically as new requests are added.
        for await _ in requestStream {
            while let nextRequest = queue.first {
                // Remove the request from the internal queue before processing it.
                queue.removeFirst()
                
                // Apply business logic checks from the original Objective-C code.
                guard Branch.trackingDisabled() == false else {
                    BranchLogger.shared().logVerbose("Tracking is disabled. Skipping request.", error: nil)
                    continue // Skip to next item
                }
                
                // Perform the session checks from the original code
              /*  if nextRequest is BranchInstallRequest {
                    // No session check needed
                } else if BNCPreferenceHelper.shared.randomizedBundleToken == nil {
                     BranchLogger.shared.logError("User session has not been initialized!", error: nil)
                     nextRequest.processResponse(nil, error: nil)
                     continue
                } else if BNCPreferenceHelper.shared.randomizedDeviceToken == nil || BNCPreferenceHelper.shared.sessionID == nil {
                     BranchLogger.shared.logError("Missing session items!", error: nil)
                     nextRequest.processResponse(nil, error: nil)
                     continue
                }
                */
                // Execute the network request. The `await` here ensures that
                // the loop will not process the next request until this one is complete.
                do {
                    BranchLogger.shared().logVerbose("Executing network request.", error: nil)
                                        let response = try await nextRequest.makeRequest(self.serverInterface, key: self.key)
                    nextRequest.processResponse(response, error: nil)
                } catch {
                    BranchLogger.shared().logError("Request failed: \(error.localizedDescription)", error: error)
                    nextRequest.processResponse(nil, error: error)
                }
            }
        }
    }
}
*/

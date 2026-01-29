//
//  BranchObservableState.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Combine
import Foundation

// MARK: - BranchObservableState

/// Observable wrapper for Branch session state that integrates with SwiftUI and Combine.
///
/// This class bridges the async `SessionManager` state to Combine's `@Published` properties,
/// allowing SwiftUI views to automatically react to session state changes without manual observation.
///
/// ## Minimum Requirements
///
/// - iOS 13.0+
/// - macOS 10.15+
/// - tvOS 13.0+
/// - watchOS 6.0+
///
/// ## Usage in SwiftUI
///
/// ```swift
/// struct ContentView: View {
///     @ObservedObject var branchState = BranchSessionCoordinator.shared.observableState
///
///     var body: some View {
///         VStack {
///             Text("Status: \(branchState.stateDescription)")
///
///             if branchState.isInitialized, let session = branchState.currentSession {
///                 Text("Session ID: \(session.id)")
///             }
///
///             if let error = branchState.lastError {
///                 Text("Error: \(error.localizedDescription)")
///                     .foregroundColor(.red)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Usage in UIKit
///
/// ```swift
/// class ViewController: UIViewController {
///     private var cancellables = Set<AnyCancellable>()
///
///     override func viewDidLoad() {
///         super.viewDidLoad()
///
///         BranchSessionCoordinator.shared.observableState.$sessionState
///             .receive(on: DispatchQueue.main)
///             .sink { [weak self] state in
///                 self?.updateUI(for: state)
///             }
///             .store(in: &cancellables)
///     }
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class BranchObservableState: ObservableObject {
    // MARK: Lifecycle

    /// Creates a new observable state wrapper for the given session manager.
    ///
    /// - Parameter sessionManager: The session manager to observe
    public init(sessionManager: SessionManaging) {
        self.sessionManager = sessionManager
        startObserving()
    }

    // MARK: Public

    // MARK: - Published Properties

    /// The current session state.
    ///
    /// Automatically updated when the session manager state changes.
    @Published public private(set) var sessionState: SessionState = .uninitialized

    /// The current session, if initialized.
    ///
    /// Convenience property that extracts the session from `sessionState`.
    @Published public private(set) var currentSession: Session?

    /// The last error that occurred, if any.
    ///
    /// Cleared when a new initialization succeeds.
    @Published public private(set) var lastError: Error?

    // MARK: - Computed Properties

    /// Whether the SDK is ready for operations.
    public var isInitialized: Bool {
        sessionState.isReady
    }

    /// Whether the SDK is currently initializing.
    public var isInitializing: Bool {
        sessionState.isInitializing
    }

    /// Whether the SDK needs initialization.
    public var needsInitialization: Bool {
        sessionState.needsInitialization
    }

    /// Human-readable description of the current state.
    ///
    /// Uses `SessionState.description` directly from the SDK.
    public var stateDescription: String {
        sessionState.description
    }

    // MARK: - Methods

    /// Manually refresh the state from the session manager.
    ///
    /// Normally not needed as state is automatically observed,
    /// but can be useful after error recovery.
    public func refresh() {
        Task {
            let state = await sessionManager.state
            await updateState(state)
        }
    }

    /// Clear the last error.
    ///
    /// Call this after displaying an error to the user.
    @MainActor
    public func clearError() {
        lastError = nil
    }

    // MARK: Internal

    /// Report an error from external initialization attempts.
    ///
    /// - Parameter error: The error that occurred
    @MainActor
    func reportError(_ error: Error) {
        lastError = error
    }

    // MARK: Private

    private let sessionManager: SessionManaging
    private var observationTask: Task<Void, Never>?

    private func startObserving() {
        observationTask = Task { [weak self] in
            guard let self else { return }

            for await state in sessionManager.observeState() {
                guard !Task.isCancelled else { break }
                await updateState(state)
            }
        }
    }

    @MainActor
    private func updateState(_ state: SessionState) {
        sessionState = state
        currentSession = state.session

        // Clear error on successful initialization
        if state.isReady {
            lastError = nil
        }
    }

    deinit {
        observationTask?.cancel()
    }
}

// MARK: - Convenience Extensions

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension BranchObservableState {
    /// Whether a deep link was clicked.
    ///
    /// Returns `true` if there's link data in the current session.
    var hasDeepLink: Bool {
        currentSession?.linkData != nil
    }

    /// The deep link URL, if any.
    var deepLinkURL: URL? {
        currentSession?.linkData?.url
    }

    /// The deep link parameters, if any.
    var deepLinkParameters: [String: AnyCodable]? {
        currentSession?.linkData?.parameters
    }
}

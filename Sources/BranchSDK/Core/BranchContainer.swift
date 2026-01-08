//
//  BranchContainer.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Dependency injection container for the Branch SDK.
///
/// This actor manages all SDK dependencies and ensures thread-safe access.
/// It enables full testability by allowing dependencies to be swapped.
///
/// ## Architecture
///
/// The container follows the service locator pattern with lazy initialization:
/// - Dependencies are created on first access
/// - Configuration can be changed before initialization
/// - Test implementations can be injected
public actor BranchContainer {
    // MARK: Lifecycle

    // MARK: - Initialization

    private init() {}

    /// Create a container for testing with custom dependencies
    public init(
        sessionManager: (any SessionManaging)? = nil,
        networkClient: (any NetworkClient)? = nil,
        storageProvider: (any StorageProvider)? = nil,
        eventTracker: (any EventTracking)? = nil,
        linkGenerator: (any LinkGenerating)? = nil,
        logger: (any Logging)? = nil
    ) {
        _sessionManager = sessionManager
        _networkClient = networkClient
        _storageProvider = storageProvider
        _eventTracker = eventTracker
        _linkGenerator = linkGenerator
        if let logger {
            _logger = logger
        }
    }

    // MARK: Public

    // MARK: - Singleton

    /// Shared container instance
    public static let shared = BranchContainer()

    /// Whether the container has been configured
    public var isConfigured: Bool {
        configuration != nil
    }

    // MARK: - Accessors

    /// The session manager
    public var sessionManager: any SessionManaging {
        if _sessionManager == nil {
            _sessionManager = SessionManager(container: self)
        }
        return _sessionManager!
    }

    /// The network client
    public var networkClient: any NetworkClient {
        if _networkClient == nil {
            _networkClient = URLSessionNetworkClient(configuration: configuration)
        }
        return _networkClient!
    }

    /// The storage provider
    public var storageProvider: any StorageProvider {
        if _storageProvider == nil {
            _storageProvider = UserDefaultsStorageProvider()
        }
        return _storageProvider!
    }

    /// The event tracker
    public var eventTracker: any EventTracking {
        if _eventTracker == nil {
            _eventTracker = EventTracker(container: self)
        }
        return _eventTracker!
    }

    /// The link generator
    public var linkGenerator: any LinkGenerating {
        if _linkGenerator == nil {
            _linkGenerator = LinkGenerator(container: self)
        }
        return _linkGenerator!
    }

    /// The logger
    public nonisolated var logger: any Logging {
        get {
            BranchLogger.shared
        }
        set {
            // Logger is a special case - it's global
            BranchLogger.shared.minimumLevel = newValue.minimumLevel
        }
    }

    /// The integration validator
    public var integrationValidator: IntegrationValidator {
        if _integrationValidator == nil {
            _integrationValidator = IntegrationValidator(container: self)
        }
        return _integrationValidator!
    }

    /// The current configuration
    public var currentConfiguration: BranchConfiguration? {
        configuration
    }

    // MARK: - Configuration

    /// Configure the container with SDK settings
    public func configure(with configuration: BranchConfiguration) {
        self.configuration = configuration

        // Reset lazy instances so they pick up new configuration
        _networkClient = nil
    }

    /// Reset the container to initial state
    public func reset() {
        configuration = nil
        _sessionManager = nil
        _networkClient = nil
        _storageProvider = nil
        _eventTracker = nil
        _linkGenerator = nil
        _integrationValidator = nil
    }

    // MARK: - Dependency Injection for Testing

    /// Inject a custom session manager
    public func inject(sessionManager: any SessionManaging) {
        _sessionManager = sessionManager
    }

    /// Inject a custom network client
    public func inject(networkClient: any NetworkClient) {
        _networkClient = networkClient
    }

    /// Inject a custom storage provider
    public func inject(storageProvider: any StorageProvider) {
        _storageProvider = storageProvider
    }

    /// Inject a custom event tracker
    public func inject(eventTracker: any EventTracking) {
        _eventTracker = eventTracker
    }

    /// Inject a custom link generator
    public func inject(linkGenerator: any LinkGenerating) {
        _linkGenerator = linkGenerator
    }

    // MARK: Private

    // MARK: - Configuration

    /// Current SDK configuration
    private var configuration: BranchConfiguration?

    // MARK: - Dependencies

    /// Session manager instance
    private var _sessionManager: (any SessionManaging)?

    /// Network client instance
    private var _networkClient: (any NetworkClient)?

    /// Storage provider instance
    private var _storageProvider: (any StorageProvider)?

    /// Event tracker instance
    private var _eventTracker: (any EventTracking)?

    /// Link generator instance
    private var _linkGenerator: (any LinkGenerating)?

    /// Logger instance
    private var _logger: (any Logging)?

    /// Integration validator instance
    private var _integrationValidator: IntegrationValidator?
}

//
//  MockLinkGenerator.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock link generator for testing.
///
/// Records all link creation requests and returns configurable URLs.
public actor MockLinkGenerator: LinkGenerating {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    /// URL to return for link creation
    public var mockURL: URL = .init(string: "https://example.app.link/mock")!

    /// Whether link creation should fail
    public var shouldFailLinkCreation = false

    /// Error to throw when link creation fails
    public var linkCreationError: Error?

    /// Map of aliases to URLs for testing specific aliases
    public var aliasMapping: [String: URL] = [:]

    // MARK: - Public Access

    /// All link requests that have been made
    public var linkRequests: [LinkProperties] {
        _linkRequests
    }

    /// All links that have been generated
    public var generatedLinks: [URL] {
        _generatedLinks
    }

    // MARK: - Test Helpers

    /// Get the last link request
    public var lastRequest: LinkProperties? {
        _linkRequests.last
    }

    // MARK: - LinkGenerating

    public func create(with properties: LinkProperties) async throws -> URL {
        _linkRequests.append(properties)

        if shouldFailLinkCreation {
            throw linkCreationError ?? BranchError.linkCreationFailed("Mock link creation failure")
        }

        // Check for alias mapping
        if let alias = properties.alias, let mappedURL = aliasMapping[alias] {
            _generatedLinks.append(mappedURL)
            return mappedURL
        }

        // Generate a URL with properties encoded
        let generatedURL = buildMockURL(for: properties)
        _generatedLinks.append(generatedURL)
        return generatedURL
    }

    public nonisolated func createLongURL(with properties: LinkProperties) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "example.app.link"
        components.path = "/a/\(properties.alias ?? "mock")"

        var queryItems: [URLQueryItem] = []
        if let channel = properties.channel {
            queryItems.append(URLQueryItem(name: "channel", value: channel))
        }
        if let feature = properties.feature {
            queryItems.append(URLQueryItem(name: "feature", value: feature))
        }
        if let campaign = properties.campaign {
            queryItems.append(URLQueryItem(name: "campaign", value: campaign))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }

    /// Clear all recorded requests
    public func clearRequests() {
        _linkRequests.removeAll()
        _generatedLinks.removeAll()
    }

    /// Reset all state
    public func reset() {
        _linkRequests.removeAll()
        _generatedLinks.removeAll()
        mockURL = URL(string: "https://example.app.link/mock")!
        shouldFailLinkCreation = false
        linkCreationError = nil
        aliasMapping.removeAll()
    }

    /// Set the mock URL to return
    public func setMockURL(_ url: URL) {
        mockURL = url
    }

    /// Add an alias mapping
    public func addAliasMapping(_ alias: String, to url: URL) {
        aliasMapping[alias] = url
    }

    // MARK: Private

    private var _linkRequests: [LinkProperties] = []
    private var _generatedLinks: [URL] = []

    private func buildMockURL(for properties: LinkProperties) -> URL {
        var components = URLComponents(url: mockURL, resolvingAgainstBaseURL: false)!

        // Add some properties to make it realistic
        var queryItems = components.queryItems ?? []

        if let channel = properties.channel {
            queryItems.append(URLQueryItem(name: "channel", value: channel))
        }
        if let campaign = properties.campaign {
            queryItems.append(URLQueryItem(name: "campaign", value: campaign))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url ?? mockURL
    }
}

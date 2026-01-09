//
//  LinkGenerator.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// Actor-based link generator implementation.
///
/// Provides thread-safe link generation with caching support.
public actor LinkGenerator: LinkGenerating {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(container: BranchContainer) {
        self.container = container
    }

    // MARK: Public

    /// Get the current cache size
    public var cacheSize: Int {
        linkCache.count
    }

    // MARK: - LinkGenerating

    public func create(with properties: LinkProperties) async throws -> URL {
        // Check cache first
        let cacheKey = buildCacheKey(for: properties)
        if let cachedURL = linkCache[cacheKey] {
            return cachedURL
        }

        // Build request payload
        let payload = buildLinkPayload(properties)
        let data = try JSONSerialization.data(withJSONObject: payload)

        let request = try URLSessionNetworkClient.buildRequest(
            endpoint: "/v1/url",
            method: "POST",
            body: data
        )

        let networkClient = await container.networkClient
        let (responseData, _) = try await networkClient.data(for: request)

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let urlString = json["url"] as? String,
              let url = URL(string: urlString)
        else {
            throw BranchError.linkCreationFailed("Invalid response from server")
        }

        // Cache the result
        linkCache[cacheKey] = url

        return url
    }

    public nonisolated func createLongURL(with properties: LinkProperties) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Self.defaultDomain

        // Build path from alias or generate
        if let alias = properties.alias {
            components.path = "/a/\(alias)"
        } else {
            components.path = "/a/link"
        }

        // Build query parameters
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
        if let stage = properties.stage {
            queryItems.append(URLQueryItem(name: "stage", value: stage))
        }

        // Add tags
        for tag in properties.tags {
            queryItems.append(URLQueryItem(name: "tags", value: tag))
        }

        // Add control params
        for (key, value) in properties.controlParams {
            if let stringValue = value.value as? String {
                queryItems.append(URLQueryItem(name: key, value: stringValue))
            }
        }

        // Add custom data as JSON-encoded parameter
        if !properties.customData.isEmpty {
            let customDataDict = properties.customData.mapValues { $0.value }
            if let jsonData = try? JSONSerialization.data(withJSONObject: customDataDict),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                queryItems.append(URLQueryItem(name: "data", value: jsonString))
            }
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }

    // MARK: - Cache Management

    /// Clear the link cache
    public func clearCache() {
        linkCache.removeAll()
    }

    // MARK: Private

    // MARK: - Constants

    private static let defaultDomain = "app.link"
    private static let defaultAlternateDomain = "test-app.link"

    private let container: BranchContainer
    private var linkCache: [String: URL] = [:]

    // MARK: - Private Methods

    private func buildCacheKey(for properties: LinkProperties) -> String {
        var components: [String] = []

        if let channel = properties.channel {
            components.append("ch:\(channel)")
        }
        if let feature = properties.feature {
            components.append("ft:\(feature)")
        }
        if let campaign = properties.campaign {
            components.append("cp:\(campaign)")
        }
        if let alias = properties.alias {
            components.append("al:\(alias)")
        }

        components.append(contentsOf: properties.tags.map { "tg:\($0)" })

        for (key, value) in properties.customData.sorted(by: { $0.key < $1.key }) {
            components.append("cd:\(key):\(String(describing: value.value))")
        }

        return components.joined(separator: "|")
    }

    private func buildLinkPayload(_ properties: LinkProperties) -> [String: Any] {
        var payload: [String: Any] = [:]

        // Link properties
        if let channel = properties.channel {
            payload["channel"] = channel
        }
        if let feature = properties.feature {
            payload["feature"] = feature
        }
        if let campaign = properties.campaign {
            payload["campaign"] = campaign
        }
        if let stage = properties.stage {
            payload["stage"] = stage
        }
        if !properties.tags.isEmpty {
            payload["tags"] = properties.tags
        }
        if let alias = properties.alias {
            payload["alias"] = alias
        }
        if properties.linkType != 0 {
            payload["type"] = properties.linkType
        }
        if let matchDuration = properties.matchDuration {
            payload["duration"] = matchDuration
        }

        // Data object (control params + custom data)
        var data: [String: Any] = [:]
        for (key, value) in properties.controlParams {
            data[key] = value.value
        }
        for (key, value) in properties.customData {
            data[key] = value.value
        }
        if !data.isEmpty {
            payload["data"] = data
        }

        return payload
    }
}

//
//  IntegrationValidator.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - IntegrationValidator

/// Validates the SDK integration and reports any configuration issues.
///
/// Use this during development to ensure the SDK is properly integrated.
///
/// ## Usage
///
/// ```swift
/// let result = await Branch.shared.validateIntegration()
/// print(result)
/// ```
public actor IntegrationValidator {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(container: BranchContainer) {
        self.container = container
    }

    // MARK: Public

    // MARK: - Validation

    /// Perform all integration validation checks
    /// - Returns: Validation result with all checks
    public func validate() async -> IntegrationValidation {
        var items: [IntegrationValidation.ValidationItem] = []

        // API Key validation
        await items.append(validateAPIKey())

        // URL Scheme validation
        items.append(validateURLSchemes())

        // Associated Domains validation
        items.append(validateAssociatedDomains())

        // Info.plist validation
        items.append(validateInfoPlist())

        // Network reachability
        await items.append(validateNetworkReachability())

        // Privacy Manifest
        items.append(validatePrivacyManifest())

        return IntegrationValidation(items: items)
    }

    // MARK: Private

    private let container: BranchContainer

    // MARK: - Individual Checks

    private func validateAPIKey() async -> IntegrationValidation.ValidationItem {
        guard let config = await container.currentConfiguration else {
            return IntegrationValidation.ValidationItem(
                name: "API Key",
                status: .failed,
                message: "SDK not configured. Call Branch.configure() first."
            )
        }

        let apiKey = config.apiKey

        if apiKey.isEmpty {
            return IntegrationValidation.ValidationItem(
                name: "API Key",
                status: .failed,
                message: "API key is empty"
            )
        }

        if !apiKey.hasPrefix("key_live_"), !apiKey.hasPrefix("key_test_") {
            return IntegrationValidation.ValidationItem(
                name: "API Key",
                status: .warning,
                message: "API key format may be invalid. Expected 'key_live_' or 'key_test_' prefix"
            )
        }

        let isTestKey = apiKey.hasPrefix("key_test_")
        return IntegrationValidation.ValidationItem(
            name: "API Key",
            status: .passed,
            message: isTestKey ? "Using test key" : "Using live key"
        )
    }

    private func validateURLSchemes() -> IntegrationValidation.ValidationItem {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return IntegrationValidation.ValidationItem(
                name: "URL Schemes",
                status: .warning,
                message: "No URL schemes configured. Deep linking via URL schemes won't work."
            )
        }

        var schemes: [String] = []
        for urlType in urlTypes {
            if let urlSchemes = urlType["CFBundleURLSchemes"] as? [String] {
                schemes.append(contentsOf: urlSchemes)
            }
        }

        if schemes.isEmpty {
            return IntegrationValidation.ValidationItem(
                name: "URL Schemes",
                status: .warning,
                message: "No URL schemes found in CFBundleURLTypes"
            )
        }

        return IntegrationValidation.ValidationItem(
            name: "URL Schemes",
            status: .passed,
            message: "Found schemes: \(schemes.joined(separator: ", "))"
        )
    }

    private func validateAssociatedDomains() -> IntegrationValidation.ValidationItem {
        // Note: We can't directly check entitlements at runtime
        // This check is informational
        IntegrationValidation.ValidationItem(
            name: "Associated Domains",
            status: .warning,
            message: "Cannot verify at runtime. Ensure Associated Domains capability is enabled with 'applinks:' entries."
        )
    }

    private func validateInfoPlist() -> IntegrationValidation.ValidationItem {
        var issues: [String] = []

        // Check for Branch key in Info.plist (alternative configuration method)
        if Bundle.main.object(forInfoDictionaryKey: "branch_key") == nil {
            // Not an error - key can be provided programmatically
        }

        // Check for App Transport Security
        if let ats = Bundle.main.object(forInfoDictionaryKey: "NSAppTransportSecurity") as? [String: Any] {
            if ats["NSAllowsArbitraryLoads"] as? Bool == true {
                issues.append("NSAllowsArbitraryLoads is enabled (not recommended for production)")
            }
        }

        // Check for tracking usage description (iOS 14+)
        if Bundle.main.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription") == nil {
            issues.append("NSUserTrackingUsageDescription not set (required for ATT framework)")
        }

        if issues.isEmpty {
            return IntegrationValidation.ValidationItem(
                name: "Info.plist",
                status: .passed,
                message: nil
            )
        } else {
            return IntegrationValidation.ValidationItem(
                name: "Info.plist",
                status: .warning,
                message: issues.joined(separator: "; ")
            )
        }
    }

    private func validateNetworkReachability() async -> IntegrationValidation.ValidationItem {
        // Simple check - try to reach Branch API
        do {
            let request = try URLSessionNetworkClient.buildRequest(
                endpoint: "/v1/app-link-settings",
                method: "GET"
            )
            let networkClient = await container.networkClient
            _ = try await networkClient.data(for: request)
            return IntegrationValidation.ValidationItem(
                name: "Network",
                status: .passed,
                message: "Branch API reachable"
            )
        } catch {
            return IntegrationValidation.ValidationItem(
                name: "Network",
                status: .warning,
                message: "Could not reach Branch API: \(error.localizedDescription)"
            )
        }
    }

    private func validatePrivacyManifest() -> IntegrationValidation.ValidationItem {
        // Check for Privacy Manifest (PrivacyInfo.xcprivacy)
        // This is required for App Store submission starting Spring 2024
        if Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy") != nil {
            IntegrationValidation.ValidationItem(
                name: "Privacy Manifest",
                status: .passed,
                message: "PrivacyInfo.xcprivacy found"
            )
        } else {
            IntegrationValidation.ValidationItem(
                name: "Privacy Manifest",
                status: .warning,
                message: "PrivacyInfo.xcprivacy not found. Required for App Store submission."
            )
        }
    }
}

// MARK: - Debug Helpers

public extension IntegrationValidator {
    /// Log validation results using the SDK logger
    func logValidation() async {
        let result = await validate()
        container.logger.log(.info, result.description, file: #file, function: #function, line: #line)
    }
}

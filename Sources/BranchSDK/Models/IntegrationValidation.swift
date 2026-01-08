//
//  IntegrationValidation.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - IntegrationValidation

/// Result of SDK integration validation.
///
/// Provides detailed information about the SDK setup and any issues found.
public struct IntegrationValidation: Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(items: [ValidationItem]) {
        self.items = items
    }

    // MARK: Public

    // MARK: - Validation Item

    /// A single validation check result
    public struct ValidationItem: Sendable, Identifiable {
        public enum Status: Sendable {
            case passed
            case warning
            case failed
        }

        public let id = UUID()
        public let name: String
        public let status: Status
        public let message: String?
    }

    /// All validation items
    public let items: [ValidationItem]

    /// Overall validation passed
    public var isValid: Bool {
        !items.contains { $0.status == .failed }
    }

    /// Number of passed checks
    public var passedCount: Int {
        items.count(where: { $0.status == .passed })
    }

    /// Number of warnings
    public var warningCount: Int {
        items.count(where: { $0.status == .warning })
    }

    /// Number of failed checks
    public var failedCount: Int {
        items.count(where: { $0.status == .failed })
    }

    /// Failed items
    public var failures: [ValidationItem] {
        items.filter { $0.status == .failed }
    }

    /// Warning items
    public var warnings: [ValidationItem] {
        items.filter { $0.status == .warning }
    }
}

// MARK: CustomStringConvertible

extension IntegrationValidation: CustomStringConvertible {
    public var description: String {
        var lines = ["Branch SDK Integration Validation"]
        lines.append("=".padding(toLength: 40, withPad: "=", startingAt: 0))

        for item in items {
            let icon = switch item.status {
            case .passed:
                "✓"
            case .warning:
                "⚠"
            case .failed:
                "✗"
            }
            var line = "\(icon) \(item.name)"
            if let message = item.message {
                line += ": \(message)"
            }
            lines.append(line)
        }

        lines.append("=".padding(toLength: 40, withPad: "=", startingAt: 0))
        lines.append("Result: \(passedCount) passed, \(warningCount) warnings, \(failedCount) failed")

        return lines.joined(separator: "\n")
    }
}

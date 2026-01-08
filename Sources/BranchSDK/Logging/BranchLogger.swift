//
//  BranchLogger.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation
import OSLog

// MARK: - BranchLogger

/// Shared logger implementation for the Branch SDK.
///
/// Uses Apple's unified logging system (OSLog) for optimal performance
/// and integration with Console.app and Instruments.
public final class BranchLogger: Logging, @unchecked Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    private init() {
        osLog = OSLog(subsystem: "io.branch.sdk", category: "Branch")
    }

    // MARK: Public

    // MARK: - Singleton

    /// Shared logger instance
    public static let shared = BranchLogger()

    /// The minimum log level to output
    public var minimumLevel: LogLevel = .warning

    /// Whether to include file/function/line in log output
    public var includeSourceLocation: Bool = true

    /// Custom log handler for capturing logs programmatically
    public var customHandler: ((LogLevel, String, String, String, Int) -> Void)?

    // MARK: - Logging Protocol

    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= minimumLevel else {
            return
        }

        let messageString = message()

        // Call custom handler if set
        if let handler = customHandler {
            handler(level, messageString, file, function, line)
        }

        // Build the log message
        let formattedMessage: String
        if includeSourceLocation {
            let filename = (file as NSString).lastPathComponent
            formattedMessage = "[\(filename):\(line)] \(function) - \(messageString)"
        } else {
            formattedMessage = messageString
        }

        // Log to OSLog
        queue.async { [osLog] in
            os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        }

        // Also print to console in debug builds
        #if DEBUG
        let timestamp = Self.timestampFormatter.string(from: Date())
        let levelPrefix = level.prefix
        print("[\(timestamp)] \(levelPrefix) Branch: \(formattedMessage)")
        #endif
    }

    // MARK: Private

    // MARK: - Private Helpers

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    // MARK: - Private Properties

    private let osLog: OSLog
    private let queue = DispatchQueue(label: "io.branch.sdk.logger", qos: .utility)
}

// MARK: - LogLevel Extensions

extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .verbose:
            .debug
        case .debug:
            .debug
        case .info:
            .info
        case .warning:
            .default
        case .error:
            .error
        case .none:
            .fault
        }
    }

    var prefix: String {
        switch self {
        case .verbose:
            "VERBOSE"
        case .debug:
            "DEBUG"
        case .info:
            "INFO"
        case .warning:
            "WARNING"
        case .error:
            "ERROR"
        case .none:
            ""
        }
    }
}

// MARK: - Convenience Static Methods

public extension BranchLogger {
    /// Enable verbose logging for debugging
    static func enableVerboseLogging() {
        shared.minimumLevel = .verbose
    }

    /// Enable debug logging
    static func enableDebugLogging() {
        shared.minimumLevel = .debug
    }

    /// Disable all logging
    static func disableLogging() {
        shared.minimumLevel = .none
    }

    /// Reset to default logging level
    static func resetLoggingLevel() {
        shared.minimumLevel = .warning
    }
}

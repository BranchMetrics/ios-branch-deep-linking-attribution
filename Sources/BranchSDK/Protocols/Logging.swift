//
//  Logging.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation
import OSLog

// MARK: - LogLevel

/// Log levels for the SDK
public enum LogLevel: Int, Comparable, Sendable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case none = 5

    // MARK: Public

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Logging

/// Protocol for SDK logging.
///
/// Provides a unified logging interface that can be customized or mocked.
public protocol Logging: Sendable {
    /// The minimum log level to output
    var minimumLevel: LogLevel { get set }

    /// Log a message at the specified level
    /// - Parameters:
    ///   - level: The log level
    ///   - message: The message to log
    ///   - file: The source file (auto-populated)
    ///   - function: The source function (auto-populated)
    ///   - line: The source line (auto-populated)
    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Convenience Extensions

public extension Logging {
    /// Log a verbose message
    func verbose(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.verbose, message(), file: file, function: function, line: line)
    }

    /// Log a debug message
    func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message(), file: file, function: function, line: line)
    }

    /// Log an info message
    func info(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), file: file, function: function, line: line)
    }

    /// Log a warning message
    func warning(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message(), file: file, function: function, line: line)
    }

    /// Log an error message
    func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), file: file, function: function, line: line)
    }
}

//
//  BranchLoggerAdapter.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// Import the Objective-C BranchLogger via the BranchSDK module
// This requires BranchSDK to be properly linked
#if canImport(BranchSDK)
    import BranchSDK
#endif

// MARK: - LogLevel

/// Swift-native log levels that map to BranchLogLevel
public enum LogLevel: Int, Comparable, Sendable {
    /// Detailed debugging information
    case verbose = 0

    /// Debug information for development
    case debug = 1

    /// Warning messages for potentially problematic situations
    case warning = 2

    /// Error messages for failures
    case error = 3

    /// No logging
    case none = 4

    // MARK: Public

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    #if canImport(BranchSDK)
        /// Convert to Objective-C BranchLogLevel
        var branchLogLevel: BranchLogLevel {
            switch self {
            case .verbose:
                return .verbose
            case .debug:
                return .debug
            case .warning:
                return .warning
            case .error:
                return .error
            case .none:
                return .error // No equivalent, use highest
            }
        }
    #endif
}

// MARK: - CustomStringConvertible

extension LogLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .verbose:
            "VERBOSE"
        case .debug:
            "DEBUG"
        case .warning:
            "WARNING"
        case .error:
            "ERROR"
        case .none:
            "NONE"
        }
    }
}

// MARK: - Logging Protocol

/// Protocol for SDK logging functionality.
///
/// Implementations should be thread-safe and efficient,
/// avoiding expensive operations when logging is disabled.
public protocol Logging: Sendable {
    /// The minimum log level to output
    var minimumLevel: LogLevel { get }

    /// Log a message at the specified level
    ///
    /// - Parameters:
    ///   - level: The severity level of the message
    ///   - message: The message to log (autoclosure for lazy evaluation)
    ///   - file: The source file (automatically captured)
    ///   - function: The function name (automatically captured)
    ///   - line: The line number (automatically captured)
    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    )
}

// MARK: - Default Logging Convenience Methods

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

// MARK: - BranchLoggerAdapter

/// Adapter that bridges Swift logging calls to the existing Objective-C BranchLogger.
///
/// This adapter allows the modern Swift SessionManager to use the existing
/// BranchLogger infrastructure without duplicating logging logic.
///
/// When BranchSDK is not available (e.g., in standalone Swift builds),
/// falls back to print statements in DEBUG mode.
public final class BranchLoggerAdapter: Logging, @unchecked Sendable {
    // MARK: Lifecycle

    public init(minimumLevel: LogLevel = .warning) {
        _minimumLevel = minimumLevel
    }

    // MARK: Public

    /// Shared adapter instance (uses verbose level to let BranchLogger control filtering)
    public static let shared = BranchLoggerAdapter(minimumLevel: .verbose)

    public var minimumLevel: LogLevel {
        _minimumLevel
    }

    public func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String,
        function: String,
        line: Int
    ) {
        guard level >= _minimumLevel else {
            return
        }

        let messageString = message()
        let filename = (file as NSString).lastPathComponent
        let formattedMessage = "[\(filename):\(line)] \(function) - \(messageString)"

        #if canImport(BranchSDK)
            // Use the existing Objective-C BranchLogger
            let logger = BranchLogger.shared()
            switch level {
            case .verbose:
                logger.logVerbose(formattedMessage, error: nil)
            case .debug:
                logger.logDebug(formattedMessage, error: nil)
            case .warning:
                logger.logWarning(formattedMessage, error: nil)
            case .error:
                logger.logError(formattedMessage, error: nil)
            case .none:
                break
            }
        #else
            // Fallback for standalone Swift builds (testing, etc.)
            #if DEBUG
                print("[Branch][\(level.description)] \(formattedMessage)")
            #endif
        #endif
    }

    // MARK: Private

    private let _minimumLevel: LogLevel
}

// MARK: - Convenience Static Methods

public extension BranchLoggerAdapter {
    /// Enable verbose logging for debugging
    static func enableVerboseLogging() -> BranchLoggerAdapter {
        BranchLoggerAdapter(minimumLevel: .verbose)
    }

    /// Enable debug logging
    static func enableDebugLogging() -> BranchLoggerAdapter {
        BranchLoggerAdapter(minimumLevel: .debug)
    }

    /// Create adapter with custom minimum level
    static func with(minimumLevel: LogLevel) -> BranchLoggerAdapter {
        BranchLoggerAdapter(minimumLevel: minimumLevel)
    }
}

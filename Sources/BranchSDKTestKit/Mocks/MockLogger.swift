//
//  MockLogger.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock logger for testing.
///
/// Captures all log messages for verification in tests.
public final class MockLogger: Logging, @unchecked Sendable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    // MARK: - Types

    public struct LogEntry: Equatable, Sendable {
        // MARK: Lifecycle

        public init(
            level: LogLevel,
            message: String,
            file: String,
            function: String,
            line: Int,
            timestamp: Date = Date()
        ) {
            self.level = level
            self.message = message
            self.file = file
            self.function = function
            self.line = line
            self.timestamp = timestamp
        }

        // MARK: Public

        public let level: LogLevel
        public let message: String
        public let file: String
        public let function: String
        public let line: Int
        public let timestamp: Date
    }

    public var minimumLevel: LogLevel = .verbose

    /// All logged entries
    public var logs: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _logs
    }

    /// Get all error logs
    public var errorLogs: [LogEntry] {
        logs(at: .error)
    }

    /// Get all warning logs
    public var warningLogs: [LogEntry] {
        logs(at: .warning)
    }

    /// Get the last logged message
    public var lastLog: LogEntry? {
        lock.lock()
        defer { lock.unlock() }
        return _logs.last
    }

    /// Get log count
    public var logCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _logs.count
    }

    // MARK: - Logging

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

        let entry = LogEntry(
            level: level,
            message: message(),
            file: file,
            function: function,
            line: line
        )

        lock.lock()
        _logs.append(entry)
        lock.unlock()
    }

    // MARK: - Test Helpers

    /// Get all logs at a specific level
    public func logs(at level: LogLevel) -> [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _logs.filter { $0.level == level }
    }

    /// Check if a message containing specific text was logged
    public func hasLog(containing text: String, at level: LogLevel? = nil) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return _logs.contains { entry in
            let levelMatch = level == nil || entry.level == level
            return levelMatch && entry.message.contains(text)
        }
    }

    /// Clear all logs
    public func clearLogs() {
        lock.lock()
        defer { lock.unlock() }
        _logs.removeAll()
    }

    /// Reset all state
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        _logs.removeAll()
        minimumLevel = .verbose
    }

    // MARK: Private

    private let lock = NSLock()
    private var _logs: [LogEntry] = []
}

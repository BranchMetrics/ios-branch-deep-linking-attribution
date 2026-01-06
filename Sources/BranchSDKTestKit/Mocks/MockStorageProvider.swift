//
//  MockStorageProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock storage provider for testing.
///
/// Provides an in-memory storage implementation that allows
/// verification of storage operations in tests.
public actor MockStorageProvider: StorageProvider {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init() {}

    // MARK: Public

    // MARK: - Types

    public enum Operation: Equatable, Sendable {
        case set(key: String)
        case get(key: String)
        case remove(key: String)
        case contains(key: String)
        case clear
        case allKeys
    }

    /// Track all operations performed
    public private(set) var operations: [Operation] = []

    /// Get raw storage for inspection
    public var rawStorage: [String: Data] {
        storage
    }

    // MARK: - StorageProvider

    public func set(_ value: some Codable & Sendable, forKey key: StorageKey) {
        operations.append(.set(key: key.rawValue))

        do {
            let data = try encoder.encode(value)
            storage[key.rawValue] = data
        } catch {
            // Silent failure in mock
        }
    }

    public func get<T: Codable & Sendable>(forKey key: StorageKey) -> T? {
        operations.append(.get(key: key.rawValue))

        guard let data = storage[key.rawValue] else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    public func remove(forKey key: StorageKey) {
        operations.append(.remove(key: key.rawValue))
        storage.removeValue(forKey: key.rawValue)
    }

    public func contains(key: StorageKey) -> Bool {
        operations.append(.contains(key: key.rawValue))
        return storage[key.rawValue] != nil
    }

    public func clear() {
        operations.append(.clear)
        storage.removeAll()
    }

    public func allKeys() -> [StorageKey] {
        operations.append(.allKeys)
        return storage.keys.map { StorageKey(rawValue: $0) }
    }

    // MARK: - Test Helpers

    /// Pre-populate storage with a value
    public func prePopulate(_ value: some Codable & Sendable, forKey key: StorageKey) {
        do {
            let data = try encoder.encode(value)
            storage[key.rawValue] = data
        } catch {
            // Silent failure in mock
        }
    }

    /// Clear operation history
    public func clearOperations() {
        operations.removeAll()
    }

    /// Reset all state
    public func reset() {
        storage.removeAll()
        operations.removeAll()
    }

    /// Check if a specific operation was performed
    public func hasOperation(_ operation: Operation) -> Bool {
        operations.contains(operation)
    }

    // MARK: Private

    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
}

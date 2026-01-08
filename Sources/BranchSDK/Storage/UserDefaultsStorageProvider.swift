//
//  UserDefaultsStorageProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

/// UserDefaults-based implementation of StorageProvider.
///
/// Provides persistent storage using UserDefaults with JSON encoding
/// for complex types.
public actor UserDefaultsStorageProvider: StorageProvider {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        suiteName: String? = nil,
        keyPrefix: String = "io.branch.sdk."
    ) {
        if let suiteName {
            defaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            defaults = .standard
        }
        self.keyPrefix = keyPrefix
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    // MARK: Public

    // MARK: - StorageProvider

    public func set(_ value: some Codable & Sendable, forKey key: StorageKey) {
        let prefixedKey = prefixed(key)

        // Try to store directly for primitive types
        if let stringValue = value as? String {
            defaults.set(stringValue, forKey: prefixedKey)
        } else if let intValue = value as? Int {
            defaults.set(intValue, forKey: prefixedKey)
        } else if let doubleValue = value as? Double {
            defaults.set(doubleValue, forKey: prefixedKey)
        } else if let boolValue = value as? Bool {
            defaults.set(boolValue, forKey: prefixedKey)
        } else if let dateValue = value as? Date {
            defaults.set(dateValue, forKey: prefixedKey)
        } else if let dataValue = value as? Data {
            defaults.set(dataValue, forKey: prefixedKey)
        } else {
            // Encode complex types as JSON
            do {
                let data = try encoder.encode(value)
                defaults.set(data, forKey: prefixedKey)
            } catch {
                BranchLogger.shared.error("Failed to encode value for key \(key.rawValue): \(error)")
            }
        }
    }

    public func get<T: Codable & Sendable>(forKey key: StorageKey) -> T? {
        let prefixedKey = prefixed(key)

        // Try to retrieve directly for primitive types
        if T.self == String.self {
            return defaults.string(forKey: prefixedKey) as? T
        } else if T.self == Int.self {
            return defaults.integer(forKey: prefixedKey) as? T
        } else if T.self == Double.self {
            return defaults.double(forKey: prefixedKey) as? T
        } else if T.self == Bool.self {
            return defaults.bool(forKey: prefixedKey) as? T
        } else if T.self == Date.self {
            return defaults.object(forKey: prefixedKey) as? T
        } else if T.self == Data.self {
            return defaults.data(forKey: prefixedKey) as? T
        } else {
            // Decode complex types from JSON
            guard let data = defaults.data(forKey: prefixedKey) else {
                return nil
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                BranchLogger.shared.error("Failed to decode value for key \(key.rawValue): \(error)")
                return nil
            }
        }
    }

    public func remove(forKey key: StorageKey) {
        defaults.removeObject(forKey: prefixed(key))
    }

    public func contains(key: StorageKey) -> Bool {
        defaults.object(forKey: prefixed(key)) != nil
    }

    public func clear() {
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(keyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    public func allKeys() -> [StorageKey] {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .map { StorageKey(rawValue: String($0.dropFirst(keyPrefix.count))) }
    }

    // MARK: Private

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let keyPrefix: String

    // MARK: - Private Helpers

    private func prefixed(_ key: StorageKey) -> String {
        keyPrefix + key.rawValue
    }
}

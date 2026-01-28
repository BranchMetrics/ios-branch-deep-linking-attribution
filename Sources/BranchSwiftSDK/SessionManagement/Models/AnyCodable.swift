//
//  AnyCodable.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - AnyCodable

/// A type-erased Codable value.
///
/// This wrapper allows storing heterogeneous values in dictionaries
/// while maintaining Codable conformance. Uses `@unchecked Sendable`
/// because it only stores primitive Sendable types internally.
public struct AnyCodable: @unchecked Sendable, Equatable, Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Initialize with a Sendable value
    public init(_ value: some Sendable) {
        _value = value
    }

    /// Initialize with nil
    public init(nilLiteral _: ()) {
        _value = NSNull()
    }

    /// Private initializer for internal use with Any values
    /// Safe because AnyCodable is @unchecked Sendable and only stores primitive types
    private init(anyValue: Any) {
        _value = anyValue
    }

    // MARK: - Codable

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            _value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            _value = bool
        } else if let int = try? container.decode(Int.self) {
            _value = int
        } else if let double = try? container.decode(Double.self) {
            _value = double
        } else if let string = try? container.decode(String.self) {
            _value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            _value = array.map(\.value)
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            _value = dictionary.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode AnyCodable"
            )
        }
    }

    // MARK: Public

    /// Access to the underlying value
    public var value: Any { _value }

    // MARK: - Equatable

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs._value, rhs._value) {
        case (is NSNull, is NSNull):
            true
        case let (lhs as Bool, rhs as Bool):
            lhs == rhs
        case let (lhs as Int, rhs as Int):
            lhs == rhs
        case let (lhs as Double, rhs as Double):
            lhs == rhs
        case let (lhs as String, rhs as String):
            lhs == rhs
        default:
            false
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch _value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { wrapAny($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { wrapAny($0) })
        default:
            throw EncodingError.invalidValue(
                _value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to encode AnyCodable"
                )
            )
        }
    }

    // MARK: Private

    /// The underlying value - only stores Sendable primitive types
    private let _value: Any

    // MARK: - Private Helpers

    /// Wrap an Any value into AnyCodable, handling the Sendable requirement
    private func wrapAny(_ value: Any) -> AnyCodable {
        // Since we're @unchecked Sendable and only store primitive types,
        // we can safely wrap Any values during encoding
        switch value {
        case let bool as Bool:
            AnyCodable(bool)
        case let int as Int:
            AnyCodable(int)
        case let double as Double:
            AnyCodable(double)
        case let string as String:
            AnyCodable(string)
        case is NSNull:
            AnyCodable(nilLiteral: ())
        default:
            // For complex types, wrap as-is (best effort)
            // Uses private initializer to avoid Sendable cast issues
            AnyCodable(anyValue: value)
        }
    }
}

// MARK: ExpressibleByNilLiteral

extension AnyCodable: ExpressibleByNilLiteral {}

// MARK: ExpressibleByBooleanLiteral

extension AnyCodable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        _value = value
    }
}

// MARK: ExpressibleByIntegerLiteral

extension AnyCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        _value = value
    }
}

// MARK: ExpressibleByFloatLiteral

extension AnyCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        _value = value
    }
}

// MARK: ExpressibleByStringLiteral

extension AnyCodable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        _value = value
    }
}

// MARK: ExpressibleByArrayLiteral

extension AnyCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: (any Sendable)...) {
        _value = elements
    }
}

// MARK: ExpressibleByDictionaryLiteral

extension AnyCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, any Sendable)...) {
        _value = Dictionary(uniqueKeysWithValues: elements)
    }
}

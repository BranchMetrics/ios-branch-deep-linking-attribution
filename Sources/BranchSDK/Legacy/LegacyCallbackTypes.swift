//
//  LegacyCallbackTypes.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - Legacy Callback Type Aliases

/// Callback type for session initialization with parameters.
///
/// This matches the v3 SDK's `callbackWithParams` type:
/// `typedef void (^callbackWithParams)(NSDictionary * _Nullable params, NSError * _Nullable error)`
///
/// ## Example
///
/// ```swift
/// let callback: LegacySessionCallback = { params, error in
///     if let error = error {
///         print("Error: \(error)")
///         return
///     }
///     if let params = params {
///         print("Session params: \(params)")
///     }
/// }
/// ```
public typealias LegacySessionCallback = @Sendable ([String: Any]?, (any Error)?) -> Void

/// Callback type for URL generation.
///
/// This matches the v3 SDK's `callbackWithUrl` type:
/// `typedef void (^callbackWithUrl)(NSString * _Nullable url, NSError * _Nullable error)`
public typealias LegacyURLCallback = @Sendable (String?, (any Error)?) -> Void

/// Callback type for status changes.
///
/// This matches the v3 SDK's `callbackWithStatus` type:
/// `typedef void (^callbackWithStatus)(BOOL changed, NSError * _Nullable error)`
public typealias LegacyStatusCallback = @Sendable (Bool, (any Error)?) -> Void

/// Callback type for list results.
///
/// This matches the v3 SDK's `callbackWithList` type:
/// `typedef void (^callbackWithList)(NSArray * _Nullable list, NSError * _Nullable error)`
public typealias LegacyListCallback = @Sendable ([Any]?, (any Error)?) -> Void

// MARK: - LegacyCallbackHelper

/// Utilities for working with legacy callbacks.
public enum LegacyCallbackHelper {
    /// Executes a legacy callback on the main thread.
    ///
    /// This ensures callbacks are delivered on the main thread,
    /// matching v3 SDK behavior for UI compatibility.
    ///
    /// - Parameters:
    ///   - callback: The callback to execute
    ///   - params: Session parameters
    ///   - error: Error, if any
    @MainActor
    public static func executeOnMainThread(
        _ callback: @escaping LegacySessionCallback,
        params: [String: Any]?,
        error: (any Error)?
    ) {
        callback(params, error)
    }

    /// Executes a legacy callback on the main thread using DispatchQueue.
    ///
    /// This variant can be called from non-MainActor contexts.
    /// Uses nonisolated(unsafe) to handle the dictionary crossing actor boundaries,
    /// which is safe because we're immediately dispatching to main thread.
    ///
    /// - Parameters:
    ///   - callback: The callback to execute
    ///   - params: Session parameters
    ///   - error: Error, if any
    public static func dispatchToMainThread(
        _ callback: @escaping LegacySessionCallback,
        params: [String: Any]?,
        error: (any Error)?
    ) {
        // Capture params safely - [String: Any]? is not Sendable
        nonisolated(unsafe) let capturedParams = params

        if Thread.isMainThread {
            callback(capturedParams, error)
        } else {
            DispatchQueue.main.async {
                callback(capturedParams, error)
            }
        }
    }

    /// Executes a legacy URL callback on the main thread.
    ///
    /// - Parameters:
    ///   - callback: The URL callback to execute
    ///   - url: URL string
    ///   - error: Error, if any
    public static func dispatchToMainThread(
        _ callback: @escaping LegacyURLCallback,
        url: String?,
        error: (any Error)?
    ) {
        if Thread.isMainThread {
            callback(url, error)
        } else {
            DispatchQueue.main.async {
                callback(url, error)
            }
        }
    }
}

// MARK: - SendableSessionCallback

/// A thread-safe wrapper for legacy callbacks.
///
/// This wrapper safely invokes callbacks on the main thread,
/// making them usable across actor boundaries in Swift 6.
public struct SendableSessionCallback: Sendable {
    // MARK: Lifecycle

    public init(_ callback: @escaping LegacySessionCallback) {
        self.callback = callback
    }

    // MARK: Public

    /// Invoke the callback on the main thread with session parameters.
    public func callAsFunction(_ params: [String: Any]?, _ error: (any Error)?) {
        LegacyCallbackHelper.dispatchToMainThread(callback, params: params, error: error)
    }

    /// Invoke the callback directly (caller ensures main thread).
    @MainActor
    public func invokeDirectly(_ params: [String: Any]?, _ error: (any Error)?) {
        callback(params, error)
    }

    // MARK: Private

    private let callback: LegacySessionCallback
}

// MARK: - SendableURLCallback

/// A thread-safe wrapper for legacy URL callbacks.
public struct SendableURLCallback: Sendable {
    // MARK: Lifecycle

    public init(_ callback: @escaping LegacyURLCallback) {
        self.callback = callback
    }

    // MARK: Public

    /// Invoke the callback on the main thread with URL.
    public func callAsFunction(_ url: String?, _ error: (any Error)?) {
        LegacyCallbackHelper.dispatchToMainThread(callback, url: url, error: error)
    }

    /// Invoke the callback directly (caller ensures main thread).
    @MainActor
    public func invokeDirectly(_ url: String?, _ error: (any Error)?) {
        callback(url, error)
    }

    // MARK: Private

    private let callback: LegacyURLCallback
}

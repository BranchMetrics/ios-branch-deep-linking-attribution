//
//  BranchSDKTestKit.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

/// BranchSDKTestKit provides mock implementations for testing
/// Branch SDK integrations.
///
/// ## Overview
///
/// Use this module to test your app's Branch SDK integration without
/// making actual network requests.
///
/// ```swift
/// import BranchSDKTestKit
///
/// let mockNetwork = MockNetworkClient()
/// let container = BranchContainer(networkClient: mockNetwork)
/// let branch = Branch(container: container)
/// ```
public enum BranchSDKTestKit {
    /// Test kit version
    public static let version = "4.0.0-alpha.1"
}

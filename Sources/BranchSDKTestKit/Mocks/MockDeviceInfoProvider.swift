//
//  MockDeviceInfoProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import BranchSDK
import Foundation

/// Mock device info provider for testing.
///
/// Provides configurable device information for testing scenarios
/// without requiring actual device APIs.
public actor MockDeviceInfoProvider: DeviceInfoProvider {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(deviceInfo: DeviceInfo? = nil) {
        if let deviceInfo {
            mockDeviceInfo = deviceInfo
        } else {
            mockDeviceInfo = Self.defaultDeviceInfo
        }
    }

    // MARK: Public

    // MARK: - Types

    public enum Operation: Equatable, Sendable {
        case collectDeviceInfo
        case getCurrentDeviceInfo
        case refreshHardwareId
        case checkATTStatus
        case registerPlugin(name: String, version: String)
        case localIPAddress
        case connectionType
        case userAgentString
    }

    /// Track all operations performed
    public private(set) var operations: [Operation] = []

    // MARK: - Configurable Responses

    /// The device info to return from collection methods
    public var mockDeviceInfo: DeviceInfo

    /// The ATT status to return
    public var mockATTStatus: ATTAuthorizationStatus = .notDetermined

    /// The local IP address to return
    public var mockLocalIPAddress: String? = "192.168.1.100"

    /// The connection type to return
    public var mockConnectionType: String = "wifi"

    /// The user agent to return
    public var mockUserAgent: String = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"

    // MARK: - DeviceInfoProvider

    public var currentDeviceInfo: DeviceInfo {
        get async {
            operations.append(.getCurrentDeviceInfo)
            return mockDeviceInfo
        }
    }

    // MARK: - Convenience Initializers

    /// Create a mock with authorized ATT status
    public static func authorized() -> MockDeviceInfoProvider {
        let provider = MockDeviceInfoProvider()
        Task {
            await provider.setATTStatus(.authorized)
        }
        return provider
    }

    /// Create a mock with denied ATT status
    public static func denied() -> MockDeviceInfoProvider {
        let provider = MockDeviceInfoProvider()
        Task {
            await provider.setATTStatus(.denied)
        }
        return provider
    }

    public func collectDeviceInfo() async -> DeviceInfo {
        operations.append(.collectDeviceInfo)
        return mockDeviceInfo
    }

    public func refreshHardwareId() async -> DeviceInfo {
        operations.append(.refreshHardwareId)
        return mockDeviceInfo
    }

    public func checkATTStatus() async -> ATTAuthorizationStatus {
        operations.append(.checkATTStatus)
        return mockATTStatus
    }

    public func registerPlugin(name: String, version: String) {
        operations.append(.registerPlugin(name: name, version: version))

        // Update mock device info with plugin info
        mockDeviceInfo = DeviceInfo(
            hardwareId: mockDeviceInfo.hardwareId,
            hardwareIdType: mockDeviceInfo.hardwareIdType,
            isRealHardwareId: mockDeviceInfo.isRealHardwareId,
            vendorId: mockDeviceInfo.vendorId,
            advertiserId: mockDeviceInfo.advertiserId,
            anonId: mockDeviceInfo.anonId,
            attAuthorizationStatus: mockDeviceInfo.attAuthorizationStatus,
            isFirstOptIn: mockDeviceInfo.isFirstOptIn,
            brandName: mockDeviceInfo.brandName,
            modelName: mockDeviceInfo.modelName,
            osName: mockDeviceInfo.osName,
            osVersion: mockDeviceInfo.osVersion,
            osBuildVersion: mockDeviceInfo.osBuildVersion,
            cpuType: mockDeviceInfo.cpuType,
            environment: mockDeviceInfo.environment,
            screenWidth: mockDeviceInfo.screenWidth,
            screenHeight: mockDeviceInfo.screenHeight,
            screenScale: mockDeviceInfo.screenScale,
            locale: mockDeviceInfo.locale,
            country: mockDeviceInfo.country,
            language: mockDeviceInfo.language,
            timezone: mockDeviceInfo.timezone,
            applicationVersion: mockDeviceInfo.applicationVersion,
            branchSDKVersion: mockDeviceInfo.branchSDKVersion,
            pluginName: name,
            pluginVersion: version,
            isSimulator: mockDeviceInfo.isSimulator,
            collectedAt: mockDeviceInfo.collectedAt
        )
    }

    public func localIPAddress() async -> String? {
        operations.append(.localIPAddress)
        return mockLocalIPAddress
    }

    public func connectionType() async -> String {
        operations.append(.connectionType)
        return mockConnectionType
    }

    public func userAgentString() async -> String {
        operations.append(.userAgentString)
        return mockUserAgent
    }

    // MARK: - Test Helpers

    /// Clear operation history
    public func clearOperations() {
        operations.removeAll()
    }

    /// Reset all state to defaults
    public func reset() {
        operations.removeAll()
        mockDeviceInfo = Self.defaultDeviceInfo
        mockATTStatus = .notDetermined
        mockLocalIPAddress = "192.168.1.100"
        mockConnectionType = "wifi"
        mockUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
    }

    /// Check if a specific operation was performed
    public func hasOperation(_ operation: Operation) -> Bool {
        operations.contains(operation)
    }

    /// Count how many times an operation was performed
    public func operationCount(_ operation: Operation) -> Int {
        operations.count(where: { $0 == operation })
    }

    /// Set ATT status
    public func setATTStatus(_ status: ATTAuthorizationStatus) {
        mockATTStatus = status
    }

    /// Set device info
    public func setDeviceInfo(_ deviceInfo: DeviceInfo) {
        mockDeviceInfo = deviceInfo
    }

    // MARK: Private

    // MARK: - Default Test Device Info

    private static let defaultDeviceInfo = DeviceInfo(
        hardwareId: "test-vendor-id-12345",
        hardwareIdType: .vendorId,
        isRealHardwareId: true,
        vendorId: "test-vendor-id-12345",
        advertiserId: nil,
        anonId: "test-anon-id-67890",
        attAuthorizationStatus: .notDetermined,
        isFirstOptIn: false,
        brandName: "Apple",
        modelName: "iPhone15,2",
        osName: "iOS",
        osVersion: "17.0.0",
        osBuildVersion: "21A329",
        cpuType: "16777228",
        environment: "SIMULATOR",
        screenWidth: 390,
        screenHeight: 844,
        screenScale: 3.0,
        locale: "en_US",
        country: "US",
        language: "en",
        timezone: "America/Los_Angeles",
        applicationVersion: "1.0.0",
        branchSDKVersion: "ios4.0.0-alpha",
        pluginName: nil,
        pluginVersion: nil,
        isSimulator: true
    )
}

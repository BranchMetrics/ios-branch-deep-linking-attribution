//
//  DeviceInfoProviderTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import BranchSDKTestKit
import Foundation
import Testing

@Suite("DeviceInfoProvider Tests")
struct DeviceInfoProviderTests {
    // MARK: - MockDeviceInfoProvider Tests

    @Test("Mock provider returns configured device info")
    func mockReturnsConfiguredDeviceInfo() async {
        let mockProvider = MockDeviceInfoProvider()

        let deviceInfo = await mockProvider.collectDeviceInfo()

        #expect(deviceInfo.brandName == "Apple")
        #expect(deviceInfo.modelName == "iPhone15,2")
        #expect(deviceInfo.osName == "iOS")
    }

    @Test("Mock provider tracks collectDeviceInfo operation")
    func mockTracksCollectOperation() async {
        let mockProvider = MockDeviceInfoProvider()

        _ = await mockProvider.collectDeviceInfo()

        let hasOperation = await mockProvider.hasOperation(.collectDeviceInfo)
        #expect(hasOperation)
    }

    @Test("Mock provider tracks refreshHardwareId operation")
    func mockTracksRefreshOperation() async {
        let mockProvider = MockDeviceInfoProvider()

        _ = await mockProvider.refreshHardwareId()

        let hasOperation = await mockProvider.hasOperation(.refreshHardwareId)
        #expect(hasOperation)
    }

    @Test("Mock provider returns configured ATT status")
    func mockReturnsConfiguredATTStatus() async {
        let mockProvider = MockDeviceInfoProvider()
        await mockProvider.setATTStatus(.authorized)

        let status = await mockProvider.checkATTStatus()

        #expect(status == .authorized)
    }

    @Test("Mock provider tracks registerPlugin operation")
    func mockTracksRegisterPluginOperation() async {
        let mockProvider = MockDeviceInfoProvider()

        await mockProvider.registerPlugin(name: "Flutter", version: "3.0.0")

        let hasOperation = await mockProvider.hasOperation(.registerPlugin(name: "Flutter", version: "3.0.0"))
        #expect(hasOperation)
    }

    @Test("Mock provider updates device info after plugin registration")
    func mockUpdatesDeviceInfoAfterPluginRegistration() async {
        let mockProvider = MockDeviceInfoProvider()

        await mockProvider.registerPlugin(name: "React Native", version: "0.72.0")
        let deviceInfo = await mockProvider.currentDeviceInfo

        #expect(deviceInfo.pluginName == "React Native")
        #expect(deviceInfo.pluginVersion == "0.72.0")
    }

    @Test("Mock provider returns configured local IP address")
    func mockReturnsConfiguredLocalIP() async {
        let mockProvider = MockDeviceInfoProvider()

        let ip = await mockProvider.localIPAddress()

        #expect(ip == "192.168.1.100")
    }

    @Test("Mock provider returns configured connection type")
    func mockReturnsConfiguredConnectionType() async {
        let mockProvider = MockDeviceInfoProvider()

        let connectionType = await mockProvider.connectionType()

        #expect(connectionType == "wifi")
    }

    @Test("Mock provider returns configured user agent")
    func mockReturnsConfiguredUserAgent() async {
        let mockProvider = MockDeviceInfoProvider()

        let userAgent = await mockProvider.userAgentString()

        #expect(userAgent.contains("iPhone"))
    }

    @Test("Mock provider clears operations correctly")
    func mockClearsOperations() async {
        let mockProvider = MockDeviceInfoProvider()

        _ = await mockProvider.collectDeviceInfo()
        _ = await mockProvider.refreshHardwareId()

        await mockProvider.clearOperations()

        let operations = await mockProvider.operations
        #expect(operations.isEmpty)
    }

    @Test("Mock provider resets to defaults correctly")
    func mockResetsToDefaults() async {
        let mockProvider = MockDeviceInfoProvider()

        await mockProvider.setATTStatus(.authorized)
        _ = await mockProvider.collectDeviceInfo()
        await mockProvider.reset()

        let status = await mockProvider.mockATTStatus
        let operations = await mockProvider.operations

        #expect(status == .notDetermined)
        #expect(operations.isEmpty)
    }

    @Test("Mock provider counts operations correctly")
    func mockCountsOperations() async {
        let mockProvider = MockDeviceInfoProvider()

        _ = await mockProvider.collectDeviceInfo()
        _ = await mockProvider.collectDeviceInfo()
        _ = await mockProvider.collectDeviceInfo()

        let count = await mockProvider.operationCount(.collectDeviceInfo)
        #expect(count == 3)
    }

    @Test("Mock provider currentDeviceInfo tracks operation")
    func mockCurrentDeviceInfoTracksOperation() async {
        let mockProvider = MockDeviceInfoProvider()

        _ = await mockProvider.currentDeviceInfo

        let hasOperation = await mockProvider.hasOperation(.getCurrentDeviceInfo)
        #expect(hasOperation)
    }

    // MARK: - Custom DeviceInfo Tests

    @Test("Mock provider can be initialized with custom device info")
    func mockWithCustomDeviceInfo() async {
        let customDeviceInfo = DeviceInfo(
            hardwareId: "custom-id",
            hardwareIdType: .idfa,
            isRealHardwareId: true,
            vendorId: nil,
            advertiserId: "custom-idfa",
            anonId: "custom-anon",
            attAuthorizationStatus: .authorized,
            isFirstOptIn: true,
            brandName: "Apple",
            modelName: "iPad13,4",
            osName: "iPadOS",
            osVersion: "17.1.0",
            osBuildVersion: nil,
            cpuType: nil,
            environment: "FULL_APP",
            screenWidth: 1024,
            screenHeight: 768,
            screenScale: 2.0,
            locale: "fr_FR",
            country: "FR",
            language: "fr",
            timezone: "Europe/Paris",
            applicationVersion: "2.0.0",
            branchSDKVersion: "ios4.0.0-alpha",
            pluginName: nil,
            pluginVersion: nil,
            isSimulator: false
        )

        let mockProvider = MockDeviceInfoProvider(deviceInfo: customDeviceInfo)
        let deviceInfo = await mockProvider.collectDeviceInfo()

        #expect(deviceInfo.hardwareId == "custom-id")
        #expect(deviceInfo.hardwareIdType == .idfa)
        #expect(deviceInfo.modelName == "iPad13,4")
        #expect(deviceInfo.osName == "iPadOS")
        #expect(deviceInfo.locale == "fr_FR")
    }

    @Test("Mock provider setDeviceInfo updates the returned device info")
    func mockSetDeviceInfoUpdates() async {
        let mockProvider = MockDeviceInfoProvider()

        let newDeviceInfo = DeviceInfo(
            hardwareId: "updated-id",
            hardwareIdType: .random,
            isRealHardwareId: false,
            vendorId: nil,
            advertiserId: nil,
            anonId: "new-anon",
            attAuthorizationStatus: .denied,
            isFirstOptIn: false,
            brandName: "Apple",
            modelName: "AppleTV11,1",
            osName: "tvOS",
            osVersion: "17.0.0",
            osBuildVersion: nil,
            cpuType: nil,
            environment: "FULL_APP",
            screenWidth: 1920,
            screenHeight: 1080,
            screenScale: 1.0,
            locale: "en_GB",
            country: "GB",
            language: "en",
            timezone: "Europe/London",
            applicationVersion: nil,
            branchSDKVersion: "ios4.0.0-alpha",
            pluginName: nil,
            pluginVersion: nil,
            isSimulator: false
        )

        await mockProvider.setDeviceInfo(newDeviceInfo)
        let deviceInfo = await mockProvider.collectDeviceInfo()

        #expect(deviceInfo.hardwareId == "updated-id")
        #expect(deviceInfo.modelName == "AppleTV11,1")
        #expect(deviceInfo.osName == "tvOS")
    }
}

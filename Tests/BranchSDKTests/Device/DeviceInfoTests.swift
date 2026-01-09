//
//  DeviceInfoTests.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

@testable import BranchSDK
import Foundation
import Testing

@Suite("DeviceInfo Model Tests")
struct DeviceInfoTests {
    // MARK: Internal

    // MARK: - Initialization Tests

    @Test("DeviceInfo initializes with all properties")
    func initializationWithAllProperties() {
        let collectedAt = Date()

        let deviceInfo = DeviceInfo(
            hardwareId: "test-hardware-id",
            hardwareIdType: .vendorId,
            isRealHardwareId: true,
            vendorId: "vendor-123",
            advertiserId: nil,
            anonId: "anon-456",
            attAuthorizationStatus: .notDetermined,
            isFirstOptIn: false,
            brandName: "Apple",
            modelName: "iPhone15,2",
            osName: "iOS",
            osVersion: "17.0.0",
            osBuildVersion: "21A329",
            cpuType: "16777228",
            environment: "FULL_APP",
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
            isSimulator: false,
            collectedAt: collectedAt
        )

        #expect(deviceInfo.hardwareId == "test-hardware-id")
        #expect(deviceInfo.hardwareIdType == .vendorId)
        #expect(deviceInfo.isRealHardwareId == true)
        #expect(deviceInfo.vendorId == "vendor-123")
        #expect(deviceInfo.advertiserId == nil)
        #expect(deviceInfo.anonId == "anon-456")
        #expect(deviceInfo.attAuthorizationStatus == .notDetermined)
        #expect(deviceInfo.isFirstOptIn == false)
        #expect(deviceInfo.brandName == "Apple")
        #expect(deviceInfo.modelName == "iPhone15,2")
        #expect(deviceInfo.osName == "iOS")
        #expect(deviceInfo.osVersion == "17.0.0")
        #expect(deviceInfo.screenWidth == 390)
        #expect(deviceInfo.screenHeight == 844)
        #expect(deviceInfo.screenScale == 3.0)
        #expect(deviceInfo.collectedAt == collectedAt)
    }

    // MARK: - Screen DPI Tests

    @Test("screenDPI calculates correctly for 2x scale")
    func screenDPI2x() {
        let deviceInfo = createDeviceInfo(screenScale: 2.0)
        #expect(deviceInfo.screenDPI == 320)
    }

    @Test("screenDPI calculates correctly for 3x scale")
    func screenDPI3x() {
        let deviceInfo = createDeviceInfo(screenScale: 3.0)
        #expect(deviceInfo.screenDPI == 480)
    }

    // MARK: - Hardware ID Type Tests

    @Test("HardwareIdType has correct raw values")
    func hardwareIdTypeRawValues() {
        #expect(HardwareIdType.idfa.rawValue == "idfa")
        #expect(HardwareIdType.vendorId.rawValue == "vendor_id")
        #expect(HardwareIdType.random.rawValue == "random")
    }

    // MARK: - ATT Status Tests

    @Test("ATTAuthorizationStatus has correct raw values")
    func attStatusRawValues() {
        #expect(ATTAuthorizationStatus.notDetermined.rawValue == "not_determined")
        #expect(ATTAuthorizationStatus.restricted.rawValue == "restricted")
        #expect(ATTAuthorizationStatus.denied.rawValue == "denied")
        #expect(ATTAuthorizationStatus.authorized.rawValue == "authorized")
        #expect(ATTAuthorizationStatus.unavailable.rawValue == "unavailable")
    }

    // MARK: - Dictionary Representation Tests

    @Test("asDictionary includes required fields")
    func dictionaryRequiredFields() {
        let deviceInfo = createDeviceInfo()
        let dict = deviceInfo.asDictionary

        #expect(dict["hardware_id"] as? String == "test-hardware-id")
        #expect(dict["hardware_id_type"] as? String == "vendor_id")
        #expect(dict["is_hardware_id_real"] as? Bool == true)
        #expect(dict["anon_id"] as? String == "anon-456")
        #expect(dict["brand"] as? String == "Apple")
        #expect(dict["model"] as? String == "iPhone15,2")
        #expect(dict["os"] as? String == "iOS")
        #expect(dict["os_version"] as? String == "17.0.0")
        #expect(dict["sdk_version"] as? String == "ios4.0.0-alpha")
    }

    @Test("asDictionary includes optional fields when present")
    func dictionaryOptionalFieldsPresent() {
        let deviceInfo = createDeviceInfo(
            vendorId: "vendor-123",
            advertiserId: "idfa-789",
            osBuildVersion: "21A329",
            cpuType: "16777228",
            country: "US",
            language: "en",
            applicationVersion: "2.0.0",
            pluginName: "Flutter",
            pluginVersion: "1.5.0"
        )
        let dict = deviceInfo.asDictionary

        #expect(dict["idfv"] as? String == "vendor-123")
        #expect(dict["idfa"] as? String == "idfa-789")
        #expect(dict["os_build"] as? String == "21A329")
        #expect(dict["cpu_type"] as? String == "16777228")
        #expect(dict["country"] as? String == "US")
        #expect(dict["language"] as? String == "en")
        #expect(dict["app_version"] as? String == "2.0.0")
        #expect(dict["plugin_name"] as? String == "Flutter")
        #expect(dict["plugin_version"] as? String == "1.5.0")
    }

    @Test("asDictionary excludes nil optional fields")
    func dictionaryExcludesNilFields() {
        let deviceInfo = createDeviceInfo(
            vendorId: nil,
            advertiserId: nil,
            pluginName: nil,
            pluginVersion: nil
        )
        let dict = deviceInfo.asDictionary

        #expect(dict["idfv"] == nil)
        #expect(dict["idfa"] == nil)
        #expect(dict["plugin_name"] == nil)
        #expect(dict["plugin_version"] == nil)
    }

    @Test("asDictionary includes first_opt_in only when true")
    func dictionaryFirstOptIn() {
        let deviceInfoOptedIn = createDeviceInfo(isFirstOptIn: true)
        let dictOptedIn = deviceInfoOptedIn.asDictionary
        #expect(dictOptedIn["first_opt_in"] as? Bool == true)

        let deviceInfoNotOptedIn = createDeviceInfo(isFirstOptIn: false)
        let dictNotOptedIn = deviceInfoNotOptedIn.asDictionary
        #expect(dictNotOptedIn["first_opt_in"] == nil)
    }

    // MARK: - Codable Tests

    @Test("DeviceInfo encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = createDeviceInfo()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(DeviceInfo.self, from: data)

        #expect(decoded == original)
    }

    @Test("HardwareIdType encodes and decodes correctly")
    func hardwareIdTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in [HardwareIdType.idfa, .vendorId, .random] {
            let data = try encoder.encode(type)
            let decoded = try decoder.decode(HardwareIdType.self, from: data)
            #expect(decoded == type)
        }
    }

    @Test("ATTAuthorizationStatus encodes and decodes correctly")
    func attStatusCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in [ATTAuthorizationStatus.notDetermined, .restricted, .denied, .authorized, .unavailable] {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(ATTAuthorizationStatus.self, from: data)
            #expect(decoded == status)
        }
    }

    // MARK: - Equatable Tests

    @Test("DeviceInfo equality works correctly")
    func equatable() {
        let deviceInfo1 = createDeviceInfo()
        let deviceInfo2 = createDeviceInfo()
        let deviceInfo3 = createDeviceInfo(hardwareId: "different-id")

        #expect(deviceInfo1 == deviceInfo2)
        #expect(deviceInfo1 != deviceInfo3)
    }

    // MARK: - Sendable Tests

    @Test("DeviceInfo can be passed across concurrency boundaries")
    func sendable() async {
        let deviceInfo = createDeviceInfo()

        let task = Task.detached { () -> DeviceInfo in
            deviceInfo
        }

        let result = await task.value
        #expect(result == deviceInfo)
    }

    // MARK: Private

    // MARK: - Helper Methods

    private func createDeviceInfo(
        hardwareId: String = "test-hardware-id",
        hardwareIdType: HardwareIdType = .vendorId,
        isRealHardwareId: Bool = true,
        vendorId: String? = "vendor-123",
        advertiserId: String? = nil,
        anonId: String = "anon-456",
        attAuthorizationStatus: ATTAuthorizationStatus = .notDetermined,
        isFirstOptIn: Bool = false,
        brandName: String = "Apple",
        modelName: String = "iPhone15,2",
        osName: String = "iOS",
        osVersion: String = "17.0.0",
        osBuildVersion: String? = "21A329",
        cpuType: String? = "16777228",
        environment: String = "FULL_APP",
        screenWidth: Int = 390,
        screenHeight: Int = 844,
        screenScale: Double = 3.0,
        locale: String = "en_US",
        country: String? = "US",
        language: String? = "en",
        timezone: String = "America/Los_Angeles",
        applicationVersion: String? = "1.0.0",
        branchSDKVersion: String = "ios4.0.0-alpha",
        pluginName: String? = nil,
        pluginVersion: String? = nil,
        isSimulator: Bool = false,
        collectedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> DeviceInfo {
        DeviceInfo(
            hardwareId: hardwareId,
            hardwareIdType: hardwareIdType,
            isRealHardwareId: isRealHardwareId,
            vendorId: vendorId,
            advertiserId: advertiserId,
            anonId: anonId,
            attAuthorizationStatus: attAuthorizationStatus,
            isFirstOptIn: isFirstOptIn,
            brandName: brandName,
            modelName: modelName,
            osName: osName,
            osVersion: osVersion,
            osBuildVersion: osBuildVersion,
            cpuType: cpuType,
            environment: environment,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            screenScale: screenScale,
            locale: locale,
            country: country,
            language: language,
            timezone: timezone,
            applicationVersion: applicationVersion,
            branchSDKVersion: branchSDKVersion,
            pluginName: pluginName,
            pluginVersion: pluginVersion,
            isSimulator: isSimulator,
            collectedAt: collectedAt
        )
    }
}

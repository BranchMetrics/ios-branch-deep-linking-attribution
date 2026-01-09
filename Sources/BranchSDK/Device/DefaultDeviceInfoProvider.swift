//
//  DefaultDeviceInfoProvider.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

#if canImport(AdSupport)
import AdSupport
#endif

// MARK: - DefaultDeviceInfoProvider

/// Default implementation of DeviceInfoProvider.
///
/// Collects device information using system APIs and caches the result
/// for efficient access.
///
/// ## Thread Safety
///
/// This type is implemented as an actor to ensure thread-safe access
/// to cached device information.
public actor DefaultDeviceInfoProvider: DeviceInfoProvider {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(storage: any StorageProvider) {
        self.storage = storage
    }

    // MARK: Public

    // MARK: - DeviceInfoProvider

    public var currentDeviceInfo: DeviceInfo {
        get async {
            if let cached = cachedDeviceInfo {
                return cached
            }
            return await collectDeviceInfo()
        }
    }

    public func collectDeviceInfo() async -> DeviceInfo {
        let hardwareInfo = await collectHardwareIds()
        let attStatus = await checkATTStatus()

        let deviceInfo = await DeviceInfo(
            hardwareId: hardwareInfo.hardwareId,
            hardwareIdType: hardwareInfo.hardwareIdType,
            isRealHardwareId: hardwareInfo.isRealHardwareId,
            vendorId: collectVendorId(),
            advertiserId: hardwareInfo.advertiserId,
            anonId: loadOrCreateAnonId(),
            attAuthorizationStatus: attStatus,
            isFirstOptIn: checkFirstOptIn(status: attStatus),
            brandName: collectBrandName(),
            modelName: collectModelName(),
            osName: collectOSName(),
            osVersion: collectOSVersion(),
            osBuildVersion: collectOSBuildVersion(),
            cpuType: collectCPUType(),
            environment: collectEnvironment(),
            screenWidth: collectScreenWidth(),
            screenHeight: collectScreenHeight(),
            screenScale: collectScreenScale(),
            locale: collectLocale(),
            country: collectCountry(),
            language: collectLanguage(),
            timezone: collectTimezone(),
            applicationVersion: collectApplicationVersion(),
            branchSDKVersion: collectSDKVersion(),
            pluginName: registeredPluginName,
            pluginVersion: registeredPluginVersion,
            isSimulator: isRunningOnSimulator()
        )

        cachedDeviceInfo = deviceInfo
        return deviceInfo
    }

    public func refreshHardwareId() async -> DeviceInfo {
        // Invalidate cache and recollect
        cachedDeviceInfo = nil
        return await collectDeviceInfo()
    }

    public func checkATTStatus() async -> ATTAuthorizationStatus {
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            switch status {
            case .notDetermined:
                return .notDetermined

            case .restricted:
                return .restricted

            case .denied:
                return .denied

            case .authorized:
                return .authorized

            @unknown default:
                return .unavailable
            }
        }
        #endif
        return .unavailable
    }

    public func registerPlugin(name: String, version: String) {
        registeredPluginName = name
        registeredPluginVersion = version
        // Invalidate cache so next collection includes plugin info
        cachedDeviceInfo = nil
    }

    public func localIPAddress() async -> String? {
        // Implementation would use Network.framework or similar
        // For now, returning nil as this requires platform-specific code
        nil
    }

    public func connectionType() async -> String {
        // Would use NWPathMonitor to determine connection type
        "unknown"
    }

    public func userAgentString() async -> String {
        #if os(tvOS)
        // tvOS does not support WebKit
        return ""
        #else
        // Would need to collect from WKWebView
        // For now, return a default user agent
        return await collectUserAgent()
        #endif
    }

    // MARK: Private

    // MARK: - Storage Keys

    private static let anonIdKey = StorageKey(rawValue: "branch_anon_id")
    private static let hasOptedInBeforeKey = StorageKey(rawValue: "branch_has_opted_in_before")

    // MARK: - Dependencies

    private let storage: any StorageProvider

    // MARK: - Cached State

    private var cachedDeviceInfo: DeviceInfo?
    private var registeredPluginName: String?
    private var registeredPluginVersion: String?
    private var cachedUserAgent: String?

    // MARK: - Hardware ID Collection

    private func collectHardwareIds() async -> HardwareIdInfo {
        let advertiserId = collectAdvertiserId()
        let vendorId = collectVendorId()
        let randomId = UUID().uuidString

        if let advertiserId, !advertiserId.isEmpty {
            return HardwareIdInfo(
                hardwareId: advertiserId,
                hardwareIdType: .idfa,
                isRealHardwareId: true,
                advertiserId: advertiserId
            )
        } else if let vendorId, !vendorId.isEmpty {
            return HardwareIdInfo(
                hardwareId: vendorId,
                hardwareIdType: .vendorId,
                isRealHardwareId: true,
                advertiserId: nil
            )
        } else {
            return HardwareIdInfo(
                hardwareId: randomId,
                hardwareIdType: .random,
                isRealHardwareId: false,
                advertiserId: nil
            )
        }
    }

    private func collectAdvertiserId() -> String? {
        #if canImport(AdSupport)
        let manager = ASIdentifierManager.shared()

        // Check if advertising tracking is enabled
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
                return nil
            }
        }
        #endif

        let idfa = manager.advertisingIdentifier.uuidString

        // Check for zeroed out IDFA (tracking not allowed)
        guard idfa != "00000000-0000-0000-0000-000000000000" else {
            return nil
        }

        return idfa
        #else
        return nil
        #endif
    }

    private nonisolated func collectVendorId() -> String? {
        #if canImport(UIKit) && !os(watchOS)
        return UIDevice.current.identifierForVendor?.uuidString
        #else
        return nil
        #endif
    }

    // MARK: - Anonymous ID

    private func loadOrCreateAnonId() async -> String {
        if let existingId: String = await storage.get(forKey: Self.anonIdKey) {
            return existingId
        }

        let newId = UUID().uuidString
        await storage.set(newId, forKey: Self.anonIdKey)
        return newId
    }

    // MARK: - First Opt-In Check

    private func checkFirstOptIn(status: ATTAuthorizationStatus) async -> Bool {
        guard status == .authorized else {
            return false
        }

        let hasOptedInBefore: Bool = await storage.get(forKey: Self.hasOptedInBeforeKey) ?? false

        if !hasOptedInBefore {
            await storage.set(true, forKey: Self.hasOptedInBeforeKey)
            return true
        }

        return false
    }

    // MARK: - Device Information Collection

    private nonisolated func collectBrandName() -> String {
        "Apple"
    }

    private nonisolated func collectModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let model = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        return model.isEmpty ? "Unknown" : model
    }

    private nonisolated func collectOSName() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(visionOS)
        return "visionOS"
        #else
        return "Unknown"
        #endif
    }

    private nonisolated func collectOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private nonisolated func collectOSBuildVersion() -> String? {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)

        guard size > 0 else {
            return nil
        }

        var buildVersion = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &buildVersion, &size, nil, 0)

        // Convert to UInt8 array and decode as UTF-8
        let uint8Array = buildVersion.map { UInt8(bitPattern: $0) }
        return String(decoding: uint8Array.prefix { $0 != 0 }, as: UTF8.self)
    }

    private nonisolated func collectCPUType() -> String? {
        var type: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.cputype", &type, &size, nil, 0)

        return String(type)
    }

    private nonisolated func collectEnvironment() -> String {
        #if targetEnvironment(simulator)
        return "SIMULATOR"
        #else
        if isAppClip() {
            return "APP_CLIP"
        }
        return "FULL_APP"
        #endif
    }

    private nonisolated func isAppClip() -> Bool {
        // Check if running as App Clip by examining bundle
        guard let bundlePath = Bundle.main.bundlePath as NSString? else {
            return false
        }
        return bundlePath.pathExtension == "appex"
    }

    // MARK: - Screen Information

    private nonisolated func collectScreenWidth() -> Int {
        #if canImport(UIKit) && !os(watchOS)
        return Int(UIScreen.main.bounds.width)
        #else
        return 0
        #endif
    }

    private nonisolated func collectScreenHeight() -> Int {
        #if canImport(UIKit) && !os(watchOS)
        return Int(UIScreen.main.bounds.height)
        #else
        return 0
        #endif
    }

    private nonisolated func collectScreenScale() -> Double {
        #if canImport(UIKit) && !os(watchOS)
        return Double(UIScreen.main.scale)
        #else
        return 1.0
        #endif
    }

    // MARK: - Locale Information

    private nonisolated func collectLocale() -> String {
        Locale.current.identifier
    }

    private nonisolated func collectCountry() -> String? {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *) {
            Locale.current.region?.identifier
        } else {
            Locale.current.regionCode
        }
    }

    private nonisolated func collectLanguage() -> String? {
        if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1, *) {
            Locale.current.language.languageCode?.identifier
        } else {
            Locale.current.languageCode
        }
    }

    private nonisolated func collectTimezone() -> String {
        TimeZone.current.identifier
    }

    // MARK: - App Information

    private nonisolated func collectApplicationVersion() -> String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private nonisolated func collectSDKVersion() -> String {
        "ios4.0.0-alpha"
    }

    // MARK: - Runtime Information

    private nonisolated func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - User Agent

    private func collectUserAgent() async -> String {
        if let cached = cachedUserAgent {
            return cached
        }

        // Default user agent when WebKit is not available
        let defaultUA = "Mozilla/5.0 (iPhone; CPU iPhone OS \(collectOSVersion().replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

        cachedUserAgent = defaultUA
        return defaultUA
    }
}

// MARK: - HardwareIdInfo

/// Internal helper struct for hardware ID collection results
private struct HardwareIdInfo {
    let hardwareId: String
    let hardwareIdType: HardwareIdType
    let isRealHardwareId: Bool
    let advertiserId: String?
}

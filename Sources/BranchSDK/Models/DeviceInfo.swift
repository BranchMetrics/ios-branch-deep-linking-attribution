//
//  DeviceInfo.swift
//  Branch iOS SDK - Modern Swift Implementation
//
//  Copyright © 2026 Branch Metrics. All rights reserved.
//  SPDX-License-Identifier: MIT
//

import Foundation

// MARK: - DeviceInfo

/// Immutable container for device information.
///
/// This struct holds all device-related data collected by the SDK,
/// including hardware identifiers, OS information, screen dimensions,
/// and locale settings.
///
/// ## Thread Safety
///
/// `DeviceInfo` is `Sendable` and safe to pass across concurrency domains.
public struct DeviceInfo: Codable, Sendable, Equatable {
    // MARK: Lifecycle

    // MARK: - Initialization

    public init(
        hardwareId: String,
        hardwareIdType: HardwareIdType,
        isRealHardwareId: Bool,
        vendorId: String?,
        advertiserId: String?,
        anonId: String,
        attAuthorizationStatus: ATTAuthorizationStatus,
        isFirstOptIn: Bool,
        brandName: String,
        modelName: String,
        osName: String,
        osVersion: String,
        osBuildVersion: String?,
        cpuType: String?,
        environment: String,
        screenWidth: Int,
        screenHeight: Int,
        screenScale: Double,
        locale: String,
        country: String?,
        language: String?,
        timezone: String,
        applicationVersion: String?,
        branchSDKVersion: String,
        pluginName: String?,
        pluginVersion: String?,
        isSimulator: Bool,
        collectedAt: Date = Date()
    ) {
        self.hardwareId = hardwareId
        self.hardwareIdType = hardwareIdType
        self.isRealHardwareId = isRealHardwareId
        self.vendorId = vendorId
        self.advertiserId = advertiserId
        self.anonId = anonId
        self.attAuthorizationStatus = attAuthorizationStatus
        self.isFirstOptIn = isFirstOptIn
        self.brandName = brandName
        self.modelName = modelName
        self.osName = osName
        self.osVersion = osVersion
        self.osBuildVersion = osBuildVersion
        self.cpuType = cpuType
        self.environment = environment
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.screenScale = screenScale
        self.locale = locale
        self.country = country
        self.language = language
        self.timezone = timezone
        self.applicationVersion = applicationVersion
        self.branchSDKVersion = branchSDKVersion
        self.pluginName = pluginName
        self.pluginVersion = pluginVersion
        self.isSimulator = isSimulator
        self.collectedAt = collectedAt
    }

    // MARK: Public

    // MARK: - Hardware Identifiers

    /// The primary hardware identifier (IDFA, Vendor ID, or random UUID)
    public let hardwareId: String

    /// The type of hardware identifier ("idfa", "vendor_id", or "random")
    public let hardwareIdType: HardwareIdType

    /// Whether the hardware ID is a real device identifier (not random)
    public let isRealHardwareId: Bool

    /// The vendor identifier (IDFV)
    public let vendorId: String?

    /// The advertising identifier (IDFA), if available
    public let advertiserId: String?

    /// Anonymous identifier for the device (persisted across sessions)
    public let anonId: String

    // MARK: - ATT Status

    /// App Tracking Transparency authorization status
    public let attAuthorizationStatus: ATTAuthorizationStatus

    /// Whether this is the first time the user has opted in
    public let isFirstOptIn: Bool

    // MARK: - Device Information

    /// Device brand (e.g., "Apple")
    public let brandName: String

    /// Device model (e.g., "iPhone15,2")
    public let modelName: String

    /// Operating system name (e.g., "iOS")
    public let osName: String

    /// Operating system version (e.g., "17.0")
    public let osVersion: String

    /// Operating system build version
    public let osBuildVersion: String?

    /// CPU architecture type
    public let cpuType: String?

    /// Runtime environment (e.g., "FULL_APP", "APP_CLIP")
    public let environment: String

    // MARK: - Screen Information

    /// Screen width in points
    public let screenWidth: Int

    /// Screen height in points
    public let screenHeight: Int

    /// Screen scale factor (e.g., 2.0 for Retina, 3.0 for Super Retina)
    public let screenScale: Double

    // MARK: - Locale Information

    /// Full locale identifier (e.g., "en_US")
    public let locale: String

    /// ISO country code (e.g., "US")
    public let country: String?

    /// ISO language code (e.g., "en")
    public let language: String?

    /// Device timezone identifier
    public let timezone: String

    // MARK: - App Information

    /// Application version string
    public let applicationVersion: String?

    /// Branch SDK version string
    public let branchSDKVersion: String

    // MARK: - Plugin Information

    /// Name of the plugin using the SDK (e.g., "React Native", "Flutter")
    public let pluginName: String?

    /// Version of the plugin
    public let pluginVersion: String?

    // MARK: - Runtime Information

    /// Whether the app is running in a simulator
    public let isSimulator: Bool

    /// Timestamp when this info was collected
    public let collectedAt: Date

    /// Screen DPI (dots per inch)
    public var screenDPI: Int {
        Int(Double(screenScale) * 160.0)
    }
}

// MARK: - HardwareIdType

/// Type of hardware identifier being used
public enum HardwareIdType: String, Codable, Sendable {
    /// IDFA (Identifier for Advertisers) - requires ATT authorization
    case idfa

    /// IDFV (Identifier for Vendor) - always available
    case vendorId = "vendor_id"

    /// Random UUID - fallback when no real identifier is available
    case random
}

// MARK: - ATTAuthorizationStatus

/// App Tracking Transparency authorization status
public enum ATTAuthorizationStatus: String, Codable, Sendable {
    /// User has not yet been prompted
    case notDetermined = "not_determined"

    /// Tracking is restricted (e.g., parental controls)
    case restricted

    /// User denied tracking permission
    case denied

    /// User authorized tracking
    case authorized

    /// ATT is not available (iOS < 14.5 or tvOS)
    case unavailable
}

// MARK: - DeviceInfo Extensions

public extension DeviceInfo {
    /// Creates a dictionary representation suitable for API requests
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "hardware_id": hardwareId,
            "hardware_id_type": hardwareIdType.rawValue,
            "is_hardware_id_real": isRealHardwareId,
            "anon_id": anonId,
            "opted_in_status": attAuthorizationStatus.rawValue,
            "brand": brandName,
            "model": modelName,
            "os": osName,
            "os_version": osVersion,
            "environment": environment,
            "screen_width": screenWidth,
            "screen_height": screenHeight,
            "screen_dpi": screenDPI,
            "locale": locale,
            "timezone": timezone,
            "sdk_version": branchSDKVersion,
            "is_simulator": isSimulator,
        ]

        if let vendorId {
            dict["idfv"] = vendorId
        }
        if let advertiserId {
            dict["idfa"] = advertiserId
        }
        if let osBuildVersion {
            dict["os_build"] = osBuildVersion
        }
        if let cpuType {
            dict["cpu_type"] = cpuType
        }
        if let country {
            dict["country"] = country
        }
        if let language {
            dict["language"] = language
        }
        if let applicationVersion {
            dict["app_version"] = applicationVersion
        }
        if let pluginName {
            dict["plugin_name"] = pluginName
        }
        if let pluginVersion {
            dict["plugin_version"] = pluginVersion
        }
        if isFirstOptIn {
            dict["first_opt_in"] = true
        }

        return dict
    }
}

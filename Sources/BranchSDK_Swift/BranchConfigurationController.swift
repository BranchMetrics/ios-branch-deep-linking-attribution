//
//  BranchConfigurationController.swift
//  BranchSDK
//
//  Swift port of the former Objective-C BranchConfigurationController.
//
//  The @objc(BranchConfigurationController) attribute and the sharedInstance selector are
//  pinned so existing Objective-C call sites and unit tests keep working unchanged.
//

import Foundation

#if SWIFT_PACKAGE
import BranchObjCSDK
#endif

/// The `BranchConfigurationController` class contains SDK configuration information.
/// This information is sent to the backend as `operational_metrics` with the v1/install request.
@objc(BranchConfigurationController)
public class BranchConfigurationController: NSObject {

    // MARK: - Properties

    @objc public var branchKeySource: String?
    @objc public var deferInitForPluginRuntime: Bool = false
    @objc public var checkPasteboardOnInstall: Bool = false

    // MARK: - Singleton

    private static let _sharedInstance = BranchConfigurationController()

    @objc(sharedInstance)
    public class func sharedInstance() -> BranchConfigurationController {
        return _sharedInstance
    }

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    /// Retrieves the current SDK configuration as a dictionary.
    @objc public func getConfiguration() -> [String: Any] {
        var config: [String: Any] = [:]
        config.merge(branchKeyInfo()) { _, new in new }
        config.merge(featureFlagsInfo()) { _, new in new }
        config.merge(frameworkIntegrationInfo()) { _, new in new }
        return config
    }

    // MARK: - Private helpers

    private func branchKeyInfo() -> [String: String] {
        return [
            BRANCH_REQUEST_KEY_BRANCH_KEY_SOURCE: branchKeySource ?? "Unknown"
        ]
    }

    private func featureFlagsInfo() -> [String: Bool] {
        return [
            BRANCH_REQUEST_KEY_CHECK_PASTEBOARD_ON_INSTALL: checkPasteboardOnInstall,
            BRANCH_REQUEST_KEY_DEFER_INIT_FOR_PLUGIN_RUNTIME: deferInitForPluginRuntime
        ]
    }

    private func frameworkIntegrationInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        info[BRANCH_REQUEST_KEY_LINKED_FRAMEORKS] = [
            FRAMEWORK_AD_SUPPORT: isClassAvailable("ASIdentifierManager"),
            FRAMEWORK_ATT_TRACKING_MANAGER: isClassAvailable("ATTrackingManager"),
            FRAMEWORK_AD_FIREBASE_CRASHLYTICS: isClassAvailable("FIRCrashlytics"),
            FRAMEWORK_AD_SAFARI_SERVICES: isClassAvailable("SFSafariViewController"),
            FRAMEWORK_AD_APP_ADS_ONDEVICE_CONVERSION: isClassAvailable("ODCConversionManager")
        ]
        return info
    }

    private func isClassAvailable(_ className: String) -> Bool {
        return NSClassFromString(className) != nil
    }
}

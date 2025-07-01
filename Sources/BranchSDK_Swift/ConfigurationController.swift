//
//  ConfigurationController.swift
//  BranchSDK
//
//  Created by Nidhi Dixit on 6/17/25.
//


import Foundation

#if SWIFT_PACKAGE
import BranchConstantsTarget
#endif

@objcMembers
public class ConfigurationController: NSObject {

    // MARK: - Properties
    public var branchKeySource: String?
    public var deferInitForPluginRuntime: Bool = false
    public var checkPasteboardOnInstall: Bool = false

    // MARK: - Singleton
     @MainActor public static let shared = ConfigurationController()

    private override init() {
        // Private initializer to enforce singleton usage.
        super.init()
    }

    public func getConfiguration() -> [String: Any] {
        var config: [String: Any] = [:]
        
        config.merge(branchKeyInfo()) { (_, new) in new }
        config.merge(featureFlagsInfo()) { (_, new) in new }
        config.merge(frameworkIntegrationInfo()) { (_, new) in new }
        
        return config
    }

    // MARK: - Private Helper Methods
    private func branchKeyInfo() -> [String: String] {
        return [
            BRANCH_REQUEST_KEY_BRANCH_KEY_SOURCE: self.branchKeySource ?? "Unknown"
        ]
    }

    private func featureFlagsInfo() -> [String: Bool] {
        return [
            BRANCH_REQUEST_KEY_CHECK_PASTEBOARD_ON_INSTALL: self.checkPasteboardOnInstall,
            BRANCH_REQUEST_KEY_DEFER_INIT_FOR_PLUGIN_RUNTIME: self.deferInitForPluginRuntime
        ]
    }

    private func frameworkIntegrationInfo() -> [String: Any] {
        var info: [String: Any] = [:]

        let linkedFrameworks: [String: Bool] = [
            FRAMEWORK_AD_SUPPORT: isClassAvailable(className: "ASIdentifierManager"),
            FRAMEWORK_ATT_TRACKING_MANAGER: isClassAvailable(className: "ATTrackingManager"),
            FRAMEWORK_AD_FIREBASE_CRASHLYTICS: isClassAvailable(className: "FIRCrashlytics"),
            FRAMEWORK_AD_SAFARI_SERVICES: isClassAvailable(className: "SFSafariViewController"),
            FRAMEWORK_AD_APP_ADS_ONDEVICE_CONVERSION: isClassAvailable(className: "ODCConversionManager")
        ]
        
        info[BRANCH_REQUEST_KEY_LINKED_FRAMEORKS] = linkedFrameworks
        
        return info
    }

    private func isClassAvailable(className: String) -> Bool {
        return NSClassFromString(className) != nil
    }
}

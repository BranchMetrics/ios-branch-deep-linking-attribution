//
//  IntegratedSDKsData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct IntegratedSDKsData {

    static let userDefaults = UserDefaults.standard
    
    // MARK - Adjust
    
    static func activeAdjustKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAdjustKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "adjust_api_key") as! String
            userDefaults.setValue(value, forKey: "activeAdjustKey")
            return value
        }
    }
    
    static func setActiveAdjustKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAdjustKey")
    }
    
    static func pendingAdjustKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdjustKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "adjust_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingAdjustKey")
            return value
        }
    }
    
    static func setPendingAdjustKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAdjustKey")
    }
    
    static func activeAdjustEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAdjustEnabled")
    }
    
    static func setActiveAdjustEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAdjustEnabled")
    }
    
    static func pendingAdjustEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAdjustEnabled")
    }
    
    static func setPendingAdjustEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAdjustEnabled")
    }
    
    // MARK - Adobe
    
    static func activeAdobeKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAdobeKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as! String
            userDefaults.setValue(value, forKey: "activeAdobeKey")
            return value
        }
    }
    
    static func setActiveAdobeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAdobeKey")
    }
    
    static func pendingAdobeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdobeKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingAdobeKey")
            return value
        }
    }
    
    static func setPendingAdobeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAdobeKey")
    }
    
    static func activeAdobeEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAdobeEnabled")
    }
    
    static func setActiveAdobeEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAdobeEnabled")
    }
    
    static func pendingAdobeEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAdobeEnabled")
    }
    
    static func setPendingAdobeEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAdobeEnabled")
    }
    
    // Amplitude
    
    static func activeAmplitudeKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAmplitudeKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as! String
            userDefaults.setValue(value, forKey: "activeAmplitudeKey")
            return value
        }
    }
    
    static func setActiveAmplitudeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAmplitudeKey")
    }
    
    static func pendingAmplitudeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAmplitudeKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingAmplitudeKey")
            return value
        }
    }
    
    static func setPendingAmplitudeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAmplitudeKey")
    }
    
    static func activeAmplitudeEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAmplitudeEnabled")
    }
    
    static func setActiveAmplitudeEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAmplitudeEnabled")
    }
    
    static func pendingAmplitudeEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAmplitudeEnabled")
    }
    
    static func setPendingAmplitudeEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAmplitudeEnabled")
    }
    
    // Mark - Appsflyer
    
    static func activeAppsflyerKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAppsflyerKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as! String
            userDefaults.setValue(value, forKey: "activeAppsflyerKey")
            return value
        }
    }
    
    static func setActiveAppsflyerKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppsflyerKey")
    }
    
    static func pendingAppsflyerKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAppsflyerKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingAppsflyerKey")
            return value
        }
    }
    
    static func setPendingAppsflyerKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAppsflyerKey")
    }
    
    static func activeAppsflyerEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAppsflyerEnabled")
    }
    
    static func setActiveAppsflyerEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAppsflyerEnabled")
    }
    
    static func pendingAppsflyerEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAppsflyerEnabled")
    }
    
    static func setPendingAppsflyerEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAppsflyerEnabled")
    }
    
    // Mark - Mixpanel
    
    static func activeMixpanelKey() -> String? {
        if let value = userDefaults.string(forKey: "activeMixpanelKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as! String
            userDefaults.setValue(value, forKey: "activeMixpanelKey")
            return value
        }
    }
    
    static func setActiveMixpanelKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeMixpanelKey")
    }
    
    static func pendingMixpanelKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingMixpanelKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingMixpanelKey")
            return value
        }
    }
    
    static func setPendingMixpanelKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingMixpanelKey")
    }
    
    static func activeMixpanelEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeMixpanelEnabled")
    }
    
    static func setActiveMixpanelEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeMixpanelEnabled")
    }
    
    static func pendingMixpanelEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingMixpanelEnabled")
    }
    
    static func setPendingMixpanelEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingMixpanelEnabled")
    }
    
    // Mark - Tune
    
    static func activeTuneKey() -> String? {
        if let value = userDefaults.string(forKey: "activeTuneKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "tune_api_key") as! String
            userDefaults.setValue(value, forKey: "activeTuneKey")
            return value
        }
    }
    
    static func setActiveTuneKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeTuneKey")
    }
    
    static func pendingTuneKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingTuneKey") {
            return value
        } else {
            let value = Bundle.main.object(forInfoDictionaryKey: "tune_api_key") as! String
            userDefaults.setValue(value, forKey: "pendingTuneKey")
            return value
        }
    }
    
    static func setPendingTuneKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingTuneKey")
    }
    
    static func activeTuneEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeTuneEnabled")
    }
    
    static func setActiveTuneEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeTuneEnabled")
    }
    
    static func pendingTuneEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingTuneEnabled")
    }
    
    static func setPendingTuneEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingTuneEnabled")
    }
    
}

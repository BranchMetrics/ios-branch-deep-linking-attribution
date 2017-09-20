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
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "adjust_api_key") as! String
        userDefaults.setValue(value, forKey: "activeAdjustKey")
        return value
    }
    
    static func setActiveAdjustKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAdjustKey")
    }
    
    static func pendingAdjustKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdjustKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "adjust_api_key") as! String
        userDefaults.setValue(value, forKey: "pendingAdjustKey")
        return value
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
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as! String
        userDefaults.setValue(value, forKey: "activeAdobeKey")
        return value
    }
    
    static func setActiveAdobeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAdobeKey")
    }
    
    static func pendingAdobeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdobeKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as! String
        userDefaults.setValue(value, forKey: "pendingAdobeKey")
        return value
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
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as! String
        userDefaults.setValue(value, forKey: "activeAmplitudeKey")
        return value
    }
    
    static func setActiveAmplitudeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAmplitudeKey")
    }
    
    static func pendingAmplitudeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAmplitudeKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as! String
        userDefaults.setValue(value, forKey: "pendingAmplitudeKey")
        return value
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
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as! String
        userDefaults.setValue(value, forKey: "activeAppsflyerKey")
        return value
    }
    
    static func setActiveAppsflyerKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppsflyerKey")
    }
    
    static func pendingAppsflyerKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAppsflyerKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as! String
        userDefaults.setValue(value, forKey: "pendingAppsflyerKey")
        return value
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
    
    // Mark - Google Analytics
    
    static func activeGoogleAnalyticsTrackingID() -> String? {
        if let value = userDefaults.string(forKey: "activeGoogleAnalyticsTrackingID") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "google_analytics_tracking_id") as! String
        userDefaults.setValue(value, forKey: "activeGoogleAnalyticsTrackingID")
        return value
    }
    
    static func setActiveGoogleAnalyticsTrackingID(_ value: String) {
        userDefaults.setValue(value, forKey: "activeGoogleAnalyticsTrackingID")
    }
    
    static func pendingGoogleAnalyticsTrackingID() -> String? {
        if let value = userDefaults.string(forKey: "pendingGoogleAnalyticsTrackingID") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "google_analytics_tracking_id") as! String
        userDefaults.setValue(value, forKey: "pendingGoogleAnalyticsTrackingID")
        return value
    }
    
    static func setPendingGoogleAnalyticsTrackingID(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingGoogleAnalyticsTrackingID")
    }
    
    static func activeGoogleAnalyticsEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeGoogleAnalyticsEnabled")
    }
    
    static func setActiveGoogleAnalyticsEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeGoogleAnalyticsEnabled")
    }
    
    static func pendingGoogleAnalyticsEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingGoogleAnalyticsEnabled")
    }
    
    static func setPendingGoogleAnalyticsEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingGoogleAnalyticsEnabled")
    }
    
    // Mark - Mixpanel
    
    static func activeMixpanelKey() -> String? {
        if let value = userDefaults.string(forKey: "activeMixpanelKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as! String
        userDefaults.setValue(value, forKey: "activeMixpanelKey")
        return value
    }
    
    static func setActiveMixpanelKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeMixpanelKey")
    }
    
    static func pendingMixpanelKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingMixpanelKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as! String
        userDefaults.setValue(value, forKey: "pendingMixpanelKey")
        return value
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
    
    // AdvertisingID
    static func activeTuneAdvertisingID() -> String? {
        if let value = userDefaults.string(forKey: "activeTuneAdvertisingID") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "tune_advertising_id") as! String
        userDefaults.setValue(value, forKey: "activeTuneAdvertisingID")
        return value
    }
    
    static func setActiveTuneAdvertisingID(_ value: String) {
        userDefaults.setValue(value, forKey: "activeTuneAdvertisingID")
    }
    
    static func pendingTuneAdvertisingID() -> String? {
        if let value = userDefaults.string(forKey: "pendingTuneAdvertisingID") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "tune_advertising_id") as! String
        userDefaults.setValue(value, forKey: "pendingTuneAdvertisingID")
        return value
    }
    
    static func setPendingTuneAdvertisingID(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingTuneAdvertisingID")
    }
    
    // ConversionKey
    static func activeTuneConversionKey() -> String? {
        if let value = userDefaults.string(forKey: "activeTuneConversionKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "tune_conversion_key") as! String
        userDefaults.setValue(value, forKey: "activeTuneConversionKey")
        return value
    }
    
    static func setActiveTuneConversionKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeTuneConversionKey")
    }
    
    static func pendingTuneConversionKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingTuneConversionKey") {
            if value.characters.count > 0 {
                return value
            }
        }
        let value = Bundle.main.object(forInfoDictionaryKey: "tune_conversion_key") as! String
        userDefaults.setValue(value, forKey: "pendingTuneConversionKey")
        return value
    }
    
    static func setPendingTuneConversionKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingTuneConversionKey")
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

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
    
    static func activeAdjustAppToken() -> String? {
        if let value = userDefaults.string(forKey: "activeAppToken") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "adjust_app_token") as? String {
            userDefaults.setValue(value, forKey: "activeAppToken")
            return value
        }
        return nil
    }
    
    static func setActiveAdjustAppToken(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppToken")
    }
    
    static func pendingAdjustAppToken() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdjustAppToken") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "adjust_app_token") as? String {
            userDefaults.setValue(value, forKey: "pendingAdjustAppToken")
            return value
        }
        return nil
    }
    
    static func setPendingAdjustAppToken(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAdjustAppToken")
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeAdobeKey")
            return value
        }
        return nil
    }
    
    static func setActiveAdobeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAdobeKey")
    }
    
    static func pendingAdobeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAdobeKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "adobe_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingAdobeKey")
            return value
        }
        return nil
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as? String{
            userDefaults.setValue(value, forKey: "activeAmplitudeKey")
            return value
        }
        return nil
    }
    
    static func setActiveAmplitudeKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAmplitudeKey")
    }
    
    static func pendingAmplitudeKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAmplitudeKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "amplitude_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingAmplitudeKey")
            return value
        }
        return nil
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeAppsflyerKey")
            return value
        }
        return nil
    }
    
    static func setActiveAppsflyerKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppsflyerKey")
    }
    
    static func pendingAppsflyerKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAppsflyerKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appsflyer_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingAppsflyerKey")
            return value
        }
        return nil
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "google_analytics_tracking_id") as? String {
            userDefaults.setValue(value, forKey: "activeGoogleAnalyticsTrackingID")
            return value
        }
        return nil
    }
    
    static func setActiveGoogleAnalyticsTrackingID(_ value: String) {
        userDefaults.setValue(value, forKey: "activeGoogleAnalyticsTrackingID")
    }
    
    static func pendingGoogleAnalyticsTrackingID() -> String? {
        if let value = userDefaults.string(forKey: "pendingGoogleAnalyticsTrackingID") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "google_analytics_tracking_id") as? String {
            userDefaults.setValue(value, forKey: "pendingGoogleAnalyticsTrackingID")
            return value
        }
        return nil
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeMixpanelKey")
            return value
        }
        return nil
    }
    
    static func setActiveMixpanelKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeMixpanelKey")
    }
    
    static func pendingMixpanelKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingMixpanelKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mixpanel_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingMixpanelKey")
            return value
        }
        return nil
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
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "tune_advertising_id") as? String {
            userDefaults.setValue(value, forKey: "activeTuneAdvertisingID")
            return value
        }
        return nil
    }
    
    static func setActiveTuneAdvertisingID(_ value: String) {
        userDefaults.setValue(value, forKey: "activeTuneAdvertisingID")
    }
    
    static func pendingTuneAdvertisingID() -> String? {
        if let value = userDefaults.string(forKey: "pendingTuneAdvertisingID") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "tune_advertising_id") as? String {
            userDefaults.setValue(value, forKey: "pendingTuneAdvertisingID")
            return value
        }
        return nil
    }
    
    static func setPendingTuneAdvertisingID(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingTuneAdvertisingID")
    }
    
    // ConversionKey
    static func activeTuneConversionKey() -> String? {
        if let value = userDefaults.string(forKey: "activeTuneConversionKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "tune_conversion_key") as? String {
            userDefaults.setValue(value, forKey: "activeTuneConversionKey")
            return value
        }
        return nil
    }
    
    static func setActiveTuneConversionKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeTuneConversionKey")
    }
    
    static func pendingTuneConversionKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingTuneConversionKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "tune_conversion_key") as? String {
            userDefaults.setValue(value, forKey: "pendingTuneConversionKey")
            return value
        }
        return nil
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
    
    // Mark - Appboy
    
    static func activeAppboyAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAppboyAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appboy_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeAppboyAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveAppboyAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppboyAPIKey")
    }
    
    static func pendingAppboyAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAppboyAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appboy_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingAppboyAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingAppboyAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAppboyAPIKey")
    }
    
    static func activeAppboyEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAppboyEnabled")
    }
    
    static func setActiveAppboyEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAppboyEnabled")
    }
    
    static func pendingAppboyEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAppboyEnabled")
    }
    
    static func setPendingAppboyEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAppboyEnabled")
    }
    
    // Mark - AppMetrica
    
    static func activeAppMetricaAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeAppMetricaAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appmetrica_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeAppMetricaAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveAppMetricaAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeAppMetricaAPIKey")
    }
    
    static func pendingAppMetricaAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingAppMetricaAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "appmetrica_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingAppMetricaAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingAppMetricaAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingAppMetricaAPIKey")
    }
    
    static func activeAppMetricaEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeAppMetricaEnabled")
    }
    
    static func setActiveAppMetricaEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeAppMetricaEnabled")
    }
    
    static func pendingAppMetricaEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingAppMetricaEnabled")
    }
    
    static func setPendingAppMetricaEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingAppMetricaEnabled")
    }
    
    // Mark - ClearTap
    
    static func activeClearTapAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeClearTapAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "clevertap_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeClearTapAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveClearTapAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeClearTapAPIKey")
    }
    
    static func pendingClearTapAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingClearTapAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "clevertap_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingClearTapAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingClearTapAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingClearTapAPIKey")
    }
    
    static func activeClearTapEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeClearTapEnabled")
    }
    
    static func setActiveClearTapEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeClearTapEnabled")
    }
    
    static func pendingClearTapEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingClearTapEnabled")
    }
    
    static func setPendingClearTapEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingClearTapEnabled")
    }
    
    // Mark - Convertro
    
    static func activeConvertroAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeConvertroAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "convertro_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeConvertroAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveConvertroAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeConvertroAPIKey")
    }
    
    static func pendingConvertroAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingConvertroAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "convertro_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingConvertroAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingConvertroAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingConvertroAPIKey")
    }
    
    static func activeConvertroEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeConvertroEnabled")
    }
    
    static func setActiveConvertroEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeConvertroEnabled")
    }
    
    static func pendingConvertroEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingConvertroEnabled")
    }
    
    static func setPendingConvertroEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingConvertroEnabled")
    }
    
    // Mark - Kochava
    
    static func activeKochavaAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeKochavaAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "kochava_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeKochavaAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveKochavaAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeKochavaAPIKey")
    }
    
    static func pendingKochavaAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingKochavaAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "kochava_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingKochavaAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingKochavaAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingKochavaAPIKey")
    }
    
    static func activeKochavaEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeKochavaEnabled")
    }
    
    static func setActiveKochavaEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeKochavaEnabled")
    }
    
    static func pendingKochavaEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingKochavaEnabled")
    }
    
    static func setPendingKochavaEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingKochavaEnabled")
    }
    
    // Mark - Localytics
    
    static func activeLocalyticsAppKey() -> String? {
        if let value = userDefaults.string(forKey: "activeLocalyticsAppKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "localytics_app_key") as? String {
            userDefaults.setValue(value, forKey: "activeLocalyticsAppKey")
            return value
        }
        return nil
    }
    
    static func setActiveLocalyticsAppKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeLocalyticsAppKey")
    }
    
    static func pendingLocalyticsAppKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingLocalyticsAppKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "localytics_app_key") as? String {
            userDefaults.setValue(value, forKey: "pendingLocalyticsAppKey")
            return value
        }
        return nil
    }
    
    static func setPendingLocalyticsAppKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingLocalyticsAppKey")
    }
    
    static func activeLocalyticsEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeLocalyticsEnabled")
    }
    
    static func setActiveLocalyticsEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeLocalyticsEnabled")
    }
    
    static func pendingLocalyticsEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingLocalyticsEnabled")
    }
    
    static func setPendingLocalyticsEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingLocalyticsEnabled")
    }
    
    // Mark - mParticle
    
    static func activemParticleAppKey() -> String? {
        if let value = userDefaults.string(forKey: "activemParticleAppKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mparticle_app_key") as? String {
            userDefaults.setValue(value, forKey: "activemParticleAppKey")
            return value
        }
        return nil
    }
    
    static func setActivemParticleAppKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activemParticleAppKey")
    }
    
    static func pendingmParticleAppKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingmParticleAppKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mparticle_app_key") as? String {
            userDefaults.setValue(value, forKey: "pendingmParticleAppKey")
            return value
        }
        return nil
    }
    
    static func setPendingmParticleAppKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingmParticleAppKey")
    }
    
    static func activemParticleAppSecret() -> String? {
        if let value = userDefaults.string(forKey: "activemParticleAppSecret") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mparticle_app_secret") as? String {
            userDefaults.setValue(value, forKey: "activemParticleAppSecret")
            return value
        }
        return nil
    }
    
    static func setActivemParticleAppSecret(_ value: String) {
        userDefaults.setValue(value, forKey: "activemParticleAppSecret")
    }
    
    static func pendingmParticleAppSecret() -> String? {
        if let value = userDefaults.string(forKey: "pendingmParticleAppSecret") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "mparticle_app_secret") as? String {
            userDefaults.setValue(value, forKey: "pendingmParticleAppSecret")
            return value
        }
        return nil
    }
    
    static func setPendingmParticleAppSecret(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingmParticleAppSecret")
    }
    
    static func activemParticleEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activemParticleEnabled")
    }
    
    static func setActivemParticleEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activemParticleEnabled")
    }
    
    static func pendingmParticleEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingmParticleEnabled")
    }
    
    static func setPendingmParticleEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingmParticleEnabled")
    }
    
    // Mark - Segment
    
    static func activeSegmentAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeSegmentAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "segment_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeSegmentAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveSegmentAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeSegmentAPIKey")
    }
    
    static func pendingSegmentAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingSegmentAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "segment_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingSegmentAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingSegmentAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingSegmentAPIKey")
    }
    
    static func activeSegmentEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeSegmentEnabled")
    }
    
    static func setActiveSegmentEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeSegmentEnabled")
    }
    
    static func pendingSegmentEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingSegmentEnabled")
    }
    
    static func setPendingSegmentEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingSegmentEnabled")
    }
    
    // Mark - Singular
    
    static func activeSingularAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeSingularAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "singular_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeSingularAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveSingularAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeSingularAPIKey")
    }
    
    static func pendingSingularAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingSingularAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "singular_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingSingularAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingSingularAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingSingularAPIKey")
    }
    
    static func activeSingularEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeSingularEnabled")
    }
    
    static func setActiveSingularEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeSingularEnabled")
    }
    
    static func pendingSingularEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingSingularEnabled")
    }
    
    static func setPendingSingularEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingSingularEnabled")
    }
    
    // Mark - Stitch
    
    static func activeStitchAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "activeStitchAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "stitch_api_key") as? String {
            userDefaults.setValue(value, forKey: "activeStitchAPIKey")
            return value
        }
        return nil
    }
    
    static func setActiveStitchAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeStitchAPIKey")
    }
    
    static func pendingStitchAPIKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingStitchAPIKey") {
            if value.count > 0 {
                return value
            }
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "stitch_api_key") as? String {
            userDefaults.setValue(value, forKey: "pendingStitchAPIKey")
            return value
        }
        return nil
    }
    
    static func setPendingStitchAPIKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingStitchAPIKey")
    }
    
    static func activeStitchEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeStitchEnabled")
    }
    
    static func setActiveStitchEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeStitchEnabled")
    }
    
    static func pendingStitchEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingStitchEnabled")
    }
    
    static func setPendingStitchEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingStitchEnabled")
    }
    
}

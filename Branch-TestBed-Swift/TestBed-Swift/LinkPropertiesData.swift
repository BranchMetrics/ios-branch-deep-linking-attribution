//
//  LinkPropertiesData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct LinkPropertiesData {
    
    static let userDefaults = UserDefaults.standard
    
    static let linkPropertiesKeys: Set = ["~channel","~feature","~campaign","~stage",
                                          "~tags","~alias","$fallback_url","$desktop_url",
                                          "$ios_url","$ios_has_app_url","$ipad_url","$android_url",
                                          "$windows_phone_url","$blackberry_url","$fire_url",
                                          "$ios_wechat_url","$ios_weibo_url","$after_click_url",
                                          "$web_only","$deeplink_path","$android_deeplink_path",
                                          "$ios_deeplink_path","$match_duration","$always_deeplink",
                                          "$ios_redirect_timeout","$android_redirect_timeout",
                                          "$one_time_use","$custom_sms_text","$marketing_title",
                                          "$ios_deepview","$android_deepview","$desktop_deepview"]
    
    static func linkProperties() -> [String: Any] {
        if let value = userDefaults.dictionary(forKey: "linkProperties") {
            print("value[$match_duration] = \(value["$match_duration"] ?? "empty")")
            return value as [String : Any]
        } else {
            let value = [String: Any]()
            userDefaults.set(value, forKey: "linkProperties")
            return value
        }
    }
    
    static func setLinkProperties(_ linkProperties: [String: Any]) {
        var reducedLinkPropertiess = [String: Any]()
        
        for key in linkProperties.keys {
            guard linkPropertiesKeys.contains(key) else {
                continue
            }
            reducedLinkPropertiess[key] = linkProperties[key]
        }
        userDefaults.set(reducedLinkPropertiess, forKey: "linkProperties")
    }
    
    static func clearLinkProperties() {
        userDefaults.set([String: Any](), forKey:"linkProperties")
    }
    
    static func branchLinkProperties() -> BranchLinkProperties {
        let branchLinkProperties = BranchLinkProperties()
        let properties = linkProperties()
        
        for key in properties.keys {
            guard properties[key] != nil else {
                continue
            }
            
            print("key = \(key)")
            switch key {
            case "~alias":
                branchLinkProperties.alias = properties[key] as! String
            case "~campaign":
                branchLinkProperties.campaign = properties[key] as! String
            case "~channel":
                branchLinkProperties.channel = properties[key] as! String
            case "~feature":
                branchLinkProperties.feature = properties[key] as! String
            case "~stage":
                branchLinkProperties.stage = properties[key] as! String
            case "~tags":
                branchLinkProperties.tags = properties[key] as! [String]
            case "$match_duration":
                if let value = properties[key] {
                    branchLinkProperties.matchDuration = UInt(value as? String ?? "") ?? 0
                }
            default:
                guard (key.first != "+") && (key.first != "~") else {
                    continue
                }
                guard let value = properties[key] as? String else {
                    continue
                }
                branchLinkProperties.addControlParam(key, withValue: value)
            }
        }
        return branchLinkProperties
    }
    
    static func setBranchLinkProperties(branchLinkProperties: BranchLinkProperties) {
        setLinkProperties(branchLinkProperties.dictionaryWithValues(forKeys: Array(linkPropertiesKeys)) as [String : AnyObject])
    }
    
}

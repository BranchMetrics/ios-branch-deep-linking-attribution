//
//  TestData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import Foundation

struct TestData {
    
    static let userDefaults = NSUserDefaults.standardUserDefaults()

    static func getUserID() -> String? {
        if let value = userDefaults.stringForKey("userID") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "userID")
            return value
        }
    }
    
    static func setUserID(value: String) {
        if value == "" {
            userDefaults.removeObjectForKey("userID")
        } else {
            userDefaults.setValue(value, forKey: "userID")
        }
    }
    
    static func getLinkProperties() -> [String: AnyObject] {
        if let value = userDefaults.dictionaryForKey("linkProperties") {
            return value
        } else {
            let value = [String: AnyObject]()
            userDefaults.setObject(value, forKey: "linkProperties")
            return value
        }
    }
    
    static func setLinkProperties(value: [String: AnyObject]) {
        userDefaults.setObject(value, forKey: "linkProperties")
    }
    
    static func getUniversalObjectProperties() -> [String: AnyObject] {
        if let value = userDefaults.dictionaryForKey("UniversalObjectProperties") {
            return value
        } else {
            let value = [String: AnyObject]()
            userDefaults.setObject(value, forKey: "UniversalObjectProperties")
            return value
        }
    }
    
    static func setUniversalObjectProperties(value: [String: AnyObject]) {
        userDefaults.setObject(value, forKey: "UniversalObjectProperties")
    }
    
    static func getRewardsBucket() -> String {
        if let value = userDefaults.stringForKey("rewardsBucket") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardsBucket")
            return value
        }
    }
    
    static func setRewardsBucket(value: String) {
        if value == "" {
            userDefaults.removeObjectForKey("rewardsBucket")
        } else {
            userDefaults.setValue(value, forKey: "rewardsBucket")
        }
    }
    
    static func getRewardsBalanceOfBucket() -> String {
        if let value = userDefaults.stringForKey("rewardsBalanceOfBucket") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardsBalanceOfBucket")
            return value
        }
    }
    
    static func setRewardsBalanceOfBucket(value: String) {
        if value == "" {
            userDefaults.removeObjectForKey("rewardsBalanceOfBucket")
        } else {
            userDefaults.setValue(value, forKey: "rewardsBalanceOfBucket")
        }
    }
    
    static func getRewardPointsToRedeem() -> String {
        if let value = userDefaults.stringForKey("rewardPointsToRedeem") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardPointsToRedeem")
            return value
        }
    }
    
    static func setRewardPointsToRedeem(value: String) {
        if Int(value) != nil {
            userDefaults.setValue(value, forKey: "rewardPointsToRedeem")
        } else {
            userDefaults.removeObjectForKey("rewardPointsToRedeem")
        }
    }
    
    static func getCustomEventName() -> String? {
        if let value = userDefaults.stringForKey("customEventName") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "customEventName")
            return value
        }
    }
    
    static func setCustomEventName(value: String) {
        if value == "" {
            userDefaults.removeObjectForKey("customEventName")
        } else {
            userDefaults.setValue(value, forKey: "customEventName")
        }
    }
    
    static func getCustomEventMetadata() -> [String: AnyObject] {
        if let value = userDefaults.dictionaryForKey("customEventMetadata") {
            return value
        } else {
            let value = [String: AnyObject]()
            userDefaults.setObject(value, forKey: "customEventMetadata")
            return value
        }
    }
    
    static func setCustomEventMetadata(value: [String: AnyObject]) {
        userDefaults.setObject(value, forKey: "customEventMetadata")
    }
    
    
    
}
//
//  TestData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import Foundation

struct TestData {
    
    static let userDefaults = UserDefaults.standard

    static func getUserID() -> String? {
        if let value = userDefaults.string(forKey: "userID") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "userID")
            return value
        }
    }
    
    static func setUserID(_ value: String) {
        if value == "" {
            userDefaults.removeObject(forKey: "userID")
        } else {
            userDefaults.setValue(value, forKey: "userID")
        }
    }
    
    static func getLinkProperties() -> [String: AnyObject] {
        if let value = userDefaults.dictionary(forKey: "linkProperties") {
            return value as [String : AnyObject]
        } else {
            let value = [String: AnyObject]()
            userDefaults.set(value, forKey: "linkProperties")
            return value
        }
    }
    
    static func setLinkProperties(_ value: [String: AnyObject]) {
        userDefaults.set(value, forKey: "linkProperties")
    }
    
    static func getUniversalObjectProperties() -> [String: AnyObject] {
        if let value = userDefaults.dictionary(forKey: "UniversalObjectProperties") {
            return value as [String : AnyObject]
        } else {
            let value = [String: AnyObject]()
            userDefaults.set(value, forKey: "UniversalObjectProperties")
            return value
        }
    }
    
    static func setUniversalObjectProperties(_ value: [String: AnyObject]) {
        userDefaults.set(value, forKey: "UniversalObjectProperties")
    }
    
    static func getRewardsBucket() -> String {
        if let value = userDefaults.string(forKey: "rewardsBucket") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardsBucket")
            return value
        }
    }
    
    static func setRewardsBucket(_ value: String) {
        if value == "" {
            userDefaults.removeObject(forKey: "rewardsBucket")
        } else {
            userDefaults.setValue(value, forKey: "rewardsBucket")
        }
    }
    
    static func getRewardsBalanceOfBucket() -> String {
        if let value = userDefaults.string(forKey: "rewardsBalanceOfBucket") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardsBalanceOfBucket")
            return value
        }
    }
    
    static func setRewardsBalanceOfBucket(_ value: String) {
        if value == "" {
            userDefaults.removeObject(forKey: "rewardsBalanceOfBucket")
        } else {
            userDefaults.setValue(value, forKey: "rewardsBalanceOfBucket")
        }
    }
    
    static func getRewardPointsToRedeem() -> String {
        if let value = userDefaults.string(forKey: "rewardPointsToRedeem") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "rewardPointsToRedeem")
            return value
        }
    }
    
    static func setRewardPointsToRedeem(_ value: String) {
        if Int(value) != nil {
            userDefaults.setValue(value, forKey: "rewardPointsToRedeem")
        } else {
            userDefaults.removeObject(forKey: "rewardPointsToRedeem")
        }
    }
    
    static func getCustomEventName() -> String? {
        if let value = userDefaults.string(forKey: "customEventName") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "customEventName")
            return value
        }
    }
    
    static func setCustomEventName(_ value: String) {
        if value == "" {
            userDefaults.removeObject(forKey: "customEventName")
        } else {
            userDefaults.setValue(value, forKey: "customEventName")
        }
    }
    
    static func getCustomEventMetadata() -> [String: AnyObject] {
        if let value = userDefaults.dictionary(forKey: "customEventMetadata") {
            return value as [String : AnyObject]
        } else {
            let value = [String: AnyObject]()
            userDefaults.set(value, forKey: "customEventMetadata")
            return value
        }
    }
    
    static func setCustomEventMetadata(_ value: [String: AnyObject]) {
        userDefaults.set(value, forKey: "customEventMetadata")
    }
    
    
    
}

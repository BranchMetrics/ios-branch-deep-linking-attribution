//
//  ReferralRewardsData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct ReferralRewardsData {
    
    static let userDefaults = UserDefaults.standard
    
    static func rewardsBucket() -> String {
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
    
    static func rewardsBalanceOfBucket() -> String {
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
    
    static func rewardPointsToRedeem() -> String {
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
    
}

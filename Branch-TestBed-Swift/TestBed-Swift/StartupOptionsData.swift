//
//  StartupOptionsData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct StartupOptionsData {
    
    static let userDefaults = UserDefaults.standard
    
    static func getActiveBranchKey() -> String? {
        if let value = userDefaults.string(forKey: "activeBranchKey") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "activeBranchKey")
            return value
        }
    }
    
    static func setActiveBranchKey(_ value: String) {
        userDefaults.setValue(value, forKey: "activeBranchKey")
    }
    
    static func getPendingBranchKey() -> String? {
        if let value = userDefaults.string(forKey: "pendingBranchKey") {
            return value
        } else {
            let value = ""
            userDefaults.setValue(value, forKey: "pendingBranchKey")
            return value
        }
    }
    
    static func setPendingBranchKey(_ value: String) {
        userDefaults.setValue(value, forKey: "pendingBranchKey")
    }
    
    static func getActiveSetDebugEnabled() -> Bool? {
        return userDefaults.bool(forKey: "activeSetDebug")
    }
    
    static func setActiveSetDebugEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeSetDebug")
    }

    static func getPendingSetDebugEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingSetDebug")
    }
    
    static func setPendingSetDebugEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingSetDebug")
    }
    
}

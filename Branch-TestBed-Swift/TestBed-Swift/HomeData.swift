//
//  HomeData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct HomeData {
    
    static let userDefaults = UserDefaults.standard
    
    static func userID() -> String? {
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
    
}

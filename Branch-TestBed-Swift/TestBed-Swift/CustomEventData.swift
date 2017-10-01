//
//  CustomEventData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct CustomEventData {
    
    static let userDefaults = UserDefaults.standard
    
    static func customEventName() -> String? {
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
    
    static func customEventMetadata() -> [String: AnyObject] {
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

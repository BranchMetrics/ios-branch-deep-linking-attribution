//
//  DataStore.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
// TODO: add $ios_has_app_url, $twitter_image_url to viewcontrollers
// TODO: break this up into class-specific data access objects
import Foundation

struct DataStore {
    
    static let userDefaults = UserDefaults.standard
    
    static func getDefaultBranchEvent() -> BranchEvent {
        let branchEvent = BranchEvent.standardEvent(BranchStandardEvent.viewItem)
        
        return branchEvent
    }
    
    // MARK: Commerce Events
    

    

    
}

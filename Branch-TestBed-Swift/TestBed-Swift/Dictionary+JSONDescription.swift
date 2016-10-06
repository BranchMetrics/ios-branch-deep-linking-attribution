//
//  Dictionary+JSONDescription.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/5/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import Foundation

extension Dictionary {

    func JSONDescription() -> String {
        
        let data = self as AnyObject
        var jsonString = "Error parsing dictionary"
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
            jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
            
        } catch let error as NSError {
            print(error.description)
        }
        return jsonString
    }
    
}

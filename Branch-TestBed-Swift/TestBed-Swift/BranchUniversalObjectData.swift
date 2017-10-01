//
//  BranchUniversalObjectData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct BranchUniversalObjectData {
    
    static let userDefaults = UserDefaults.standard
    
    static let universalObjectKeys: Set = ["$publicly_indexable","$keywords",
                                           "$canonical_identifier","$exp_date","$content_type", "$og_title",
                                           "$og_description","$og_image_url", "$og_image_width",
                                           "$og_image_height","$og_video", "$og_url",
                                           "$og_type","$og_redirect", "$og_app_id",
                                           "$twitter_card","$twitter_title", "$twitter_description",
                                           "$twitter_image_url","$twitter_site","$twitter_app_country",
                                           "$twitter_player","$twitter_player_width","$twitter_player_height",
                                           "$custom_meta_tags", "customData"]
    
    static let systemKeys: Set = ["+clicked_branch_link","+referrer","~referring_link","+is_first_session",
                                  "~id","~creation_source","+match_guaranteed","$identity_id",
                                  "$one_time_use_used","+click_timestamp"]
    
    static func defaultUniversalObject() -> BranchUniversalObject {
        let universalObject = BranchUniversalObject.init()
        universalObject.contentMetadata.contentSchema = BranchContentSchema.commerceProduct
        universalObject.title = "Nike Woolen Sox"
        universalObject.canonicalIdentifier = "nike/5324"
        universalObject.contentDescription = "Fine combed woolen sox for those who love your foot"
        universalObject.contentMetadata.currency = BNCCurrency.USD
        universalObject.contentMetadata.price = 80.2
        universalObject.contentMetadata.quantity = 5
        universalObject.contentMetadata.sku = "110112467"
        universalObject.contentMetadata.productName = "Woolen Sox"
        universalObject.contentMetadata.productCategory = BNCProductCategory(rawValue: "Apparel & Accessories")
        universalObject.contentMetadata.productBrand = "Nike"
        universalObject.contentMetadata.productVariant = "Xl"
        universalObject.contentMetadata.ratingAverage = 3.3
        universalObject.contentMetadata.ratingCount = 5
        universalObject.contentMetadata.ratingMax = 2.8
        universalObject.contentMetadata.contentSchema = BranchContentSchema.commerceProduct
        
        return universalObject
    }
    
    static func universalObject() -> [String: AnyObject] {
        if let value = userDefaults.dictionary(forKey: "universalObject") {
            return value as [String : AnyObject]
        } else {
            let value = [String: AnyObject]()
            userDefaults.set(value, forKey: "universalObject")
            return value
        }
    }
    
    static func setUniversalObject(_ parameters: [String: AnyObject]) {
        var params = parameters
        var universalObject = [String: AnyObject]()
        
        for key in LinkPropertiesData.linkPropertiesKeys { params.removeValue(forKey: key) }
        for key in systemKeys { params.removeValue(forKey: key) }
        for key in universalObjectKeys {
            if let value = parameters[key] {
                universalObject[key] = value as AnyObject?
                params.removeValue(forKey: key)
            }
        }
        for param in params {
            universalObject["customData"]?.add(param)
        }
        
        userDefaults.set(universalObject, forKey: "universalObject")
    }
    
    static func clearUniversalObject() {
        userDefaults.set([String: AnyObject](), forKey: "universalObject")
    }
    
    static func branchUniversalObject() -> BranchUniversalObject {
        let uo = universalObject()
        let branchUniversalObject: BranchUniversalObject
        
        if let canonicalIdentifier = uo["$canonical_identifier"] as? String {
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        } else {
            var canonicalIdentifier = ""
            for _ in 1...18 {
                canonicalIdentifier.append(String(arc4random_uniform(10)))
            }
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        }
        
        for key in uo.keys {
            
            guard uo[key] != nil else {
                continue
            }
            
            let value = uo[key]!.description!()
            
            switch key {
            case "$canonical_identifier":
                branchUniversalObject.canonicalIdentifier = value
                
            case "$og_description":
                branchUniversalObject.contentDescription = value
            case "$exp_date":
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let expirationDate = dateFormatter.date(from:value)
                branchUniversalObject.expirationDate = expirationDate
            case "$og_image_url":
                branchUniversalObject.imageUrl = value
            case "$keywords":
                branchUniversalObject.keywords = uo[key] as! [AnyObject] as? [String]
            case "$og_title":
                branchUniversalObject.title = value
            case "$content_type":
                if let contentType = uo[key] {
                    branchUniversalObject.contentMetadata.contentSchema = contentType as? BranchContentSchema
                }
            case "$price":
                if let price = uo[key] as? String {
                    let formatter = NumberFormatter()
                    formatter.generatesDecimalNumbers = true
                    branchUniversalObject.contentMetadata.price = formatter.number(from: price) as? NSDecimalNumber ?? 0
                }
            case "$currency":
                if let currency = uo[key] as? String {
                    branchUniversalObject.contentMetadata.currency = BNCCurrency(rawValue: currency)
                }
            case "customData":
                if let data = uo[key] as? [String: String] {
                    branchUniversalObject.setValuesForKeys(data)
                }
            default:
                branchUniversalObject.setValue(uo[key], forKey: key)
            }
        }
        return branchUniversalObject
    }
    
}

//
//  DataStore.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
// TODO: add $ios_has_app_url, $twitter_image_url to viewcontrollers
import Foundation

struct DataStore {
    
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
    
    static let universalObjectKeys: Set = ["$publicly_indexable","$keywords",
                                           "$canonical_identifier","$exp_date","$content_type", "$og_title",
                                           "$og_description","$og_image_url", "$og_image_width",
                                           "$og_image_height","$og_video", "$og_url",
                                           "$og_type","$og_redirect", "$og_app_id",
                                           "$twitter_card","$twitter_title", "$twitter_description",
                                           "$twitter_image_url","$twitter_site","$twitter_app_country",
                                           "$twitter_player","$twitter_player_width","$twitter_player_height",
                                           "$custom_meta_tags"]
    
    static let systemKeys: Set = ["+clicked_branch_link","+referrer","~referring_link","+is_first_session",
                                  "~id","~creation_source","+match_guaranteed","$identity_id",
                                  "$one_time_use_used","+click_timestamp"]
    
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
    
    static func getLinkProperties() -> [String: Any] {
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
    
    static func getBranchLinkProperties() -> BranchLinkProperties {
        let branchLinkProperties = BranchLinkProperties()
        let linkProperties = getLinkProperties()
        
        for key in linkProperties.keys {
            guard linkProperties[key] != nil else {
                continue
            }
            
            print("key = \(key)")
            switch key {
            case "~alias":
                branchLinkProperties.alias = linkProperties[key] as! String
            case "~campaign":
                branchLinkProperties.campaign = linkProperties[key] as! String
            case "~channel":
                branchLinkProperties.channel = linkProperties[key] as! String
            case "~feature":
                branchLinkProperties.feature = linkProperties[key] as! String
            case "~stage":
                branchLinkProperties.stage = linkProperties[key] as! String
            case "~tags":
                branchLinkProperties.tags = linkProperties[key] as! [String]
            case "$match_duration":
                if let value = linkProperties[key] {
                    branchLinkProperties.matchDuration = UInt(value as? String ?? "") ?? 0
                }
            default:
                guard (key.characters.first != "+") && (key.characters.first != "~") else {
                    continue
                }
                guard let value = linkProperties[key] as? String else {
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
    
    static func getUniversalObject() -> [String: AnyObject] {
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
        
        for key in linkPropertiesKeys { params.removeValue(forKey: key) }
        for key in systemKeys { params.removeValue(forKey: key) }
        for key in universalObjectKeys {
            if let value = parameters[key] {
                universalObject[key] = value as AnyObject?
                params.removeValue(forKey: key)
            }
        }
        universalObject["customData"] = params as AnyObject?
        
        userDefaults.set(universalObject, forKey: "universalObject")
        
    }
    
    static func clearUniversalObject() {
        userDefaults.set([String: AnyObject](), forKey: "universalObject")
    }
    
    static func getBranchUniversalObject() -> BranchUniversalObject {
        let universalObject = getUniversalObject()
        let branchUniversalObject: BranchUniversalObject
        
        if let canonicalIdentifier = universalObject["$canonical_identifier"] as? String {
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        } else {
            var canonicalIdentifier = ""
            for _ in 1...18 {
                canonicalIdentifier.append(String(arc4random_uniform(10)))
            }
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        }
        
        for key in universalObject.keys {
            
            guard universalObject[key] != nil else {
                continue
            }
            
            switch key {
            case "$canonical_identifier":
                branchUniversalObject.canonicalIdentifier = universalObject[key] as! String
            case "$og_description":
                if let description = universalObject[key] {
                    branchUniversalObject.contentDescription = description as? String
                }
            case "$exp_date":
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let expirationDate = dateFormatter.date(from: universalObject[key] as! String)
                branchUniversalObject.expirationDate = expirationDate
            case "$og_image_url":
                if let imageURL = universalObject[key] {
                    branchUniversalObject.imageUrl = imageURL as? String
                }
            case "$keywords":
                branchUniversalObject.keywords = universalObject[key] as! [AnyObject]
            case "$og_title":
                if let title = universalObject[key] {
                    branchUniversalObject.title = title as? String
                }
            case "$content_type":
                if let contentType = universalObject[key] {
                    branchUniversalObject.type = contentType as? String
                }
            case "$price":
                if let price = universalObject[key] as? String {
                    if let float_price = Float(price) {
                        branchUniversalObject.price = CGFloat(float_price)
                    } else {
                        branchUniversalObject.price = 0.0
                    }
                }
            case "$currency":
                if let currency = universalObject[key] as? String {
                    branchUniversalObject.currency = currency
                }
            case "customData":
                if let data = universalObject[key] as? [String: String] {
                    for customDataKey in data.keys {
                        branchUniversalObject.addMetadataKey(customDataKey, value: data[customDataKey]!)
                    }
                }
            default:
                branchUniversalObject.addMetadataKey(key, value: universalObject[key] as! String)
            }
        }
        return branchUniversalObject
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
    
    static func setActivePendingSetDebugEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "activeSetDebug")
    }
    
    static func getPendingSetDebugEnabled() -> Bool? {
        return userDefaults.bool(forKey: "pendingSetDebug")
    }
    
    static func setPendingPendingSetDebugEnabled(_ value: Bool) {
        userDefaults.setValue(value, forKey: "pendingSetDebug")
    }
    
    // MARK: Commerce Events
    
    static func getCommerceEventDefaults() -> [String: String] {
        return [
            "transactionID": "00000001",
            "affiliation": "Branch Default",
            "coupon": "No coupon",
            "currency": "USD",
            "shipping": "100.00",
            "tax": "7.00",
            "revenue": "107.00",
            "default": "true"
        ]
    }
    
    static func getCommerceEvent() -> [String: Any]? {
        if let value = userDefaults.dictionary(forKey: "CommerceEvent") {
            return value
        } else {
            return getCommerceEventDefaults()
        }
    }
    
    static func setCommerceEvent(_ value: [String: Any]) {
        userDefaults.set(value, forKey: "CommerceEvent")
    }
    
    static func clearCommerceEvent() {
        userDefaults.removeObject(forKey: "CommerceEvent")
    }
    
    static func getBNCCommerceEvent() -> BNCCommerceEvent {
        let bncCommerceEvent = BNCCommerceEvent.init()
        let commerceEvent = getCommerceEvent() as! [String: String]
        let defaults = getCommerceEventDefaults()
        
        bncCommerceEvent.transactionID = commerceEvent["transactionID"] != "" ? commerceEvent["transactionID"] : defaults["transactionID"]!
        bncCommerceEvent.affiliation = commerceEvent["affiliation"] != "" ? commerceEvent["affiliation"] :  defaults["affiliation"]!
        bncCommerceEvent.coupon = commerceEvent["coupon"] != "" ? commerceEvent["coupon"] : defaults["coupon"]!
        bncCommerceEvent.currency = commerceEvent["currency"] != "" ? commerceEvent["currency"] : defaults["currency"]!
        bncCommerceEvent.shipping = self.stringToNSDecimalNumber(with: commerceEvent["shipping"] != "" ? commerceEvent["shipping"]! : defaults["shipping"]!)
        bncCommerceEvent.tax = self.stringToNSDecimalNumber(with: commerceEvent["tax"] != "" ? commerceEvent["tax"]! : defaults["tax"]!)
        bncCommerceEvent.revenue = self.stringToNSDecimalNumber(with: commerceEvent["revenue"] != "" ? commerceEvent["revenue"]! : defaults["revenue"]!)
        bncCommerceEvent.products = self.getBNCProducts()
        
        return bncCommerceEvent
    }
    
    static func setBNCCommerceEvent(_ bncCommerceEvent: BNCCommerceEvent) {
        
        let commerceEvent: [String: Any] = [
            "transactionID": bncCommerceEvent.transactionID,
            "affiliation": bncCommerceEvent.affiliation,
            "coupon": bncCommerceEvent.coupon,
            "currency": bncCommerceEvent.currency,
            "shipping": "\(bncCommerceEvent.shipping)",
            "tax": "\(bncCommerceEvent.tax)",
            "revenue": "\(bncCommerceEvent.revenue)"
        ]
        self.setBNCProducts(bncCommerceEvent.products)
        self.setCommerceEvent(commerceEvent)
    }
    
    static func getProductDefaults() -> [String: String] {
        return [
            "name": "Anvil",
            "brand": "ACME",
            "sku": "00000001",
            "quantity": "1",
            "price": "100.00",
            "variant": "London",
            "category": "Hardware",
            "default": "true"
        ]
    }
    
    static func getProducts() -> [[String : String]] {
        return userDefaults.array(forKey: "Products") as? [[String : String]] ?? [[String: String]]()
    }
    
    static func getProductsWithAddedProduct(_ product: [String : String]) -> [[String : String]] {
        var products = self.getProducts()
        products.append(product)
        self.setProducts(products)
        return products
    }
    
    static func setProducts(_ products: [[String: String]]) {
        userDefaults.set(products, forKey: "Products")
    }
    
    static func getBNCProducts() -> [BNCProduct] {
        let bncProduct = BNCProduct.init()
        
        let products = self.getProducts()
        if products.count > 0 {
            return products.map({
                (product: [String: String]) -> BNCProduct in
                
                let defaults = self.getProductDefaults()
                
                bncProduct.name = product["name"] ?? defaults["name"]
                bncProduct.brand = product["brand"] ?? defaults["brand"]
                bncProduct.sku = product["sku"] ?? defaults["sku"]
                bncProduct.price = self.stringToNSDecimalNumber(with: product["price"] ?? defaults["price"]!)
                bncProduct.quantity = self.stringToNSDecimalNumber(with: product["quantity"] ?? defaults["quantity"]!)
                bncProduct.category = product["category"] ?? defaults["category"]
                bncProduct.variant = product["variant"] ?? defaults["variant"]
                
                return bncProduct
            })
        } else {
            let defaults = self.getProductDefaults()
            
            bncProduct.name = defaults["name"]
            bncProduct.brand = defaults["brand"]
            bncProduct.sku = defaults["sku"]
            bncProduct.price = self.stringToNSDecimalNumber(with: defaults["price"]!)
            bncProduct.quantity = self.stringToNSDecimalNumber(with: defaults["quantity"]!)
            bncProduct.category = defaults["category"]
            bncProduct.variant = defaults["variant"]
            
            return [bncProduct]
        }
    }
    
    static func setBNCProducts(_ products: [BNCProduct]) {
        self.setProducts(products.map({
            (bncProduct: BNCProduct) in
            return [
                "name": bncProduct.name ?? "",
                "brand": bncProduct.brand ?? "",
                "sku": bncProduct.sku ?? "",
                "price": "\(bncProduct.price)" ,
                "quantity": "\(bncProduct.quantity)" ,
                "category": bncProduct.category ?? "",
                "variant": bncProduct.variant ?? ""
            ]
        }))
    }
    
    static func getCommerceEventCustomMetadata() -> [String: AnyObject] {
        if let value = userDefaults.dictionary(forKey: "commerceEventCustomMetadata") {
            return value as [String : AnyObject]
        } else {
            let value = [String: AnyObject]()
            userDefaults.set(value, forKey: "commerceEventCustomMetadata")
            return value
        }
    }
    
    static func setCommerceEventCustomMetadata(_ value: [String: AnyObject]) {
        userDefaults.set(value, forKey: "commerceEventCustomMetadata")
    }
    
    static func getProductCategories() -> [String] {
        return [
            "Animals & Pet Supplies",
            "Apparel & Accessories",
            "Arts & Entertainment",
            "Baby & Toddler",
            "Business & Industrial",
            "Cameras & Optics",
            "Electronics",
            "Food, Beverages & Tobacco",
            "Furniture",
            "Hardware",
            "Health & Beauty",
            "Home & Garden",
            "Luggage & Bags",
            "Mature",
            "Media",
            "Office Supplies",
            "Religious & Ceremonial",
            "Software",
            "Sporting Goods",
            "Toys & Games",
            "Vehicles & Parts"
        ]
    }
    
    static func getCurrencies() -> [String] {
        return [
            "AED United Arab Emirates Dirham",
            "AFN Afghanistan Afghani",
            "ALL Albania Lek",
            "AMD Armenia Dram",
            "ANG Netherlands Antilles Guilder",
            "AOA Angola Kwanza",
            "ARS Argentina Peso",
            "AUD Australia Dollar",
            "AWG Aruba Guilder",
            "AZN Azerbaijan Manat",
            "BAM Bosnia and Herzegovina Marka",
            "BBD Barbados Dollar",
            "BDT Bangladesh Taka",
            "BGN Bulgaria Lev",
            "BHD Bahrain Dinar",
            "BIF Burundi Franc",
            "BMD Bermuda Dollar",
            "BND Brunei Darussalam Dollar",
            "BOB Bolivia Bolíviano",
            "BRL Brazil Real",
            "BSD Bahamas Dollar",
            "BTN Bhutan Ngultrum",
            "BWP Botswana Pula",
            "BYN Belarus Ruble",
            "BZD Belize Dollar",
            "CAD Canada Dollar",
            "CDF Congo/Kinshasa Franc",
            "CHF Switzerland Franc",
            "CLP Chile Peso",
            "CNY China Yuan Renminbi",
            "COP Colombia Peso",
            "CRC Costa Rica Colon",
            "CUC Cuba Convertible Peso",
            "CUP Cuba Peso",
            "CVE Cape Verde Escudo",
            "CZK Czech Republic Koruna",
            "DJF Djibouti Franc",
            "DKK Denmark Krone",
            "DOP Dominican Republic Peso",
            "DZD Algeria Dinar",
            "EGP Egypt Pound",
            "ERN Eritrea Nakfa",
            "ETB Ethiopia Birr",
            "EUR Euro Member Countries",
            "FJD Fiji Dollar",
            "FKP Falkland Islands Pound",
            "GBP United Kingdom Pound",
            "GEL Georgia Lari",
            "GGP Guernsey Pound",
            "GHS Ghana Cedi",
            "GIP Gibraltar Pound",
            "GMD Gambia Dalasi",
            "GNF Guinea Franc",
            "GTQ Guatemala Quetzal",
            "GYD Guyana Dollar",
            "HKD Hong Kong Dollar",
            "HNL Honduras Lempira",
            "HRK Croatia Kuna",
            "HTG Haiti Gourde",
            "HUF Hungary Forint",
            "IDR Indonesia Rupiah",
            "ILS Israel Shekel",
            "IMP Isle of Man Pound",
            "INR India Rupee",
            "IQD Iraq Dinar",
            "IRR Iran Rial",
            "ISK Iceland Krona",
            "JEP Jersey Pound",
            "JMD Jamaica Dollar",
            "JOD Jordan Dinar",
            "JPY Japan Yen",
            "KES Kenya Shilling",
            "KGS Kyrgyzstan Som",
            "KHR Cambodia Riel",
            "KMF Comorian Franc",
            "KPW Korea (North) Won",
            "KRW Korea (South) Won",
            "KWD Kuwait Dinar",
            "KYD Cayman Islands Dollar",
            "KZT Kazakhstan Tenge",
            "LAK Laos Kip",
            "LBP Lebanon Pound",
            "LKR Sri Lanka Rupee",
            "LRD Liberia Dollar",
            "LSL Lesotho Loti",
            "LYD Libya Dinar",
            "MAD Morocco Dirham",
            "MDL Moldova Leu",
            "MGA Madagascar Ariary",
            "MKD Macedonia Denar",
            "MMK Myanmar (Burma) Kyat",
            "MNT Mongolia Tughrik",
            "MOP Macau Pataca",
            "MRO Mauritania Ouguiya",
            "MUR Mauritius Rupee",
            "MVR Maldives Rufiyaa",
            "MWK Malawi Kwacha",
            "MXN Mexico Peso",
            "MYR Malaysia Ringgit",
            "MZN Mozambique Metical",
            "NAD Namibia Dollar",
            "NGN Nigeria Naira",
            "NIO Nicaragua Cordoba",
            "NOK Norway Krone",
            "NPR Nepal Rupee",
            "NZD New Zealand Dollar",
            "OMR Oman Rial",
            "PAB Panama Balboa",
            "PEN Peru Sol",
            "PGK Papua New Guinea Kina",
            "PHP Philippines Peso",
            "PKR Pakistan Rupee",
            "PLN Poland Zloty",
            "PYG Paraguay Guarani",
            "QAR Qatar Riyal",
            "RON Romania Leu",
            "RSD Serbia Dinar",
            "RUB Russia Ruble",
            "RWF Rwanda Franc",
            "SAR Saudi Arabia Riyal",
            "SBD Solomon Islands Dollar",
            "SCR Seychelles Rupee",
            "SDG Sudan Pound",
            "SEK Sweden Krona",
            "SGD Singapore Dollar",
            "SHP Saint Helena Pound",
            "SLL Sierra Leone Leone",
            "SOS Somalia Shilling",
            "SPL Seborga Luigino",
            "SRD Suriname Dollar",
            "STD São Tomé and Príncipe Dobra",
            "SVC El Salvador Colon",
            "SYP Syria Pound",
            "SZL Swaziland Lilangeni",
            "THB Thailand Baht",
            "TJS Tajikistan Somoni",
            "TMT Turkmenistan Manat",
            "TND Tunisia Dinar",
            "TOP Tonga Pa'anga",
            "TRY Turkey Lira",
            "TTD Trinidad and Tobago Dollar",
            "TVD Tuvalu Dollar",
            "TWD Taiwan New Dollar",
            "TZS Tanzania Shilling",
            "UAH Ukraine Hryvnia",
            "UGX Uganda Shilling",
            "USD United States Dollar",
            "UYU Uruguay Peso",
            "UZS Uzbekistan Som",
            "VEF Venezuela Bolívar",
            "VND Viet Nam Dong",
            "VUV Vanuatu Vatu",
            "WST Samoa Tala",
            "XAF Central African CFA Franc",
            "XCD East Caribbean Dollar",
            "XDR IMF Special Drawing Rights",
            "XOF West African CFA Franc",
            "XPF CFP Franc",
            "YER Yemen Rial",
            "ZAR South Africa Rand",
            "ZMW Zambia Kwacha",
            "ZWD Zimbabwe Dollar"
        ]
    }
    
    static func stringToNSDecimalNumber(with string: String) -> NSDecimalNumber {
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        return formatter.number(from: string) as? NSDecimalNumber ?? 0
    }
    
}

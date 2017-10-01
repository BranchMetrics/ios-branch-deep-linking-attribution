//
//  CommerceEventData.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/17/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct CommerceEventData {
    
    static let userDefaults = UserDefaults.standard
    
    static func commerceEventDefaults() -> [String: String] {
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
    
    static func commerceEvent() -> [String: Any]? {
        if let value = userDefaults.dictionary(forKey: "CommerceEvent") {
            return value
        } else {
            return commerceEventDefaults()
        }
    }
    
    static func setCommerceEvent(_ value: [String: Any]) {
        userDefaults.set(value, forKey: "CommerceEvent")
    }
    
    static func clearCommerceEvent() {
        userDefaults.removeObject(forKey: "CommerceEvent")
    }
    // v2 commerce event function
    static func branchEvent() -> BranchEvent {
        let branchEvent = BranchEvent.standardEvent(BranchStandardEvent.viewItem)
        let event = commerceEvent() as! [String: String]
        let defaults = commerceEventDefaults()
        
        branchEvent.transactionID = event["transactionID"] != "" ? event["transactionID"] : defaults["transactionID"]!
        branchEvent.affiliation = event["affiliation"] != "" ? event["affiliation"] :  defaults["affiliation"]!
        branchEvent.coupon = event["coupon"] != "" ? event["coupon"] : defaults["coupon"]!
        branchEvent.currency = (event["currency"] != "" ? event["currency"] : defaults["currency"]).map { BNCCurrency(rawValue: $0) }
        branchEvent.shipping = self.stringToNSDecimalNumber(with: event["shipping"] != "" ? event["shipping"]! : defaults["shipping"]!)
        branchEvent.tax = self.stringToNSDecimalNumber(with: event["tax"] != "" ? event["tax"]! : defaults["tax"]!)
        branchEvent.revenue = self.stringToNSDecimalNumber(with: event["revenue"] != "" ? event["revenue"]! : defaults["revenue"]!)
        branchEvent.contentItems = [BranchUniversalObjectData.defaultUniversalObject()]
        
        return branchEvent
    }
    
    // v2 commerce event function
    static func setBranchEvent(_ branchEvent: BranchEvent) {
        
        let commerceEvent: [String: Any] = [
            "transactionID": branchEvent.transactionID ?? "",
            "affiliation": branchEvent.affiliation ?? "",
            "coupon": branchEvent.coupon ?? "",
            "currency": branchEvent.currency ?? "",
            "shipping": "\(String(describing: branchEvent.shipping))",
            "tax": "\(String(describing: branchEvent.tax))",
            "revenue": "\(String(describing: branchEvent.revenue))"
        ]
        // self.setBNCProducts(branchEvent.products!)
        self.setCommerceEvent(commerceEvent)
    }
    
    // v1 commerce event function
    static func bNCCommerceEvent() -> BNCCommerceEvent {
        let bncCommerceEvent = BNCCommerceEvent.init()
        let event = commerceEvent() as! [String: String]
        let defaults = commerceEventDefaults()
        
        bncCommerceEvent.transactionID = event["transactionID"] != "" ? event["transactionID"] : defaults["transactionID"]!
        bncCommerceEvent.affiliation = event["affiliation"] != "" ? event["affiliation"] :  defaults["affiliation"]!
        bncCommerceEvent.coupon = event["coupon"] != "" ? event["coupon"] : defaults["coupon"]!
        bncCommerceEvent.currency = (event["currency"] != "" ? event["currency"] : defaults["currency"]).map { BNCCurrency(rawValue: $0) }
        bncCommerceEvent.shipping = self.stringToNSDecimalNumber(with: event["shipping"] != "" ? event["shipping"]! : defaults["shipping"]!)
        bncCommerceEvent.tax = self.stringToNSDecimalNumber(with: event["tax"] != "" ? event["tax"]! : defaults["tax"]!)
        bncCommerceEvent.revenue = self.stringToNSDecimalNumber(with: event["revenue"] != "" ? event["revenue"]! : defaults["revenue"]!)
        bncCommerceEvent.products = self.bNCProducts()
        
        return bncCommerceEvent
    }
    
    // v1 commerce event function
    static func setBNCCommerceEvent(_ bncCommerceEvent: BNCCommerceEvent) {
        
        let commerceEvent: [String: Any] = [
            "transactionID": bncCommerceEvent.transactionID ?? "",
            "affiliation": bncCommerceEvent.affiliation ?? "",
            "coupon": bncCommerceEvent.coupon ?? "",
            "currency": bncCommerceEvent.currency ?? "",
            "shipping": "\(String(describing: bncCommerceEvent.shipping))",
            "tax": "\(String(describing: bncCommerceEvent.tax))",
            "revenue": "\(String(describing: bncCommerceEvent.revenue))"
        ]
        self.setBNCProducts(bncCommerceEvent.products!)
        self.setCommerceEvent(commerceEvent)
    }
    
    static func productDefaults() -> [String: String] {
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
    
    static func products() -> [[String : String]] {
        return userDefaults.array(forKey: "Products") as? [[String : String]] ?? [[String: String]]()
    }
    
    static func productsWithAddedProduct(_ product: [String : String]) -> [[String : String]] {
        var products = self.products()
        products.append(product)
        self.setProducts(products)
        return products
    }
    
    static func setProducts(_ products: [[String: String]]) {
        userDefaults.set(products, forKey: "Products")
    }
    
    static func bNCProducts() -> [BNCProduct] {
        let bncProduct = BNCProduct.init()
        let products = self.products()
        
        if products.count > 0 {
            return products.map({
                (product: [String: String]) -> BNCProduct in
                
                let defaults = self.productDefaults()
                
                bncProduct.name = product["name"] ?? defaults["name"]
                bncProduct.brand = product["brand"] ?? defaults["brand"]
                bncProduct.sku = product["sku"] ?? defaults["sku"]
                bncProduct.price = self.stringToNSDecimalNumber(with: product["price"] ?? defaults["price"]!)
                bncProduct.quantity = self.stringToNSDecimalNumber(with: product["quantity"] ?? defaults["quantity"]!)
                bncProduct.category = (product["category"] ?? defaults["category"]).map { BNCProductCategory(rawValue: $0) }
                bncProduct.variant = product["variant"] ?? defaults["variant"]
                
                return bncProduct
            })
        } else {
            let defaults = self.productDefaults()
            
            bncProduct.name = defaults["name"]
            bncProduct.brand = defaults["brand"]
            bncProduct.sku = defaults["sku"]
            bncProduct.price = self.stringToNSDecimalNumber(with: defaults["price"]!)
            bncProduct.quantity = self.stringToNSDecimalNumber(with: defaults["quantity"]!)
            bncProduct.category = defaults["category"].map { BNCProductCategory(rawValue: $0) }
            bncProduct.variant = defaults["variant"]
            
            return [bncProduct]
        }
    }
    
    static func setBNCProducts(_ products: [BNCProduct]) {
        var productsArray = [[String:String]]()
        for bncProduct in products {
            productsArray.append([
                "name": bncProduct.name ?? "",
                "brand": bncProduct.brand ?? "",
                "sku": bncProduct.sku ?? "",
                "price": "\(String(describing: bncProduct.price))" ,
                "quantity": "\(String(describing: bncProduct.quantity))" ,
                "category": bncProduct.category?.rawValue ?? "",
                "variant": bncProduct.variant ?? ""
                ])
        }
        self.setProducts(productsArray)
    }
    
    static func commerceEventCustomMetadata() -> [String: AnyObject] {
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
    
    static func productCategories() -> [String] {
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
    
    static func currencies() -> [String] {
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

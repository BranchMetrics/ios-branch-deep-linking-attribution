//
//  BranchEvent.Test.swift
//  Branch-SDK-Tests
//
//  Created by edward on 10/9/17.
//  Copyright © 2017 Branch, Inc. All rights reserved.
//

import XCTest
/*
// TODO: fix this test class, requires modules which our testbed is not using
final class BranchEventTestSwift : XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        Branch.getInstance("key_live_foo")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testBranchEvent() throws {

        // Set up the Branch Universal Object --

        let branchUniversalObject = BranchUniversalObject.init()
        branchUniversalObject.canonicalIdentifier = "item/12345"
        branchUniversalObject.canonicalUrl        = "https://branch.io/deepviews"
        branchUniversalObject.title               = "My Content Title"
        branchUniversalObject.contentDescription  = "my_product_description1"
        branchUniversalObject.imageUrl            = "https://test_img_url"
        branchUniversalObject.keywords            = [ "My_Keyword1", "My_Keyword2" ]
        branchUniversalObject.creationDate        = Date.init(timeIntervalSince1970:1501869445321.0/1000.0)
        branchUniversalObject.expirationDate      = Date.init(timeIntervalSince1970:212123232544.0/1000.0)
        branchUniversalObject.locallyIndex        = true
        branchUniversalObject.publiclyIndex       = false

        branchUniversalObject.contentMetadata.contentSchema     = .commerceProduct
        branchUniversalObject.contentMetadata.quantity          = 2
        branchUniversalObject.contentMetadata.price             = 23.20
        branchUniversalObject.contentMetadata.currency          = .USD
        branchUniversalObject.contentMetadata.sku               = "1994320302"
        branchUniversalObject.contentMetadata.productName       = "my_product_name1"
        branchUniversalObject.contentMetadata.productBrand      = "my_prod_Brand1"
        branchUniversalObject.contentMetadata.productCategory   = .babyToddler
        branchUniversalObject.contentMetadata.productVariant    = "3T"
        branchUniversalObject.contentMetadata.condition         = .fair

        branchUniversalObject.contentMetadata.ratingAverage     = 5;
        branchUniversalObject.contentMetadata.ratingCount       = 5;
        branchUniversalObject.contentMetadata.ratingMax         = 7;
        branchUniversalObject.contentMetadata.rating            = 6;
        branchUniversalObject.contentMetadata.addressStreet     = "Street_name1"
        branchUniversalObject.contentMetadata.addressCity       = "city1"
        branchUniversalObject.contentMetadata.addressRegion     = "Region1"
        branchUniversalObject.contentMetadata.addressCountry    = "Country1"
        branchUniversalObject.contentMetadata.addressPostalCode = "postal_code"
        branchUniversalObject.contentMetadata.latitude          = 12.07
        branchUniversalObject.contentMetadata.longitude         = -97.5
        branchUniversalObject.contentMetadata.imageCaptions     = [
            "my_img_caption1",
            "my_img_caption_2"
        ]
        branchUniversalObject.contentMetadata.customMetadata    = [
            "Custom_Content_metadata_key1": "Custom_Content_metadata_val1",
            "Custom_Content_metadata_key2": "Custom_Content_metadata_val2"
        ]

        // Set up the event properties --

        let event = BranchEvent.standardEvent(.purchase)
        event.transactionID    = "12344555"
        event.currency         = .USD;
        event.revenue          = 1.5
        event.shipping         = 10.2
        event.tax              = 12.3
        event.coupon           = "test_coupon";
        event.affiliation      = "test_affiliation";
        event.eventDescription = "Event _description";
        event.searchQuery      = "Query"
        event.customData       = [
            "Custom_Event_Property_Key1": "Custom_Event_Property_val1",
            "Custom_Event_Property_Key2": "Custom_Event_Property_val2"
        ]

        var testDictionary = event.dictionary()
        var dictionary = self.mutableDictionaryFromBundleJSON(withKey: "V2EventProperties")
        XCTAssert((dictionary?.isEqual(to: testDictionary))!)

        testDictionary = branchUniversalObject.dictionary() as! [AnyHashable : Any]
        dictionary = self.mutableDictionaryFromBundleJSON(withKey: "BranchUniversalObjectJSON")
        dictionary!["$publicly_indexable"] = nil // Remove this value since we don't add false values.
        XCTAssert((dictionary?.isEqual(to: testDictionary))!)

        event.contentItems = [ branchUniversalObject ]
        event.logEvent()
    }

    func testExampleSyntaxSwift() throws {
        let contentItem = BranchUniversalObject.init()
        contentItem.canonicalIdentifier = "item/123"
        contentItem.canonicalUrl = "https://branch.io/item/123"
        contentItem.contentMetadata.ratingAverage = 5.0;

        var event = BranchEvent.standardEvent(.spendCredits)
        event.transactionID = "tx1234"
        event.eventDescription = "Product Search"
        event.searchQuery = "user search query terms for product xyz"
        event.customData["Custom_Event_Property_Key1"] = "Custom_Event_Property_val1"
        event.contentItems = [ contentItem ]
        event.logEvent()

        event = BranchEvent.standardEvent(.viewItem)
        event.logEvent();

        // Quickly log an event:
        BranchEvent.standardEvent(.viewItem).logEvent()

        // Quickly log an event with content:
        let branchUniversalObject = BranchUniversalObject.init()
        branchUniversalObject.canonicalIdentifier = "item/12345"
        branchUniversalObject.canonicalUrl        = "https://branch.io/deepviews"
        branchUniversalObject.title               = "My Content Title"
        BranchEvent.standardEvent(.viewItem, withContentItem: branchUniversalObject).logEvent()
    }
}
*/

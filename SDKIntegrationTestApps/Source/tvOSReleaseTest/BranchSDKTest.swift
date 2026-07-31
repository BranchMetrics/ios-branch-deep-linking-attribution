//
//  BranchSDKTest.swift
//  iOSReleaseTest
//
//  Created by Nidhi Dixit on 1/31/23.
//

import Foundation
import BranchSDK
// BranchAttributionLevel lives in the BranchObjCSDK sibling module of the BranchSDK product.
import BranchObjCSDK

class BranchSDKTest {
    
    init(callback: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        Branch.sharedInstance().requestDeepLinkData(launchOptions: nil, callback: callback)
    }

    func setCPPLevel( status: BranchAttributionLevel)  {
        Branch.sharedInstance().setConsumerProtectionAttributionLevel(status)
    }
}

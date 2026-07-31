//
//  BranchSDKTest.swift
//  iOSReleaseTest
//
//  Created by Nidhi Dixit on 1/31/23.
//

import Foundation
import BranchSDK
// Under SwiftPM, BranchAttributionLevel lives in the sibling BranchObjCSDK module; other integration
// methods ship a single BranchSDK module, so import it only when it exists.
#if canImport(BranchObjCSDK)
import BranchObjCSDK
#endif

class BranchSDKTest {
    
    init(callback: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        Branch.sharedInstance().requestDeepLinkData(launchOptions: nil, callback: callback)
    }

    func setCPPLevel( status: BranchAttributionLevel)  {
        Branch.sharedInstance().setConsumerProtectionAttributionLevel(status)
    }
}

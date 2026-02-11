//
//  BranchSDKTest.swift
//  iOSReleaseTest
//
//  Created by Nidhi Dixit on 1/31/23.
//

import Foundation
import BranchSDK

class BranchSDKTest {
    
    init(callback: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        Branch.getInstance().initSession(launchOptions:nil, andRegisterDeepLinkHandler: callback)
    }
    
    func setCPPLevel( status: BranchAttributionLevel)  {
        Branch.getInstance().setConsumerProtectionAttributionLevel(status)
    }
}

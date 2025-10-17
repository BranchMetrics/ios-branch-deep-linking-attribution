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
       // Branch.getInstance().enableLogging()
       // Branch.getInstance().initSession(launchOptions: nil, callback: callback)
        Branch.getInstance().initSession(launchOptions:nil, andRegisterDeepLinkHandler: callback)
    }
    
    func disableTracking( status: Bool)  {
        Branch.setTrackingDisabled(status)
    }
    
    func trackingStatus() -> Bool {
       return Branch.trackingDisabled()
    }
}

//
//  BranchSDKTest.swift
//  iOSReleaseTest
//
//  Created by Nidhi Dixit on 1/31/23.
//

import Foundation
import BranchSDK

class BranchSDKTest {
    
    init() {
        Branch.init()
    }
    
    func disableTracking( status: Bool)  {
        Branch.setTrackingDisabled(status)
    }
    
    func trackingStatus() -> Bool {
       return Branch.trackingDisabled()
    }
}

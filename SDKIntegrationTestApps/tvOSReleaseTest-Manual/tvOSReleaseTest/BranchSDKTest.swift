//
//  File.swift
//  tvOSReleaseTest
//
//  Created by Nidhi Dixit on 1/31/23.
//

import Foundation
import BranchSDK

class BranchSDKTest {
    
    init() {
        Branch.getInstance().enableLogging()
        Branch.getInstance().initSession(launchOptions: nil) { (params, error) in
              print(params as? [String: AnyObject] ?? {})
          }
    }
    
    func disableTracking( status: Bool)  {
        Branch.setTrackingDisabled(status)
    }
    
    func trackingStatus() -> Bool {
       return Branch.trackingDisabled()
    }
}

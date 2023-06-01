//  CommonMethod.swift
//  DeepLinkDemo
//  Created by Rakesh kumar on 4/18/22.


import Foundation
import UIKit
import BranchSDK
import SystemConfiguration


class CommonMethod {
    
    static let sharedInstance = CommonMethod()
    var branchUniversalObject = BranchUniversalObject()
    var linkProperties = BranchLinkProperties()
    var contentMetaData : BranchContentMetadata? = nil
    
    var branchData = [String: AnyObject]()

    func navigatetoContent(onCompletion:@escaping (NSDictionary?) -> Void) -> Void {
        guard let data = branchData as? [String: AnyObject] else { return }
        onCompletion(data as NSDictionary)
    }
    
    func showActionAlertView(title:String,message:String,actions:[UIAlertAction],preferredStyle:UIAlertController.Style = .alert,viewController:UIViewController?) -> Void {
           let alertController = UIAlertController(title: title, message:message, preferredStyle: preferredStyle)
           if actions.isEmpty {
               alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                   viewController?.dismiss(animated: true, completion: nil)

               }))
           } else {
               for action in actions {
                   alertController.addAction(action)
               }
           }
      }
    
    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
         }
        }

       var flags = SCNetworkReachabilityFlags()

       if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
          return false
       }
       let isReachable = flags.contains(.reachable)
       let needsConnection = flags.contains(.connectionRequired)
       return (isReachable && !needsConnection)
    }
}

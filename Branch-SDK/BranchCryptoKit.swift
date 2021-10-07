//
//  BranchCryptoKit.swift
//  BranchSDK
//
//  Created by Nipun Singh on 10/6/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOSApplicationExtension 13.0, *)
@objc public class BranchCryptoKit: NSObject {
    
    @objc public func getSHA256(_ input: NSString) -> NSMutableString {
        let data = String(input).data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        let stringHash = hash.map { String(format: "%02hhx", $0) }.joined()
        return stringHash as! NSMutableString
    }
}

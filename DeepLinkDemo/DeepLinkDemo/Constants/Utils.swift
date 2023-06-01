//
//  Utils.swift
//  DeepLinkDemo
//
//  Created by Apple on 24/05/22.
//

import Foundation
import UIKit

class Utils: NSObject {
    
    static let shared = Utils()
    var logFileName: String?
    var prevCommandLogFileName: String?

    func clearAllLogFiles(){
        
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch  {
            NSLog("Failed to delete the file %@", error.localizedDescription)
        }

    }

        
    func removeItem(_ relativeFilePath: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let absoluteFilePath = documentsDirectory.appendingPathComponent(relativeFilePath)
        try? FileManager.default.removeItem(at: absoluteFilePath)
    }
    
    func setLogFile(_ fileName: String?) {
        if fileName == nil {
            logFileName = nil
            return
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0]
        let pathForLog = "\(documentsDirectory)/\(fileName ?? "app").log"
        self.removeItem(pathForLog)
        if (logFileName == nil) {
            logFileName = pathForLog
            prevCommandLogFileName = logFileName
        } else {
            prevCommandLogFileName = logFileName
            logFileName = pathForLog
        }
        let cstr = (pathForLog as NSString).utf8String
        freopen(cstr, "a+", stderr)

    }
}


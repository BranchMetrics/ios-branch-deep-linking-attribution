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
    
     func printLogMessage(_ message: String) {
         objc_sync_enter(self)
             do {
                 print(message) // print to console
                 
                 if !FileManager.default.fileExists(atPath: logFileName!) {   // does it exits?
                     FileManager.default.createFile(atPath: logFileName!, contents: nil)
                 }
                 
                 if let data = message.data(using: .utf8) {
                     let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFileName!))
                     if #available(iOS 13.4, *) {
                         print(" ============= ********** Writing in file " + logFileName!)
                         try fileHandle.seekToEnd()
                         try fileHandle.write(contentsOf: data)
                         try fileHandle.close()
                     } else {
                         print("Unable to write log: iOS Version not supported")
                     }
                 }
             } catch let error as NSError {                              // something wrong
                 print("Unable to write log: \(error.debugDescription)") // debug printout
             }
         objc_sync_exit(self)
    }
}


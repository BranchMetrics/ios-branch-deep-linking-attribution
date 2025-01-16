//
//  AppDelegate.swift
//  SwiftUITest
//
//  Created by Nipun Singh on 9/18/24.
//

import SwiftUI
import BranchSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        redirectConsoleLogs()
        
        Branch.enableLogging(at: .verbose, withCallback: nil)
        
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            guard let data = params as? [String: AnyObject] else { return }
            print("Branch Params: \(params ?? [:])")
            
            if (data["+clicked_branch_link"] as! Bool) == true {
                self.showAlert(withParams: params ?? [:])
            }
        }
        
        return true
    }
    
    func showAlert(withParams params: [AnyHashable: Any]) {
        // Convert params to a readable string
        let paramsString = params.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        // Create alert
        let alert = UIAlertController(title: "✅ Successfully Deep Linked", message: paramsString, preferredStyle: .alert)
        
        // Add OK action
        alert.addAction(UIAlertAction(title: "Nice", style: .default, handler: nil))
        
        // Present alert
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
    
    func redirectConsoleLogs() {
        let logsFilePath = getLogFilePath()
        freopen(logsFilePath, "a+", stdout)
        freopen(logsFilePath, "a+", stderr)
        print("App started and console redirection initialized.")
    }
    
    func getLogFilePath() -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("console.log").path
    }
}

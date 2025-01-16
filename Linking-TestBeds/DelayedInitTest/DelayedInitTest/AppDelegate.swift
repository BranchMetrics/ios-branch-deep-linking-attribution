//
//  AppDelegate.swift
//  DelayedInitTest
//
//  Created by Nipun Singh on 9/13/24.
//

import UIKit
import BranchSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        redirectConsoleLogs()
        
        Branch.enableLogging(at: .verbose, withCallback: nil)
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
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


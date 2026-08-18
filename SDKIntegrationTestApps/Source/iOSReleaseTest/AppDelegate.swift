//
//  AppDelegate.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import BranchSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        Branch.enableLogging()
      //  Branch.setUseTestBranchKey(true)

        let initStart = CFAbsoluteTimeGetCurrent()
        print("[BranchPerf] initSession: called at \(initStart)")

        Branch.getInstance().initSession(launchOptions: launchOptions) { params, error in
            let elapsed = (CFAbsoluteTimeGetCurrent() - initStart) * 1000.0
            print("[BranchPerf] initSession callback: received after \(String(format: "%.2f", elapsed)) ms")
            if let error = error {
                print("[BranchPerf] initSession callback: error = \(error.localizedDescription)")
            } else {
                print("[BranchPerf] initSession callback: success, params = \(params ?? [:])")
            }
        }

        return true
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


}


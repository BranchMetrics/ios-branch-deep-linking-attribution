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
        // Override point for customization after application launch.

        // Callback variant — NS_SWIFT_NAME:
        // Branch.sharedInstance()?.requestDeepLinkData(launchOptions: launchOptions) { params, error in
        //     print("Deep Link Params: \(params ?? [:]), error: \(String(describing: error))")
        // }

        // Async/await variant — NS_SWIFT_ASYNC_NAME:
        // Task {
        //     let params = try? await Branch.sharedInstance()?.requestDeepLinkData(launchOptions: launchOptions)
        //     print("Deep Link Params: \(params ?? [:])")
        // }

        // The remaining async variants — NS_SWIFT_ASYNC_NAME. Uncomment whichever you want to run.
        // These should only be called after the deep link request above completes, so they are
        // shown here as one sequential Task.
        // Task {
        //     // setUserAlias:completion: -> setUserAlias(_:)
        //     if let params = try? await Branch.sharedInstance()?.setUserAlias("test_user_alias") {
        //         print("Set User Alias Params: \(params)")
        //     }
        //
        //     // getShortURLWithParams:andCallback: -> getShortURL(params:)
        //     if let url = try? await Branch.sharedInstance()?.getShortURL(params: ["$og_title": "Async Example"]) {
        //         print("Short URL: \(url)")
        //     }
        //
        //     // lastAttributedTouchDataWithAttributionWindow:completion: -> lastAttributedTouchData(attributionWindow:)
        //     if let latd = try? await Branch.sharedInstance()?.lastAttributedTouchData(attributionWindow: 30) {
        //         print("Last Attributed Touch Data: \(latd.lastAttributedTouchJSON)")
        //     }
        //
        //     // BranchEvent logEventWithCompletion: -> logEventAsync()
        //     if let success = try? await BranchEvent.standardEvent(.purchase).logEventAsync() {
        //         print("Log Event Succeeded: \(success)")
        //     }
        //
        //     // logoutWithCallback: -> logoutAsync()
        //     if let changed = try? await Branch.sharedInstance()?.logoutAsync() {
        //         print("Logout Changed: \(changed)")
        //     }
        // }

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


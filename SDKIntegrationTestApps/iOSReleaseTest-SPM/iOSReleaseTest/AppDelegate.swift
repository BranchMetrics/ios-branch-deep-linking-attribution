//
//  AppDelegate.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import BranchSDK
import GoogleUtilities_Logger
import GoogleUtilities_Network
import GoogleAdsOnDeviceConversion


@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GULSetLoggerLevel(.max)
        // Override point for customization after application launch.
     /*   Branch.getInstance().enableLogging()
       // Set the time when the app was first launched.
        ConversionManager.sharedInstance.setFirstLaunchTime(Date())

        // Fetch the conversion info.
        ConversionManager.sharedInstance.fetchAggregateConversionInfo(for: .installation)
        { aggregateConversionInfo, error in
            print("Conversion info Error  ************** \(error)")
           guard error == nil else { return }
           guard let info = aggregateConversionInfo else {
              // Troubleshoot:
              // 1. Check that the Date passed to setFirstLaunchTime() was when the app
              //    first launched.
              // 2. Check that your app is running in an approved region.
              return
           }
           guard info.count > 0 else { return }

           print("Conversion info ************** \(info)")
           // Use info as the value in the odm_info query parameter in
           // the App Conversion API detailed in Step 6.
           // For example, if info is "abcdEfadGdaf", then odm_info=abcdEfadGdaf.
        }
        */
        Branch.enableLogging(at: .verbose) { msg,level , error in
            print(msg)
        }
        Branch.getInstance().initSession(launchOptions: nil) { (params, error) in
              print(params as? [String: AnyObject] ?? {})
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


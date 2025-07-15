//
//  AppDelegate.swift
//  TestDeepLinking
//
//  Created by Nidhi on 3/20/21.
//

import UIKit
import Branch

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        BranchScene.shared().initSession(launchOptions: launchOptions, registerDeepLinkHandler: { (params, error, scene) in
            let presentedVC : ViewController =  UIApplication.shared.keyWindow?.rootViewController as! ViewController
            let jsonData = try! JSONSerialization.data(withJSONObject:params, options: JSONSerialization.WritingOptions.prettyPrinted)

            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

            presentedVC.addText(jsonString)
        })
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


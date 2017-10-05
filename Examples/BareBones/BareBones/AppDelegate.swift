//
//  AppDelegate.swift
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions:[UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        AppStats.shared.initialize()
        Branch.getInstance().initSession(launchOptions: launchOptions)
        return true
    }

    func application(_ application: UIApplication,
             continue userActivity: NSUserActivity,
                restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        return true
    }

    func application(_ application: UIApplication,
                          open url: URL,
                           options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(application, open: url, options: options)
        return true
    }

}

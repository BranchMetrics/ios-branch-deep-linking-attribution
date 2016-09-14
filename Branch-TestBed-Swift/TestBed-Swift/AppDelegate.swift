//
//  AppDelegate.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let branch = Branch.getInstance()
        branch?.setDebug()

        // Automatic Deeplinking on "~referring_link"
        let navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
        branch?.registerDeepLinkController(navigationController, forKey:"~referring_link")
        
        // Required. Initialize session. automaticallyDisplayDeepLinkController is optional (default is false).
        branch?.initSession(launchOptions: launchOptions, automaticallyDisplayDeepLinkController: true, deepLinkHandler: { params, error in
            
            if (error == nil) {
                
                // Deeplinking logic for use when automaticallyDisplayDeepLinkController = false
                /*
                if let clickedBranchLink = params[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] as! Bool? {
                    
                    if clickedBranchLink {
                 
                        let nc = self.window!.rootViewController as! UINavigationController
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let logOutputViewController = storyboard.instantiateViewControllerWithIdentifier("LogOutput") as! LogOutputViewController
                        nc.pushViewController(logOutputViewController, animated: true)
                 
                        let dict = params as Dictionary
                        let referringLink = dict["~referring_link"]
                        let logOutput = String(format:"\nReferring link: \(referringLink)\n\nSession Details:\n\(dict.JSONDescription())")
                        logOutputViewController.logOutput = logOutput
                 
                    }
                } else {
                    print(String(format: "Branch TestBed: Finished init with params\n%@", params.description))
                }
                */
 
            } else {
                print("Branch TestBed: Initialization failed\n%@", error!.localizedDescription)
            }
        })
        return true
    }

    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if (!Branch.getInstance().handleDeepLink(url)) {
            // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        }
        
        return true
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity);
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification launchOptions: [AnyHashable: Any]) -> Void {
        Branch.getInstance().handlePushNotification(launchOptions)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    }

}


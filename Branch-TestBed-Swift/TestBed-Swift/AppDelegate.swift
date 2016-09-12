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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let branch = Branch.getInstance()
        branch.setDebug()

        // Automatic Deeplinking on "~referring_link"
        let navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
        branch.registerDeepLinkController(navigationController, forKey:"~referring_link")
        
        // Required. Initialize session. automaticallyDisplayDeepLinkController is optional (default is false).
        branch.initSessionWithLaunchOptions(launchOptions, automaticallyDisplayDeepLinkController: true, deepLinkHandler: { params, error in
            
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
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if (!Branch.getInstance().handleDeepLink(url)) {
            // do other deep link routing for the Facebook SDK, Pinterest SDK, etc
        }
        
        return true
    }
    
    // Respond to Universal Links
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continueUserActivity(userActivity);
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification launchOptions: [NSObject: AnyObject]) -> Void {
        Branch.getInstance().handlePushNotification(launchOptions)
    }
    
    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    
    func applicationDidBecomeActive(application: UIApplication) {
    }
    
    func applicationWillTerminate(application: UIApplication) {
    }

}


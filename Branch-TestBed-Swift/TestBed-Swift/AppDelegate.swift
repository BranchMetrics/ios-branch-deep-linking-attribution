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
        
        let defaultBranchKey = Bundle.main.object(forInfoDictionaryKey: "branch_key") as! String
        var branchKey = defaultBranchKey
        
        if let pendingBranchKey = DataStore.getPendingBranchKey() as String? {
            if pendingBranchKey != "" {
                branchKey = pendingBranchKey
            }
            DataStore.setActiveBranchKey(branchKey)
        } else {
            branchKey = defaultBranchKey
            DataStore.setActiveBranchKey(defaultBranchKey)
        }
        
        if let branch = Branch.getInstance(branchKey) {
            
            branch.setDebug();
            if DataStore.getPendingSetDebugEnabled()! {
                branch.setDebug()
                DataStore.setActivePendingSetDebugEnabled(true)
            } else {
                DataStore.setActivePendingSetDebugEnabled(false)
            }
            branch.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { (params, error) in
                if (error == nil) {
                    
                    // Deeplinking logic for use when automaticallyDisplayDeepLinkController = false
                    if let clickedBranchLink = params?[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] as! Bool? {
                        
                        if clickedBranchLink {
                            
                            let nc = self.window!.rootViewController as! UINavigationController
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let contentViewController = storyboard.instantiateViewController(withIdentifier: "Content") as! ContentViewController
                            nc.pushViewController(contentViewController, animated: true)
                            contentViewController.contentType = "Content"
                            
                            
                        }
                    } else {
                        print(String(format: "Branch TestBed: Finished init with params\n%@", (params?.description)!))
                    }
                    
                    
                } else {
                    print("Branch TestBed: Initialization failed: " + error!.localizedDescription)
                }
                let notificationName = Notification.Name("BranchCallbackCompleted")
                NotificationCenter.default.post(name: notificationName, object: nil)

            })
            
        } else {
            print("Branch TestBed: Invalid Key\n")
            DataStore.setActiveBranchKey("")
            DataStore.setPendingBranchKey("")
        }
        return true
    }
    
    // Respond to URL scheme links
    func application(_ application: UIApplication,
                          open url: URL,
                 sourceApplication: String?,
                        annotation: Any) -> Bool {

        let branchHandled = Branch.getInstance().application(application,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation
        )
        if (!branchHandled) {
            // If not handled by Branch, do other deep link routing for the Facebook SDK, Pinterest SDK, etc
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


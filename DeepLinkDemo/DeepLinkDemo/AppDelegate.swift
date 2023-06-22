//
//  AppDelegate.swift
//  DeepLinkDemo
//
//  Created by Rakesh kumar on 4/15/22.
//

import UIKit
import BranchSDK
import IQKeyboardManager
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    static var shared: AppDelegate {
        return (UIApplication.shared.delegate as? AppDelegate)!
        
    }
    var launchOption = [UIApplication.LaunchOptionsKey : Any]()
    var delegate: AppDelegate!
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("didFinishLaunchingWithOptions")
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            UNUserNotificationCenter.current().delegate = self
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                   if granted {
                       print("Allowed to send Notification")
                   } else {
                       print("Not allowed to send Notification")
                   }
               }
        }else{
            let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)
            _ = application.beginBackgroundTask(withName: "showNotification", expirationHandler: nil)
        }

        Utils.shared.clearAllLogFiles()
        Utils.shared.setLogFile("AppLaunch")
        IQKeyboardManager.shared().isEnabled = true
        StartupOptionsData.setActiveSetDebugEnabled(true)
        StartupOptionsData.setPendingSetDebugEnabled(true)
        Branch.setBranchKey("key_test_om2EWe1WBeBYmpz9Z1mdpopouDmoN72T")
        Branch.getInstance().enableLogging()
        getBranchData(launchOptions)
        Utils.shared.setLogFile("AppDelegate")
        return true
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        //check for link_click_id
        if url.absoluteString.contains("link_click_id") == true{
            return Branch.getInstance().application(app, open: url, options: options)
        }
        return true
    }
    
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // handler for Universal Links
        return Branch.getInstance().continue(userActivity)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // handler for Push Notifications
        Branch.getInstance().handlePushNotification(userInfo)
    }
    
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification launchOptions: [AnyHashable: Any]) -> Void {
        Branch.getInstance().handlePushNotification(launchOptions)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification){
        print(#function)
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void){
        print(#function)
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
        if(!branchHandled) {
            // If not handled by Branch, do other deep link routing for the Facebook SDK, Pinterest SDK, etc
            
        }
        return true
    }
    
    // Respond to Universal Links
    func application(_
                     application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void
    ) -> Bool {
        let branchHandled = Branch.getInstance().continue(userActivity)
        if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
            if let url = userActivity.webpageURL,
               !branchHandled {
                
            }
        }
        
        // Apply your logic to determine the return value of this method
        return true
    }
    
    
    func pushNewView() {
        if let controller = NavigateContentVC() as? NavigateContentVC {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(controller, animated: true, completion: nil)
            }
        }
    }
    func handleDeepLinkObject(object: BranchUniversalObject, linkProperties:BranchLinkProperties, error:NSError) {
        
        NSLog("Deep linked with object: %@.", object);
        let deeplinkText = object.contentMetadata.customMetadata.value(forKey: "deeplink_text")
        let textDetail = "Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@, \(String(describing: deeplinkText)) \(String(describing: Branch.getInstance().getLatestReferringParams()?.description))"
        NSLog(textDetail)
        self.pushNewView()
    }
    
    
    
    
    fileprivate func getBranchData(_ launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
        
        Branch.getInstance().initSession(
            launchOptions: launchOptions,
            automaticallyDisplayDeepLinkController: false,
            deepLinkHandler: { params, error in
                
                defer {
                    let notificationName = Notification.Name("BranchCallbackCompleted")
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
                
                guard error == nil else {
                    NSLog("Branch TestBed: Initialization failed: " + error!.localizedDescription)
                    return
                }
                
                guard let paramsDictionary = (params as? Dictionary<String, Any>) else {
                    NSLog("No Branch parameters returned")
                    return
                }
                
                let clickedBranchLink = params?[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] as! Bool?
                if  let referringLink = paramsDictionary["~referring_link"] as! String?,
                    let trackerId = paramsDictionary["ios_tracker_id"] as! String?,
                    let clickedBranchLink = clickedBranchLink,
                    clickedBranchLink {
                    var adjustUrl = URLComponents(string: referringLink)
                    var adjust_tracker:URLQueryItem
                    if referringLink.starts(with: "https://") || referringLink.starts(with: "http://") {
                        adjust_tracker = URLQueryItem(name: "adjust_t", value: trackerId)
                    } else {
                        adjust_tracker = URLQueryItem(name: "adjust_tracker", value: trackerId)
                    }
                    let adjust_campaign = URLQueryItem(name: "adjust_campaign", value: paramsDictionary[BRANCH_INIT_KEY_CAMPAIGN] as? String)
                    let adjust_adgroup = URLQueryItem(name: "adjust_adgroup", value: paramsDictionary[BRANCH_INIT_KEY_CHANNEL] as? String)
                    let adjust_creative = URLQueryItem(name: "adjust_creative", value: paramsDictionary[BRANCH_INIT_KEY_FEATURE] as? String)
                    let queryItems = [adjust_tracker,adjust_campaign,adjust_adgroup,adjust_creative]
                    adjustUrl?.queryItems = queryItems
//                    if let url = adjustUrl?.url {
//                        //Adjust.appWillOpen(url)
//                    }
                }
                // Deeplinking logic for use when automaticallyDisplayDeepLinkController = false
                if let clickedBranchLink = clickedBranchLink,
                   clickedBranchLink {
                    let nc = self.window!.rootViewController as! UINavigationController
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "DispalyVC") as? DispalyVC {
                        let linkurl = UserDefaults.standard.value(forKey: "link") as? String ?? ""
                        //let referringLink = paramsDictionary["~referring_link"] as! String
                        let content = String(format:"\nReferring link: %@ \n\nSession Details:\n %@", linkurl, paramsDictionary.jsonStringRepresentation!)
                        vc.textDescription = content
                        vc.appData = paramsDictionary
                        vc.linkURL = linkurl
                        nc.pushViewController(vc, animated: true)
                    }
                } else {
                    NSLog("Branch TestBed: Finished init with params\n%@", paramsDictionary.description)
                }
            })
    }
    
    
    func handleURL(_ url: URL) {
        guard url.pathComponents.count >= 3 else { return }
        
        let section = url.pathComponents[1]
        let detail = url.pathComponents[2]
        
        switch section {
        case "post":
            guard let id = Int(detail) else { break }
            // navigateToItem(id)
        case "settings":
            //navigateToSettings(detail)
            break
        default: break
        }
    }
    
}


@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate{
        
    func getApprovalForSendingNotification(){
        if #available(iOS 11.0, *) {
            let center = UNUserNotificationCenter.current()
            UNUserNotificationCenter.current().delegate = self
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                   if granted {
                       print("Allowed to send Notification")
                   } else {
                       print("Not allowed to send Notification")
                   }
               }
        }else{
            let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
        let content = response.notification.request.content
        print(content.userInfo)
        Branch.getInstance().handlePushNotification(content.userInfo)
    }

}
extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
            return nil
        }

        return String(data: theJSONData, encoding: .ascii)
    }
}

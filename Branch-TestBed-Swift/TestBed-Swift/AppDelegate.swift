//
//  AppDelegate.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate {
    
    var window: UIWindow?
    var _dateFormatter: DateFormatter?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let defaultBranchKey = Bundle.main.object(forInfoDictionaryKey: "branch_key") as! String
        var branchKey = defaultBranchKey
        
        if let pendingBranchKey = StartupOptionsData.getPendingBranchKey() as String? {
            if pendingBranchKey != "" {
                branchKey = pendingBranchKey
            }
            StartupOptionsData.setActiveBranchKey(branchKey)
        } else {
            branchKey = defaultBranchKey
            StartupOptionsData.setActiveBranchKey(defaultBranchKey)
        }
        
        activateAdjust()
        activateAdobe()
        activateAmplitude()
        activateAppsflyer()
        activateMixpanel()
        activateTune()
        
        if let branch = Branch.getInstance(branchKey) {
            
            if StartupOptionsData.getPendingSetDebugEnabled()! {
                branch.setDebug()
                StartupOptionsData.setActiveSetDebugEnabled(true)
            } else {
                StartupOptionsData.setActiveSetDebugEnabled(false)
            }
            // To use automaticallyDisplayDeepLinkController:
            // 1) Uncomment the following code block
            // 2) Comment out the code in the 'if (error == nil)' code block in initSession callback below
            // 3) Change automaticallyDisplayDeepLinkController to true
            /* let navigationController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! UINavigationController
             branch.registerDeepLinkController(navigationController, forKey:"~referring_link")*/
            
            // Required. Initialize session. automaticallyDisplayDeepLinkController is optional (default is false).
            branch.initSession(launchOptions: launchOptions, automaticallyDisplayDeepLinkController: false, deepLinkHandler: { params, error in
                
                defer {
                    let notificationName = Notification.Name("BranchCallbackCompleted")
                    NotificationCenter.default.post(name: notificationName, object: nil)
                }
                
                guard error == nil else {
                    print("Branch TestBed: Initialization failed: " + error!.localizedDescription)
                    return
                }
                
                guard let paramsDictionary = (params as? Dictionary<String, Any>) else {
                    print("No Branch parameters returned")
                    return
                }
                
                // Deeplinking logic for use when automaticallyDisplayDeepLinkController = false
                if let clickedBranchLink = params?[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] as! Bool? {
                    
                    if clickedBranchLink {
                        
                        let nc = self.window!.rootViewController as! UINavigationController
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let contentViewController = storyboard.instantiateViewController(withIdentifier: "Content") as! ContentViewController
                        nc.pushViewController(contentViewController, animated: true)
                        
                        let referringLink = paramsDictionary["~referring_link"] as! String
                        let content = String(format:"\nReferring link: \(referringLink)\n\nSession Details:\n\(paramsDictionary.JSONDescription())")
                        contentViewController.content = content
                        contentViewController.contentType = "Content"
                    }
                } else {
                    print(String(format: "Branch TestBed: Finished init with params\n%@", paramsDictionary.description))
                }
                
                // Amplitude
                if IntegratedSDKsData.activeMixpanelEnabled()! {
                    var userID: String
                    
                    if paramsDictionary["developer_identity"] != nil {
                        userID = paramsDictionary["developer_identity"] as! String
                    } else {
                        userID = "Anonymous"
                    }
                    
                    Amplitude.instance().setUserId(userID)
                    branch.setRequestMetadataKey("$amplitude_user_id",
                                                 value: userID as NSObject)
                }
                
                // Mixpanel
                if IntegratedSDKsData.activeMixpanelEnabled()! {
                    var userID: String
                    
                    if paramsDictionary["developer_identity"] != nil {
                        userID = paramsDictionary["developer_identity"] as! String
                    } else {
                        userID = "Anonymous"
                    }
                    
                    Mixpanel.sharedInstance()?.identify(userID)
                    branch.setRequestMetadataKey("$mixpanel_distinct_id",
                                                 value: userID as NSObject)
                }
                

            })
        } else {
            print("Branch TestBed: Invalid Key\n")
            StartupOptionsData.setActiveBranchKey("")
            StartupOptionsData.setPendingBranchKey("")
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
            

            // Adjust
            // TODO: Is this necessary?
            // Process non-Branch URIs here...
            // Adjust.appWillOpenUrl(url)
            
        }
        return true
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        // pass the url to the handle deep link call
        Branch.getInstance().continue(userActivity);

        // Adjust
        // TODO: Is any of this necessary?
        // Adjust.appWillOpenUrl(url)
        // NSURL *oldStyleDeeplink = [Adjust convertUniversalLink:url scheme:@"branchtest"];
        // [Adjust appWillOpenUrl:oldStyleDeeplink];
        
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
    
    // Mark - Adjust callbacks
    
    func adjustAttributionChanged(_attribution: ADJAttribution) {
        NSLog("adjust attribution %@", _attribution)
    }
    
    func adjustEventTrackingSucceeded(_eventSuccessResponseData: ADJEventSuccess) {
        NSLog("adjust event success %@", _eventSuccessResponseData)
    }
    
    func adjustEventTrackingFailed(_eventFailureResponseData: ADJEventFailure) {
        NSLog("adjust event failure %@", _eventFailureResponseData)
    }
    
    func adjustSessionTrackingSucceeded(_sessionSuccessResponseData: ADJSessionSuccess) {
        NSLog("adjust session success %@", _sessionSuccessResponseData)
    }
    
    func adjustSessionTrackingFailed(_sessionFailureResponseData: ADJSessionFailure) {
        NSLog("adjust session failure %@", _sessionFailureResponseData)
    }
    
    @objc func adjustDeeplinkResponse(_deeplink: NSURL!) -> Bool {
        return true
    }
    
    func activateAdjust() {
        guard IntegratedSDKsData.pendingAdjustEnabled()! else {
            IntegratedSDKsData.setActiveAdjustEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAdjustKey() as String? else {
            IntegratedSDKsData.setPendingAdjustEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingAdjustEnabled(false)
            return
        }
        
        IntegratedSDKsData.setActiveAdjustKey(key)
        IntegratedSDKsData.setActiveAdjustEnabled(true)

        let environment = ADJEnvironmentSandbox
        let adjustConfig = ADJConfig(appToken: key, environment: environment)

        // change the log level
        adjustConfig?.logLevel = ADJLogLevelVerbose

        // Enable event buffering.
        // adjustConfig.eventBufferingEnabled = true
        // Set default tracker.
        // adjustConfig.defaultTracker = "{TrackerToken}"
        // Send in the background.
        // adjustConfig.sendInBackground = true
        // set an attribution delegate
        adjustConfig?.delegate = self

        // Initialise the SDK.
        Adjust.appDidLaunch(adjustConfig!)

        // Put the SDK in offline mode.
        // Adjust.setOfflineMode(true);

        // Disable the SDK
        // Adjust.setEnabled(false);
    }
    
    func activateAdobe() {
        guard IntegratedSDKsData.pendingAdobeEnabled()! else {
            IntegratedSDKsData.setActiveAdobeEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAdobeKey() as String? else {
            IntegratedSDKsData.setPendingAdobeEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingAdobeEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAdobeKey(key)
        IntegratedSDKsData.setActiveAdobeEnabled(true)
    }
    
    func activateAmplitude() {
        guard IntegratedSDKsData.pendingAmplitudeEnabled()! else {
            IntegratedSDKsData.setActiveAmplitudeEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAmplitudeKey() as String? else {
            IntegratedSDKsData.setPendingAmplitudeEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingAmplitudeEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAmplitudeKey(key)
        IntegratedSDKsData.setActiveAmplitudeEnabled(true)
        
        Amplitude.instance().initializeApiKey(key)
        Amplitude.instance().logEvent("Amplitude Initialized")
    }
    
    func activateAppsflyer() {
        guard IntegratedSDKsData.pendingAppsflyerEnabled()! else {
            IntegratedSDKsData.setActiveAppsflyerEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAppsflyerKey() as String? else {
            IntegratedSDKsData.setPendingAppsflyerEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingAppsflyerEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAppsflyerKey(key)
        IntegratedSDKsData.setActiveAppsflyerEnabled(true)
    }
    
    func activateMixpanel() {
        guard IntegratedSDKsData.pendingMixpanelEnabled()! else {
            IntegratedSDKsData.setActiveMixpanelEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingMixpanelKey() as String? else {
            IntegratedSDKsData.setPendingMixpanelEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingMixpanelEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveMixpanelKey(key)
        IntegratedSDKsData.setActiveMixpanelEnabled(true)
        
        Mixpanel.sharedInstance(withToken: key)
    }
    
    func activateTune() {
        guard IntegratedSDKsData.pendingTuneEnabled()! else {
            IntegratedSDKsData.setActiveTuneEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingTuneKey() as String? else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        guard key.characters.count > 0 else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveTuneKey(key)
        IntegratedSDKsData.setActiveTuneEnabled(true)
    }
    
}


//
//  AppDelegate.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AdjustDelegate, AppsFlyerTrackerDelegate {
    
    var window: UIWindow?
    
    func application(_
        application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        Fabric.with([Crashlytics.self])

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
        
        // TODO: Remove before release
        //        StartupOptionsData.setActiveSetDebugEnabled(true)
        //        StartupOptionsData.setPendingSetDebugEnabled(true)
        //        IntegratedSDKsData.setActivemParticleEnabled(true)
        //        IntegratedSDKsData.setPendingmParticleEnabled(true)
        
        activateAdjust()
        activateAdobe()
        activateAmplitude()
        activateAppsflyer()
        activateAppMetrica()
        activateGoogleAnalytics()
        activateMixpanel()
        activateTune()
        activateAppboy(application: application, withLaunchOptions: launchOptions)
        activateClearTap()
        activateConvertro()
        activateKochava()
        activateLocalytics(withLaunchOptions: launchOptions)
        activatemParticle()
        activateSegment()
        activateSingular()
        activateStitch()
        
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
            
            branch.initSession(
                launchOptions: launchOptions,
                automaticallyDisplayDeepLinkController: false,
                deepLinkHandler: { params, error in
                
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
                

                let clickedBranchLink = params?[BRANCH_INIT_KEY_CLICKED_BRANCH_LINK] as! Bool?
                
                if  let referringLink = paramsDictionary["~referring_link"] as! String?,
                    let trackerId = paramsDictionary["ios_tracker_id"] as! String?,
                    let clickedBranchLink = clickedBranchLink,
                    clickedBranchLink {
                    var adjustUrl = URLComponents(string: referringLink)
                    var adjust_tracker:URLQueryItem
                    //
                    // Here's how to add Adjust attribution:
                    //
                    // Check if the deeplink is a Universal link.
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
                    if let url = adjustUrl?.url {
                        Adjust.appWillOpen(url)
                    }
                }
                
                // Deeplinking logic for use when automaticallyDisplayDeepLinkController = false
                if let clickedBranchLink = clickedBranchLink,
                   clickedBranchLink {
                    let nc = self.window!.rootViewController as! UINavigationController
                    let storyboard = UIStoryboard(name: "Content", bundle: nil)
                    let contentViewController = storyboard.instantiateViewController(withIdentifier: "Content") as! ContentViewController
                    nc.pushViewController(contentViewController, animated: true)
                    
                    let referringLink = paramsDictionary["~referring_link"] as! String
                    let content = String(format:"\nReferring link: \(referringLink)\n\nSession Details:\n\(paramsDictionary.JSONDescription())")
                    contentViewController.content = content
                    contentViewController.contentType = "Content"
                } else {
                    print(String(format: "Branch TestBed: Finished init with params\n%@", paramsDictionary.description))
                }
                
                // Adobe
                if IntegratedSDKsData.activeAdobeEnabled()! {
                    let adobeVisitorID = ADBMobile.trackingIdentifier()
                    
                    branch.setRequestMetadataKey("$adobe_visitor_id", value:adobeVisitorID)
                }
                
                
                // Amplitude
                if IntegratedSDKsData.activeAmplitudeEnabled()! {
                    var userID: String
                    
                    if paramsDictionary["developer_identity"] != nil {
                        userID = paramsDictionary["developer_identity"] as! String
                    } else {
                        userID = "Anonymous"
                    }
                    
                    Amplitude.instance().setUserId(userID)
                    branch.setRequestMetadataKey("$amplitude_user_id",
                                                 value: userID)
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
                                                 value: userID)
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
        if(!branchHandled) {
            // If not handled by Branch, do other deep link routing for the Facebook SDK, Pinterest SDK, etc
            Adjust.appWillOpen(url)
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
                Adjust.appWillOpen(url)
            }
        }
        
        // Apply your logic to determine the return value of this method
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification launchOptions: [AnyHashable: Any]) -> Void {
        Branch.getInstance().handlePushNotification(launchOptions)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Tune
        if IntegratedSDKsData.activeTuneEnabled()! {
            Tune.measureSession()
        }

        // AppsFlyer
        AppsFlyerTracker.shared().trackAppLaunch()
        // Your code here...
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
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
        guard let key = IntegratedSDKsData.pendingAdjustAppToken() as String? else {
            IntegratedSDKsData.setPendingAdjustEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingAdjustEnabled(false)
            return
        }
        
        IntegratedSDKsData.setActiveAdjustAppToken(key)
        IntegratedSDKsData.setActiveAdjustEnabled(true)

        let adjustConfig = ADJConfig(appToken: key, environment: ADJEnvironmentProduction)

        adjustConfig?.logLevel = ADJLogLevelVerbose
        adjustConfig?.delegate = self
        Adjust.appDidLaunch(adjustConfig!)
        
    }
    
    func activateAdobe() {
        guard IntegratedSDKsData.pendingAdobeEnabled()! else {
            IntegratedSDKsData.setActiveAdobeEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAdobeEnabled(true)
        
        ADBMobile.setDebugLogging(true)
        ADBMobile.collectLifecycleData()
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
        guard key.count > 0 else {
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
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingAppsflyerEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAppsflyerKey(key)
        IntegratedSDKsData.setActiveAppsflyerEnabled(true)
        
        AppsFlyerTracker.shared().appsFlyerDevKey = key
        AppsFlyerTracker.shared().appleAppID = "1160975066"
        AppsFlyerTracker.shared().delegate = self
        AppsFlyerTracker.shared().isDebug = true
    }
    
    func activateGoogleAnalytics() {
        guard IntegratedSDKsData.pendingGoogleAnalyticsEnabled()! else {
            IntegratedSDKsData.setActiveGoogleAnalyticsEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingGoogleAnalyticsTrackingID() as String? else {
            IntegratedSDKsData.setPendingGoogleAnalyticsEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingGoogleAnalyticsEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveGoogleAnalyticsTrackingID(key)
        IntegratedSDKsData.setActiveGoogleAnalyticsEnabled(true)
        
        guard let gai = GAI.sharedInstance() else {
            assert(false, "Google Analytics not configured correctly")
        }
        gai.tracker(withTrackingId: "key")
        // Optional: automatically report uncaught exceptions.
        gai.trackUncaughtExceptions = true
        
        // Optional: set Logger to VERBOSE for debug information.
        // Remove before app release.
        gai.logger.logLevel = .verbose;
        
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
        guard key.count > 0 else {
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
        guard let tuneAdvertisingID = IntegratedSDKsData.pendingTuneAdvertisingID() as String? else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        guard let tuneConversionKey = IntegratedSDKsData.pendingTuneConversionKey() as String? else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        guard tuneAdvertisingID.count > 0 else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        guard tuneConversionKey.count > 0 else {
            IntegratedSDKsData.setPendingTuneEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveTuneConversionKey(tuneAdvertisingID)
        IntegratedSDKsData.setActiveTuneConversionKey(tuneConversionKey)
        IntegratedSDKsData.setActiveTuneEnabled(true)

        Tune.registerDeeplinkListener(self)
        Tune.initialize(withTuneAdvertiserId: tuneAdvertisingID, tuneConversionKey: tuneConversionKey)
//        Tune.setDebugMode(true)
    }
    
    func activateAppboy(application: UIApplication, withLaunchOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard IntegratedSDKsData.pendingAppboyEnabled()! else {
            IntegratedSDKsData.setActiveAppboyEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAppboyAPIKey() as String? else {
            IntegratedSDKsData.setPendingAppboyEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingAppboyEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAppboyAPIKey(key)
        IntegratedSDKsData.setActiveAppboyEnabled(true)
        
        // TODO: Delegate method required for IDFA access?
        // see: https://www.appboy.com/documentation/iOS/#optional-idfa-collection
        // Appboy.start(withApiKey: key, in: application, withLaunchOptions: launchOptions, withAppboyOptions: appboyOptions)
        Appboy.start(withApiKey: key, in: application, withLaunchOptions: launchOptions)
    }
    
    func activateAppMetrica() {
        guard IntegratedSDKsData.pendingAppMetricaEnabled()! else {
            IntegratedSDKsData.setActiveAppMetricaEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingAppMetricaAPIKey() as String? else {
            IntegratedSDKsData.setPendingAppMetricaEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingAppMetricaEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveAppMetricaAPIKey(key)
        IntegratedSDKsData.setActiveAppMetricaEnabled(true)
        
        if let config = YMMYandexMetricaConfiguration.init(apiKey: key) {
            config.logs = true
            YMMYandexMetrica.activate(with: config)
        }
    }
    
    func activateClearTap() {
        guard IntegratedSDKsData.pendingClearTapEnabled()! else {
            IntegratedSDKsData.setActiveClearTapEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingClearTapAPIKey() as String? else {
            IntegratedSDKsData.setPendingClearTapEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingClearTapEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveClearTapAPIKey(key)
        IntegratedSDKsData.setActiveClearTapEnabled(true)
    }
    
    func activateConvertro() {
        guard IntegratedSDKsData.pendingConvertroEnabled()! else {
            IntegratedSDKsData.setActiveConvertroEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingConvertroAPIKey() as String? else {
            IntegratedSDKsData.setPendingConvertroEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingConvertroEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveConvertroAPIKey(key)
        IntegratedSDKsData.setActiveConvertroEnabled(true)
    }
    
    func activateKochava() {
        guard IntegratedSDKsData.pendingKochavaEnabled()! else {
            IntegratedSDKsData.setActiveKochavaEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingKochavaAPIKey() as String? else {
            IntegratedSDKsData.setPendingKochavaEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingKochavaEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveKochavaAPIKey(key)
        IntegratedSDKsData.setActiveKochavaEnabled(true)
    }
    
    func activateLocalytics(withLaunchOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        guard IntegratedSDKsData.pendingLocalyticsEnabled()! else {
            IntegratedSDKsData.setActiveLocalyticsEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingLocalyticsAppKey() as String? else {
            IntegratedSDKsData.setPendingLocalyticsEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingLocalyticsEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveLocalyticsAppKey(key)
        IntegratedSDKsData.setActiveLocalyticsEnabled(true)
        
        Localytics.setLoggingEnabled(true)
        Localytics.autoIntegrate(key, launchOptions: launchOptions)
    }
    
    func activatemParticle() {
        guard IntegratedSDKsData.pendingmParticleEnabled()! else {
            IntegratedSDKsData.setActivemParticleEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingmParticleAppKey() as String? else {
            IntegratedSDKsData.setPendingmParticleEnabled(false)
            return
        }
        guard let secret = IntegratedSDKsData.pendingmParticleAppSecret() as String? else {
            IntegratedSDKsData.setPendingmParticleEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingmParticleEnabled(false)
            return
        }
        guard secret.count > 0 else {
            IntegratedSDKsData.setPendingmParticleEnabled(false)
            return
        }
        IntegratedSDKsData.setActivemParticleAppKey(key)
        IntegratedSDKsData.setActivemParticleAppSecret(secret)
        IntegratedSDKsData.setActivemParticleEnabled(true)
        
        MParticle.sharedInstance().start(with: MParticleOptions.init(key: key, secret: secret))
    }
    
    func activateSegment() {
        guard IntegratedSDKsData.pendingSegmentEnabled()! else {
            IntegratedSDKsData.setActiveSegmentEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingSegmentAPIKey() as String? else {
            IntegratedSDKsData.setPendingSegmentEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingSegmentEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveSegmentAPIKey(key)
        IntegratedSDKsData.setActiveSegmentEnabled(true)
    }
    
    func activateSingular() {
        guard IntegratedSDKsData.pendingSingularEnabled()! else {
            IntegratedSDKsData.setActiveSingularEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingSingularAPIKey() as String? else {
            IntegratedSDKsData.setPendingSingularEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingSingularEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveSingularAPIKey(key)
        IntegratedSDKsData.setActiveSingularEnabled(true)
    }
    
    func activateStitch() {
        guard IntegratedSDKsData.pendingStitchEnabled()! else {
            IntegratedSDKsData.setActiveStitchEnabled(false)
            return
        }
        guard let key = IntegratedSDKsData.pendingStitchAPIKey() as String? else {
            IntegratedSDKsData.setPendingStitchEnabled(false)
            return
        }
        guard key.count > 0 else {
            IntegratedSDKsData.setPendingStitchEnabled(false)
            return
        }
        IntegratedSDKsData.setActiveStitchAPIKey(key)
        IntegratedSDKsData.setActiveStitchEnabled(true)
    }
    
}

extension AppDelegate:TuneDelegate {
    func tuneDidSucceed(with data: Data?) {
        let str = String(data: data!, encoding: String.Encoding.utf8)
        print("Tune success: \(String(describing: str))")
    }
    
    func tuneDidFailWithError(_ error: Error?) {
        print("Tune failed: \(String(describing: error))")
    }
    
    func tuneEnqueuedRequest(_ url: String?, postData post: String?) {
        print("Tune request enqueued: \(String(describing: url)), post data = \(String(describing: post))")
    }
}

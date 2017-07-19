//
//  AppDelegate.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Branch
import Crashlytics
import Fabric

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CrashlyticsDelegate {

    var window: UIWindow?
    var navigationController: NavigationController!
    var branch: Branch!

    // MARK: - UIApplicationDelegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])

        /*
         * Use the test instance if USE_BRANCH_TEST_INSTANCE is defined. This is defined in the
         * Test-Debug and Test-Release configurations, which are used by the WebViewExample-Test
         * schema. Use that schema for the test environment and the WebViewExample schema for the
         * live environment. This allows, e.g., building an archive for distribution using TestFlight
         * or Crashlytics that connects to the Branch test environment using the WebViewExample-Test
         * schema.
         */
        #if USE_BRANCH_TEST_INSTANCE
            branch = Branch.getTestInstance()
        #else
            branch = Branch.getInstance()
        #endif

        // Store the NavigationController for later link routing.
        navigationController = window?.rootViewController as? NavigationController

        // Initialize Branch SDK
        branch.initSession(launchOptions: launchOptions) {
            (buo: BranchUniversalObject?, linkProperties: BranchLinkProperties?, error: Error?) in
            guard error == nil else {
                BNCLogError("Error from Branch: \(error!)")
                return
            }

            guard let buo = buo else { return }
            self.routeURLFromBranch(buo)
        }

        let userDefaults = UserDefaults.standard
        var attempt = 0
        if userDefaults.object(forKey: "attempt_count") != nil {
            attempt = userDefaults.integer(forKey: "attempt_count")
        }
        attempt += 1
        Crashlytics.sharedInstance().setObjectValue(attempt, forKey: "attempt")

        logDeviceInfo()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return branch.application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return branch.continue(userActivity)
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        BNCLogWarning("Application did receive memory warning.")
        CLSLogv("Application did receive memory warning.", getVaList([]))
        Answers.logCustomEvent(withName: "UIApplicationDidReceiveMemoryWarning", customAttributes: nil)
    }

    // MARK: - Branch link routing

    private func routeURLFromBranch(_ buo: BranchUniversalObject) {
        guard let planetData = PlanetData(branchUniversalObject: buo) else { return }

        let articleViewController = ArticleViewController(planetData: planetData)
        navigationController.pushViewController(articleViewController, animated: true)
    }

    // MARK: - CrashlyticsDelegate

    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (Bool) -> Void) {
        BNCLog("Found Crashlytics report: \(report.identifier)")
        completionHandler(true)
    }

    func logDeviceInfo() {
        guard let deviceInfo = BNCDeviceInfo.getInstance() else {
            BNCLogWarning("Failed to get BNCDeviceInfo")
            CLSLogv("Failed to get BNCDeviceInfo", getVaList([]))
            return
        }

        let params: [String: Any] = [
            "hardwareId": deviceInfo.hardwareId,
            "hardwareIdType": deviceInfo.hardwareIdType,
            "isRealHardwareId": deviceInfo.isRealHardwareId ? "YES" : "NO",
            "vendorId": deviceInfo.vendorId,
            "brandName": deviceInfo.brandName,
            "modelName": deviceInfo.modelName,
            "osName": deviceInfo.osName,
            "osVersion": deviceInfo.osVersion,
            "screenWidth": "\(deviceInfo.screenWidth)",
            "screenHeight": "\(deviceInfo.screenHeight)",
            "isAdTrackingEnabled": deviceInfo.isAdTrackingEnabled ? "YES" : "NO",
            "country": deviceInfo.country,
            "language": deviceInfo.language,
            "browserUserAgent": deviceInfo.browserUserAgent
        ]
        Answers.logCustomEvent(withName: "BNCDeviceInfo", customAttributes: params)
        BNCLog("BNCDeviceInfo: \(params)")
        CLSLogv("BNCDeviceInfo: %@", getVaList([params]))
    }
}


//
//  AppDelegate.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController: NavigationController!

    // MARK: - UIApplicationDelegate methods

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Store the NavigationController for later link routing.
        navigationController = window?.rootViewController as? NavigationController

        // Initialize Branch SDK
        Branch.getInstance().initSession(launchOptions: launchOptions) {
            (buo: BranchUniversalObject?, linkProperties: BranchLinkProperties?, error: Error?) in
            guard error == nil else {
                BNCLogError("Error from Branch: \(error!)")
                return
            }

            guard let buo = buo else { return }
            self.routeURLFromBranch(buo)
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return Branch.getInstance().application(app, open: url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        return Branch.getInstance().continue(userActivity)
    }

    // MARK: - Branch link routing

    private func routeURLFromBranch(_ buo: BranchUniversalObject) {
        guard let planetData = PlanetData(branchUniversalObject: buo) else { return }

        let articleViewController = ArticleViewController(planetData: planetData)
        navigationController.pushViewController(articleViewController, animated: true)
    }
}


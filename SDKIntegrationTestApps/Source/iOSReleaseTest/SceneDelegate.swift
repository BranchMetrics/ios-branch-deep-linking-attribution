//
//  SceneDelegate.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import BranchSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        // Callback variant — NS_SWIFT_NAME:
        // Branch.sharedInstance().requestDeepLinkData(sceneOptions: connectionOptions, scene: scene) { params, error in
        //     print("Deep Link Params: \(params ?? [:]), error: \(String(describing: error))")
        // }

        // Async/await variant — NS_SWIFT_ASYNC_NAME:
        // Task {
        //     let params = try? await Branch.sharedInstance().requestDeepLinkData(sceneOptions: connectionOptions, scene: scene)
        //     print("Deep Link Params: \(params ?? [:])")
        // }

        // The remaining async variants — NS_SWIFT_ASYNC_NAME. Uncomment whichever you want to run.
        // These should only be called after the deep link request above completes, so they are
        // shown here as one sequential Task.
        // Task {
        //     // setUserAlias:completion: -> setUserAlias(_:)
        //     if let params = try? await Branch.sharedInstance().setUserAlias("test_user_alias") {
        //         print("Set User Alias Params: \(params)")
        //     }
        //
        //     // getShortURLWithParams:andCallback: -> getShortURL(params:)
        //     if let url = try? await Branch.sharedInstance().getShortURL(params: ["$og_title": "Async Example"]) {
        //         print("Short URL: \(url)")
        //     }
        //
        //     // lastAttributedTouchDataWithAttributionWindow:completion: -> lastAttributedTouchData(attributionWindow:)
        //     if let latd = try? await Branch.sharedInstance().lastAttributedTouchData(attributionWindow: 30) {
        //         print("Last Attributed Touch Data: \(latd.lastAttributedTouchJSON)")
        //     }
        //
        //     // BranchEvent logEventWithCompletion: -> logEventAsync()
        //     if let success = try? await BranchEvent.standardEvent(.purchase).logEventAsync() {
        //         print("Log Event Succeeded: \(success)")
        //     }
        //
        //     // logoutWithCallback: -> logoutAsync()
        //     if let changed = try? await Branch.sharedInstance().logoutAsync() {
        //         print("Logout Changed: \(changed)")
        //     }
        // }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Callback variant — NS_SWIFT_NAME:
        // Branch.sharedInstance().requestDeepLinkData(branchLink: userActivity.webpageURL?.absoluteString) { params, error in
        //     print("Deep Link Params: \(params ?? [:]), error: \(String(describing: error))")
        // }

        // Async/await variant — NS_SWIFT_ASYNC_NAME:
        // Task {
        //     let params = try? await Branch.sharedInstance().requestDeepLinkData(branchLink: userActivity.webpageURL?.absoluteString)
        //     print("Deep Link Params: \(params ?? [:])")
        // }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Callback variant — NS_SWIFT_NAME:
        // Branch.sharedInstance().requestDeepLinkData(branchLink: URLContexts.first?.url.absoluteString) { params, error in
        //     print("Deep Link Params: \(params ?? [:]), error: \(String(describing: error))")
        // }

        // Async/await variant — NS_SWIFT_ASYNC_NAME:
        // Task {
        //     let params = try? await Branch.sharedInstance().requestDeepLinkData(branchLink: URLContexts.first?.url.absoluteString)
        //     print("Deep Link Params: \(params ?? [:])")
        // }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}


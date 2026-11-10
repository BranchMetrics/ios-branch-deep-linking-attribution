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

        // Callback variant — NS_SWIFT_NAME. This callback also receives the results of the
        // openURLContexts and userActivity calls below for this scene.
        Branch.sharedInstance()?.requestDeepLinkData(sceneOptions: connectionOptions, scene: scene) { params, error, linkScene in
            print("Deep Link Params ***********************: \(params ?? [:]), error: \(String(describing: error)), scene: \(String(describing: linkScene))")
        }

        // Async/await variant — NS_SWIFT_ASYNC_NAME. Use instead of the callback variant above, not with it:
        // Task {
        //     let result = try? await Branch.sharedInstance()?.requestDeepLinkData(sceneOptions: connectionOptions, scene: scene)
        //     print("Deep Link Params: \(result?.0 ?? [:]), scene: \(String(describing: result?.1))")
        // }

        // The remaining async variants — NS_SWIFT_ASYNC_NAME. Uncomment whichever you want to run.
        // These should only be called after the deep link request above completes, so they are
        // shown here as one sequential Task.
        // Task {
        //     // setUserAlias:completion: -> setUserAlias(_:)
        //     if let params = try? await Branch.sharedInstance()?.setUserAlias("test_user_alias") {
        //         print("Set User Alias Params: \(params)")
        //     }
        //
        //     // getShortURLWithParams:andCallback: -> getShortURL(params:)
        //     if let url = try? await Branch.sharedInstance()?.getShortURL(params: ["$og_title": "Async Example"]) {
        //         print("Short URL: \(url)")
        //     }
        //
        //     // lastAttributedTouchDataWithAttributionWindow:completion: -> lastAttributedTouchData(attributionWindow:)
        //     if let latd = try? await Branch.sharedInstance()?.lastAttributedTouchData(attributionWindow: 30) {
        //         print("Last Attributed Touch Data: \(latd.lastAttributedTouchJSON)")
        //     }
        //
        //     // BranchEvent logEventWithCompletion: -> logEventAsync()
        //     if let success = try? await BranchEvent.standardEvent(.purchase).logEventAsync() {
        //         print("Log Event Succeeded: \(success)")
        //     }
        //
        //     // logoutWithCallback: -> logoutAsync()
        //     if let changed = try? await Branch.sharedInstance()?.logoutAsync() {
        //         print("Logout Changed: \(changed)")
        //     }
        // }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Universal Link or Spotlight on a warm start. The result goes to the sceneOptions callback.
        Branch.sharedInstance()?.requestDeepLinkData(scene: scene, userActivity: userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // URI scheme on a warm start. The result goes to the sceneOptions callback.
        Branch.sharedInstance()?.requestDeepLinkData(scene: scene, openURLContexts: URLContexts)
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


// MARK: - Scene 2

/// Names shared by the scene configurations in Info.plist and the code that opens them.
enum SceneKind {
    static let primaryConfiguration = "Default Configuration"
    static let secondaryConfiguration = "Secondary Configuration"
    /// Activity type passed to requestSceneSessionActivation to open Scene 2.
    static let secondaryActivityType = "io.branch.iOSReleaseTest.secondaryScene"

    /// Opens a new Scene 2 window. Needs a device that supports multiple windows (iPad, Mac).
    static func openSecondary() {
        let activity = NSUserActivity(activityType: secondaryActivityType)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print("Open Scene 2 failed: \(error)")
        }
    }

    /// Returns true when connectionOptions carry nothing but the activity that opened Scene 2.
    static func isOnlySecondaryActivation(_ options: UIScene.ConnectionOptions) -> Bool {
        return options.urlContexts.isEmpty
            && !options.userActivities.isEmpty
            && options.userActivities.allSatisfy { $0.activityType == secondaryActivityType }
    }
}

/// Delegate for the "Secondary Configuration" scene (Scene 2). Builds its window in code and
/// registers its own Branch deep link callback, separate from Scene 1's callback.
class SecondarySceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let controller = ViewController()
        controller.sceneName = "Scene 2"
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .systemBackground
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window

        // The activity that opened this scene is not a link, so it is not passed to Branch.
        let options: UIScene.ConnectionOptions? = SceneKind.isOnlySecondaryActivation(connectionOptions) ? nil : connectionOptions

        // Callback variant — NS_SWIFT_NAME. This callback also receives the results of the
        // openURLContexts and userActivity calls below for this scene.
        Branch.sharedInstance()?.requestDeepLinkData(sceneOptions: options, scene: scene) { params, error, linkScene in
            print(" **********: Scene 2 Deep Link Params: \(params ?? [:]), error: \(String(describing: error)), scene: \(String(describing: linkScene))")
        }

        // Async/await variant — NS_SWIFT_ASYNC_NAME. Use instead of the callback variant above, not with it:
        // Task {
        //     let result = try? await Branch.sharedInstance()?.requestDeepLinkData(sceneOptions: options, scene: scene)
        //     print("Scene 2 Deep Link Params: \(result?.0 ?? [:]), scene: \(String(describing: result?.1))")
        // }

        // The remaining async variants — NS_SWIFT_ASYNC_NAME. Uncomment whichever you want to run.
        // These should only be called after the deep link request above completes, so they are
        // shown here as one sequential Task.
        // Task {
        //     // setUserAlias:completion: -> setUserAlias(_:)
        //     if let params = try? await Branch.sharedInstance()?.setUserAlias("test_user_alias") {
        //         print("Scene 2 Set User Alias Params: \(params)")
        //     }
        //
        //     // getShortURLWithParams:andCallback: -> getShortURL(params:)
        //     if let url = try? await Branch.sharedInstance()?.getShortURL(params: ["$og_title": "Async Example"]) {
        //         print("Scene 2 Short URL: \(url)")
        //     }
        //
        //     // lastAttributedTouchDataWithAttributionWindow:completion: -> lastAttributedTouchData(attributionWindow:)
        //     if let latd = try? await Branch.sharedInstance()?.lastAttributedTouchData(attributionWindow: 30) {
        //         print("Scene 2 Last Attributed Touch Data: \(latd.lastAttributedTouchJSON)")
        //     }
        //
        //     // BranchEvent logEventWithCompletion: -> logEventAsync()
        //     if let success = try? await BranchEvent.standardEvent(.purchase).logEventAsync() {
        //         print("Scene 2 Log Event Succeeded: \(success)")
        //     }
        //
        //     // logoutWithCallback: -> logoutAsync()
        //     if let changed = try? await Branch.sharedInstance()?.logoutAsync() {
        //         print("Scene 2 Logout Changed: \(changed)")
        //     }
        // }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Universal Link or Spotlight on a warm start. The result goes to this scene's callback.
        Branch.sharedInstance()?.requestDeepLinkData(scene: scene, userActivity: userActivity)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // URI scheme on a warm start. The result goes to this scene's callback.
        Branch.sharedInstance()?.requestDeepLinkData(scene: scene, openURLContexts: URLContexts)
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // Lets the system restore this session as Scene 2.
        return NSUserActivity(activityType: SceneKind.secondaryActivityType)
    }
}

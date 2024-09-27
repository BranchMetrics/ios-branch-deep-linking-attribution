//
//  SceneDelegate.swift
//  DelayedInitTest
//
//  Created by Nipun Singh on 9/13/24.
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
        let firstOpen = false
        
        if !UserDefaults.standard.isFirstOpen {
            print("NOT First App Open")
            BranchScene.shared().initSession(registerDeepLinkHandler: { (params, error, scene) in
                guard let data = params as? [String: AnyObject] else { return }
                print("Branch Params: \(params ?? [:])")
                
                if (data["+clicked_branch_link"] as! Bool) == true {
                    self.showAlert(withParams: params ?? [:])
                }
            })
            
            if let userActivity = connectionOptions.userActivities.first {
                print("*** Branch Scene willConnectTo User Activity: \(userActivity)")
                BranchScene.shared().scene(scene, continue: userActivity)
            } else if !connectionOptions.urlContexts.isEmpty {
                print("*** Branch Scene willConnectTo connectionOptions.urlContexts: \(connectionOptions.urlContexts)")
                BranchScene.shared().scene(scene, openURLContexts: connectionOptions.urlContexts)
            }
        } else {
            print("First App Open")
        }
    }
    
    
    func showAlert(withParams params: [AnyHashable: Any]) {
        // Convert params to a readable string
        let paramsString = params.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        // Create alert
        let alert = UIAlertController(title: "✅ Succesfully Deep Linked ", message: paramsString, preferredStyle: .alert)
        
        // Add OK action
        alert.addAction(UIAlertAction(title: "Nice", style: .default, handler: nil))
        
        // Present alert
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
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
    
    func scene(_ scene: UIScene, willContinueUserActivityWithType userActivityType: String) {
        scene.userActivity = NSUserActivity(activityType: userActivityType)
        scene.delegate = self
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        print("*** Branch Scene continueUserActivity User Activity: \(userActivity)")
        BranchScene.shared().scene(scene, continue: userActivity)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("*** Branch Scene openURLContexts URLContexts: \(URLContexts)")
        BranchScene.shared().scene(scene, openURLContexts: URLContexts)
    }
}

extension UserDefaults {
    private enum Keys {
        static let firstOpen = "firstOpen"
    }
    
    /// Indicates whether the app is opened for the first time.
    var isFirstOpen: Bool {
        get {
            // If the key doesn't exist, it's the first open.
            return !bool(forKey: Keys.firstOpen)
        }
        set {
            // Set the key to true after the first open.
            set(!newValue, forKey: Keys.firstOpen)
        }
    }
}

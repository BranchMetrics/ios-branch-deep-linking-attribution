//
//  AppDelegate.swift
//  iOSReleaseTest
//
//  Created by Nipun Singh on 2/4/22.
//

import UIKit
import BranchSDK
import os

private let branchLog = Logger(subsystem: "io.branch.iOSReleaseTest", category: "BranchSDK")

/// Splits text into pieces of at most maxBytes UTF-8 bytes, never breaking a character.
/// The unified log truncates a single message at about 1024 bytes, so long Branch messages
/// (request/response bodies) are logged in numbered pieces instead.
private func logChunks(_ text: String, maxBytes: Int = 800) -> [String] {
    var chunks: [String] = []
    var current = ""
    var currentBytes = 0
    for character in text {
        let characterBytes = String(character).utf8.count
        if currentBytes + characterBytes > maxBytes, !current.isEmpty {
            chunks.append(current)
            current = ""
            currentBytes = 0
        }
        current.append(character)
        currentBytes += characterBytes
    }
    if !current.isEmpty || chunks.isEmpty {
        chunks.append(current)
    }
    return chunks
}

/// Sends a Branch log message to the unified log (Xcode console and Console.app).
/// Messages longer than one os_log entry are split into pieces that share an ID, e.g.
/// "[Branch][1A2B3C4D 2/5] ...". Filter on "[Branch]" or category "BranchSDK" to see them.
private func logBranchMessage(_ message: String, level: BranchLogLevel, error: Error?) {
    let text = error.map { "\(message) | \($0)" } ?? message
    let type: OSLogType
    switch level {
    case .error: type = .fault
    case .warning: type = .error
    default: type = .default
    }

    let chunks = logChunks(text)
    if chunks.count == 1 {
        branchLog.log(level: type, "[Branch] \(text, privacy: .public)")
    } else {
        let id = UUID().uuidString.prefix(8)
        for (index, chunk) in chunks.enumerated() {
            branchLog.log(level: type, "[Branch][\(id, privacy: .public) \(index + 1)/\(chunks.count)] \(chunk, privacy: .public)")
        }
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        guard let branchKeys = Bundle.main.object(forInfoDictionaryKey: "branch_key") as? [String: String],
              let liveKey = branchKeys["live"] else {
            branchLog.fault("[Branch] branch_key.live missing from Info.plist; Branch not initialized")
            return true
        }

        let configuration = BranchConfiguration(key: liveKey)
        configuration.logLevel = .verbose
        configuration.loggingCallback = { message, level, error in
            logBranchMessage(message, level: level, error: error)
        }
        // Send opens automatically on launch, on foreground and for resolved deep links.
        // This is the SDK default; it is set here so the test app does not depend on it.
        configuration.automaticOpenEvents = true

        do {
            try configuration.validate()
        } catch {
            branchLog.fault("[Branch] Invalid configuration: \(error.localizedDescription, privacy: .public)")
        }
        Branch.initialize(configuration)

        // Deep link handling runs from SceneDelegate. The AppDelegate variants below are for apps
        // without a scene manifest; do not enable them alongside the SceneDelegate calls.

        // Callback variant — NS_SWIFT_NAME:
        // Branch.sharedInstance()?.requestDeepLinkData(launchOptions: launchOptions) { params, error in
        //     print("Deep Link Params: \(params ?? [:]), error: \(String(describing: error))")
        // }

        // Async/await variant — NS_SWIFT_ASYNC_NAME:
        // Task {
        //     let params = try? await Branch.sharedInstance()?.requestDeepLinkData(launchOptions: launchOptions)
        //     print("Deep Link Params: \(params ?? [:])")
        // }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        // A scene opened with the Scene 2 activity uses the Secondary configuration; everything
        // else, including a scene the system opens for an incoming link, uses the Default one.
        if options.userActivities.contains(where: { $0.activityType == SceneKind.secondaryActivityType }) {
            return UISceneConfiguration(name: SceneKind.secondaryConfiguration, sessionRole: connectingSceneSession.role)
        }
        return UISceneConfiguration(name: SceneKind.primaryConfiguration, sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

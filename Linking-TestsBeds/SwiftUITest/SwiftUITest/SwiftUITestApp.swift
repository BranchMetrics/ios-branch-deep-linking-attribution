//
//  SwiftUITestApp.swift
//  SwiftUITest
//
//  Created by Nipun Singh on 9/13/24.
//

import SwiftUI
import BranchSDK

@main
struct SwiftUITestApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL(perform: { url in
                    print("[onOpenURL] Branch handling deep link: \(url)")
                    Branch.getInstance().handleDeepLink(url)
                })
        }
    }
}

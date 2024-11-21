//
//  UserDefaultsHelper.swify.swift
//  DelayedInitTest
//
//  Created by Nipun Singh on 9/19/24.
//

import Foundation

//extension UserDefaults {
//    private enum Keys {
//        static let firstOpen = "firstOpen"
//        static let launchOptionsData = "launchOptionsData"
//    }
//    
//    var isFirstOpen: Bool {
//        get {
//            return !bool(forKey: Keys.firstOpen)
//        }
//        set {
//            set(!newValue, forKey: Keys.firstOpen)
//        }
//    }
//    
//    func saveLaunchOptions(_ options: BranchLaunchOptions) {
//        if let data = try? JSONEncoder().encode(options) {
//            set(data, forKey: Keys.launchOptionsData)
//        }
//    }
//    
//    func retrieveLaunchOptions() -> BranchLaunchOptions? {
//        if let data = data(forKey: Keys.launchOptionsData),
//           let options = try? JSONDecoder().decode(BranchLaunchOptions.self, from: data) {
//            return options
//        }
//        return nil
//    }
//}

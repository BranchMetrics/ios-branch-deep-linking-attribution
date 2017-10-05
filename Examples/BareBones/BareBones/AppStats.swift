//
//  AppStats.swift
//  BareBones
//
//  Created by Edward Smith on 10/4/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import Foundation

extension NSNotification.Name {
    static let AppStatsDidUpdate = NSNotification.Name.init("AppStatsDidUpdateNotification")
}

class AppStats {
    var appOpens: Int {
        didSet { saveAndNotify() }
    }

    var linksOpened: Int {
        didSet { saveAndNotify() }
    }

    var linksCreated: Int {
        didSet { saveAndNotify() }
    }

    static let shared = AppStats()

    private init() {
        appOpens = UserDefaults.standard.integer(forKey: "appOpens")
        linksOpened = UserDefaults.standard.integer(forKey: "linksOpened")
        linksCreated = UserDefaults.standard.integer(forKey: "linksCreated")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppOpen(notification:)),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppOpen(notification:)),
            name: NSNotification.Name.UIApplicationDidFinishLaunching,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func initialize() {
        // Make sure we're loaded and initialized.
        // Nothing to do here, but calling this method makes sure we're lazy loaded.
    }

    @objc func updateAppOpen(notification: Notification) {
        self.appOpens += 1
    }

    func saveAndNotify() {
        UserDefaults.standard.set(appOpens, forKey: "appOpens")
        UserDefaults.standard.set(linksOpened, forKey: "linksOpened")
        UserDefaults.standard.set(linksCreated, forKey: "linksCreated")
        NotificationCenter.default.post(name: Notification.Name.AppStatsDidUpdate, object: self)
    }
}

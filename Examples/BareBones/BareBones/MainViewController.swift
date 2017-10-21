//
//  AppStatsViewController.swift
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class MainViewController: UIViewController {

    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    var enableShakes: Bool = false

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(branchWillStartSession(notification:)),
            name: NSNotification.Name.BranchWillStartSession,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(branchDidStartSession(notification:)),
            name: NSNotification.Name.BranchDidStartSession,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appStatsDidUpdate(notification:)),
            name: NSNotification.Name.AppDataDidUpdate,
            object: nil
        )
        updateStatsLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        messageLabel.text =
            "Shake the phone to reveal your mystic Branch fortune..."
        updateStatsLabel()
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.enableShakes = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.enableShakes = false
    }

    override func becomeFirstResponder() -> Bool {
        // Over-ride so this view controller can get shake events:
        return enableShakes ? true : false
    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake && enableShakes {
            self.startMysticConjuring()
        }
    }

    // MARK: - Notifications

    @objc func appStatsDidUpdate(notification: Notification) {
        updateStatsLabel()
    }

    @objc func branchWillStartSession(notification: Notification) {
        guard let url: URL = notification.userInfo?[BranchURLKey] as? URL else { return }
        WaitingViewController.showWithMessage(
            message: "Opening\n\(url.absoluteString)",
            activityIndicator: true,
            disableTouches: true
        )
    }

    @objc func branchDidStartSession(notification: Notification) {
        WaitingViewController.hide()

        let url : URL? = notification.userInfo?[BranchURLKey] as? URL

        if let error = notification.userInfo?[BranchErrorKey] as? Error {
            if let url = url {
                self.showAlert(
                    title: "Couldn't Open URL",
                    message: "\(url.absoluteString)\n\n\(error.localizedDescription)"
                )
            } else {
                self.showAlert(
                    title: "Error Starting Branch Session",
                    message: error.localizedDescription
                )
            }
            return
        }

        if let buo = notification.userInfo?[BranchUniversalObjectKey] as? BranchUniversalObject {
            let messageViewController = MessageViewController.instantiate()
            messageViewController.name = buo.metadata?["name"] as? String
            messageViewController.message = buo.metadata?["message"] as? String
            navigationController?.pushViewController(messageViewController, animated: true)
            AppData.shared.linksOpened += 1
            return
        }
    }

    // MARK: - Update the UI

    func updateStatsLabel() {
        statsLabel.text =
            "\(AppData.shared.appOpens)\n\(AppData.shared.linksOpened)\n\(AppData.shared.linksCreated)"
    }

    func startMysticConjuring() {
        self.enableShakes = false
        self.messageLabel.text = "Summoning mystic fortune spirits..."

        // Start the animation:
        CATransaction.begin()
        CATransaction.setCompletionBlock { self.revealMysticConjuring() }

        var animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.20
        animation.repeatCount = 2.5
        animation.duration = 1.20
        animation.isRemovedOnCompletion = true
        animation.autoreverses = true
        self.messageLabel.layer.add(animation, forKey: "opacity")

        animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 1.0
        animation.toValue = 1.35
        animation.repeatCount = 3.0
        animation.duration = 1.20
        animation.isRemovedOnCompletion = true
        animation.autoreverses = true
        self.messageLabel.layer.add(animation, forKey: "transform.scale.x")

        CATransaction.commit()
    }

    func revealMysticConjuring() {
        let fortuneViewController = FortuneViewController.instantiate()
        fortuneViewController.message = AppData.shared.randomFortune()
        navigationController?.pushViewController(fortuneViewController, animated: true)
    }
}

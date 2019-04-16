//
//  MainViewController.swift
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class MainViewController: UIViewController {

    // MARK: - Member Variables
    
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
        self.navigationController?.isNavigationBarHidden = true
        messageLabel.layer.removeAllAnimations()
        messageLabel.text =
            "Shake the phone to reveal your mystic Branch fortune..."
        updateStatsLabel()
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
        // Over-ride so the view controller can get shake events:
        return enableShakes ? true : false
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && enableShakes {
            self.startMysticConjuring()
        }
    }

    // MARK: - Notifications

    @objc func appStatsDidUpdate(notification: Notification) {
        updateStatsLabel()
    }

    @objc func branchWillStartSession(notification: Notification) {
        // Only show the waiting view if we've been opened by an URL tap:
        guard let url = notification.userInfo?[BranchURLKey] as? URL else { return }
        WaitingViewController.showWithMessage(
            message: "Opening\n\(url.absoluteString)",
            activityIndicator: true,
            disableTouches: true
        )
    }

    @objc func branchDidStartSession(notification: Notification) {
        WaitingViewController.hide()

        if let error = notification.userInfo?[BranchErrorKey] as? Error {
            if let url = notification.userInfo?[BranchURLKey] as? URL {
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
            messageViewController.name = buo.contentMetadata.customMetadata["name"] as? String
            messageViewController.message = buo.contentMetadata.customMetadata["message"] as? String
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
        CATransaction.setAnimationDuration(0.75)

        var animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.25
        animation.repeatCount = 2.5
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards;
        animation.autoreverses = true
        self.messageLabel.layer.add(animation, forKey: "opacity")

        animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 1.0
        animation.toValue = 1.35
        animation.repeatCount = 2.5
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards;
        animation.autoreverses = true
        self.messageLabel.layer.add(animation, forKey: "transform.scale.x")

        CATransaction.commit()
    }

    func revealMysticConjuring() {
        CATransaction.begin()
        CATransaction.setCompletionBlock { self.showFortune() }
        CATransaction.setAnimationDuration(0.40)

        var animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.00
        animation.duration = 1.00
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards;
        self.messageLabel.layer.add(animation, forKey: "opacity")

        animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 1.00
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards;
        self.messageLabel.layer.add(animation, forKey: "transform.scale.x")

        CATransaction.commit()
    }

    func showFortune() {
        let fortuneViewController = FortuneViewController.instantiate()
        fortuneViewController.message = AppData.shared.randomFortune()
        navigationController?.pushViewController(fortuneViewController, animated: true)
    }
}

//
//  AppStatsViewController.swift
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class AppStatsViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var createLinkButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.messageTextView.layer.borderColor = UIColor.darkGray.cgColor
        self.messageTextView.layer.borderWidth = 0.5
        self.messageTextView.layer.cornerRadius = 3.0
        self.messageTextView.text = ""
        self.messageTextView.inputAccessoryView = InputAccessoryView.instantiate()

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
            name: NSNotification.Name.AppStatsDidUpdate,
            object: nil
        )
        updateStatsLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatsLabel()
    }

    func updateStatsLabel() {
        statsLabel.text =
            "\(AppStats.shared.appOpens)\n\(AppStats.shared.linksOpened)\n\(AppStats.shared.linksCreated)"
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let textView = self.messageTextView else { return }
        self.createLinkButton.isEnabled = textView.text.count > 0
    }
    
    @IBAction func makeNewLinkAction(_ sender: Any) {
        self.messageTextView.resignFirstResponder()
        let linkViewController = LinkViewController.instantiate()
        linkViewController.message = self.messageTextView.text
        navigationController?.pushViewController(linkViewController, animated: true)
    }

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
            messageViewController.message = buo.metadata?["message"] as? String
            navigationController?.pushViewController(messageViewController, animated: true)
            AppStats.shared.linksOpened += 1
            return
        }
    }
}

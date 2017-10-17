//
//  AppStatsViewController.swift
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class AppStatsViewController: UIViewController, UITextViewDelegate, InputAccessoryViewDelegate {

    @IBOutlet weak var statsLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var createLinkButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.messageTextView.layer.borderColor = UIColor.darkGray.cgColor
        self.messageTextView.layer.borderWidth = 0.5
        self.messageTextView.layer.cornerRadius = 3.0
        self.messageTextView.text = ""
        if let accessory = InputAccessoryView.instantiate() {
            accessory.delegate = self
            self.messageTextView.inputAccessoryView = accessory
        }

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

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if let accessory = self.messageTextView.inputAccessoryView as? InputAccessoryView {
            accessory.text = self.messageTextView.text
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let textView = self.messageTextView else { return }
        self.createLinkButton.isEnabled = textView.text.count > 0
    }
    
    @IBAction func makeNewLinkAction(_ sender: Any) {
        self.messageTextView.inputAccessoryView = nil
        self.messageTextView.reloadInputViews()

        BNCAfterSecondsPerformBlock(0.001) as {
            self.messageTextView.resignFirstResponder()
            self.view.endEditing(true)
        }

//        let linkViewController = LinkViewController.instantiate()
//        linkViewController.message = self.messageTextView.text
//        navigationController?.pushViewController(linkViewController, animated: true)
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

    @objc func inputAccessoryViewDone(accessory: InputAccessoryView) {
        self.messageTextView.text = accessory.textView.text
        accessory.resignFirstResponder()
        accessory.endEditing(true)
        self.messageTextView.inputAccessoryView = nil
        self.messageTextView.reloadInputViews()

        self.messageTextView.resignFirstResponder()
        self.view.endEditing(true)
        self.resignFirstResponder()

//        self.findAndResignFirstResponder(view: self.view)
//        self.findAndResignFirstResponder(view: accessory)
//        self.findAndResignFirstResponder(view: self.view.window as! UIView)
//        accessory.textView.resignFirstResponder()
//        self.messageTextView.resignFirstResponder()
//        accessory.endEditing(true)
//        self.view.endEditing(true)
//        self.view.window?.becomeFirstResponder()
////        self.view.becomeFirstResponder()
////        self.becomeFirstResponder()
    }

//    func findAndResignFirstResponder(responder: UIResponder) {
//        responder.resignFirstResponder()
//        //responder.endEditing(true)
//        while
//        for next in responder.next {
//            findAndResignFirstResponder(view: subview)
//        }
//    }

    func findAndResignFirstResponder(view: UIView) {
        view.resignFirstResponder()
        var next = view.next
        while let n = next {
            n.resignFirstResponder()
            next = n.next
        }
    }
}

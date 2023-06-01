//  ParentViewController.swift
//  DeepLinkDemo
//  Created by Apple on 17/05/22.

import UIKit
class ParentViewController: UIViewController {
    private var reachability:Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reachabilityCheck()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    func reachabilityCheck() {
        reachability = Reachability()!
        reachability!.whenReachable = { reachability in
        }
        reachability?.whenUnreachable = { reachability in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.networkError()
            }
        }
        do {
            try reachability?.startNotifier()
        } catch {
            NSLog("Unable to start notifier")
        }
    }
    
    func networkError() {
        CommonAlert.shared.showActionAlertView(title: "Failure", message: "Your internet/network connection appears to be offline. Please check your internet/network connection.", actions: [], preferredStyle: .alert, viewController: self)
    }
    
}

//
//  NavigationController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class NavigationController: UINavigationController, BranchDeepLinkingController {
    
    
    var deepLinkingCompletionDelegate: BranchDeepLinkingControllerCompletionDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureControl(withData params: [AnyHashable: Any]!) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "Content") as! ContentViewController
        self.pushViewController(vc, animated: true)
        
        let dict = params as Dictionary
        if dict["~referring_link"] != nil {
            vc.contentType = "Content"
        }
    }
}

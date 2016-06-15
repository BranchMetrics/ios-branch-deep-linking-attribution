//
//  NavigationController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 5/27/16.
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
    
    
    func configureControlWithData(data: [NSObject : AnyObject]!) {
        let logOutputViewController = self.storyboard?.instantiateViewControllerWithIdentifier("LogOutput") as! LogOutputViewController
        self.pushViewController(logOutputViewController, animated: true)
        if let deeplinkText = data["deeplink_text"] as! String? {
            let logOutput = String(format:"Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@", deeplinkText, data.description)
            logOutputViewController.logOutput = logOutput
        }
    }
    

}

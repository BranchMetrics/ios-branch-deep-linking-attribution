//  ViewController.swift
//  DeepLinkDemo
//  Created by Apple on 17/05/22
import UIKit

class ViewController: ParentViewController {
   
    override func viewDidLoad() {
        super.viewDidLoad()
        super.reachabilityCheck()
    }
    
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


}

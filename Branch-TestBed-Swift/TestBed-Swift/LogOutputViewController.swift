//
//  LogOutputViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class LogOutputViewController: UIViewController {
    
    
    @IBOutlet weak var logOutputTextView: UITextView!
    
    
    var logOutput: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setting scrollEnabled to false prevents a clipping bug
        logOutputTextView.isScrollEnabled = false
        logOutputTextView.text = logOutput
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // re-enabling scrollEnabled after view is painted
        logOutputTextView.isScrollEnabled = true
    }

    
}

//
//  ContentViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class ContentViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
    
    var content = ""
    var contentType: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if contentType == "Content" {
            
            if let universalObject = Branch.getInstance().getLatestReferringBranchUniversalObject() {
                content = String(format:"\nLatestReferringBranchUniversalObject:\n\n%@", universalObject)
                print("Branch TestBed: nLatestReferringBranchUniversalObject:\n", content)
                
                if (universalObject.imageUrl != nil) {
                    if let imageURL = URL(string: universalObject.imageUrl!) {
                        imageView.isHidden = false
                        imageView.loadImageFromUrl(url: imageURL)
                        print("ImageURL=\(imageURL)")
                        
                    }
                }
                
                if universalObject.canonicalIdentifier != "" {
                    universalObject.publiclyIndex = true
                    universalObject.userCompletedAction(BNCRegisterViewEvent)
                }
                
            }
        } else if contentType == "LatestReferringParams" {
            if let latestReferringParams = Branch.getInstance().getLatestReferringParams() {
                content = String(format:"\nLatestReferringParams:\n\n%@", latestReferringParams.JSONDescription())
                print("Branch TestBed: LatestReferringParams:\n", content)
            }
        } else if contentType == "FirstReferringParams" {
            if let firstReferringParams = Branch.getInstance().getFirstReferringParams() {
                content = String(format:"\nFirstReferringParams:\n\n%@", firstReferringParams.JSONDescription())
                print("Branch TestBed: FirstReferringParams:\n", content)
            }
        } else {
            content = "\nNo data available"
        }
        
        contentTextView.text = content
        print(content)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.contentTextView.sizeToFit()
        var frame: CGRect = self.contentTextView.frame
        frame.size.height = self.contentTextView.contentSize.height
        self.contentTextView.frame = frame
        
        super.viewDidAppear(animated)
        
    }
    
}

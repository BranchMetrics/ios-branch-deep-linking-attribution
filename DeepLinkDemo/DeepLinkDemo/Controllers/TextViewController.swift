//
//  TextViewController.swift
//  DeepLinkDemo
//
//  Created by ajaykumar on 15/06/22.
//

import Foundation
import UIKit
import CoreSpotlight;
import MobileCoreServices;

class TextViewController: UIViewController {
    
    var isShareDeepLink = false
    var isNavigateToContent = false
    var isDisplayContent = false
    var isTrackContent = false
    var isTrackContenttoWeb = false
    var handleLinkInWebview = false
    var isCreateDeepLink = false
    var forNotification = false
    var isTrackUser = false
    
    var url = ""
    var responseStatus = ""
    var dictData = [String:Any]()
    var textViewText = ""

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var logDataTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logDataTextView.text = textViewText
        statusLabel.text = responseStatus
        logDataTextView.isEditable = false
    }
    
    @IBAction func BackButtonAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func nextButtonAction(_ sender: Any) {
        if self.isTrackContent == true {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            if let vc = storyBoard.instantiateViewController(withIdentifier: "GenerateURLVC") as? GenerateURLVC {
                vc.isTrackContent = true
                vc.forNotification = false
                vc.isCreateDeepLink = false
                vc.isShareDeepLink = false
                vc.isNavigateToContent = false
                vc.dictData = dictData
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else if self.isTrackUser == true {
            self.navigationController?.popToRootViewController(animated: true)
        } else if self.forNotification == true {
            self.navigationController?.popToRootViewController(animated: true)
        } else if self.isTrackContenttoWeb || self.isCreateDeepLink {
            launchWebView()
        } else if self.isNavigateToContent || self.isDisplayContent || self.handleLinkInWebview {
            launchReadVC()
        } else {
            launchReadVC()
        }
    }
    
    func launchReadVC(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "ReadVC") as? ReadVC {
            vc.strTxt = url
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func launchWebView(){
        //Fixed
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "WebViewVC") as? WebViewVC {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

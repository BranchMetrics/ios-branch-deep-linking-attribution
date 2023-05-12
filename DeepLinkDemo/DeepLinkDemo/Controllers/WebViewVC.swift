//
//  WebViewVC.swift
//  DeepLinkDemo
//
//  Created by Rakesh kumar on 4/22/22.
//

import UIKit
import WebKit
import SafariServices

class WebViewVC: ParentViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webViewContainer: UIView!
    
    var webViewDetail: WKWebView = WKWebView()
    private var reachability:Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadWKWebview()
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("HandleLinksInapp")
    }
    
    fileprivate func loadWKWebview(){
        let webConfiguration = WKWebViewConfiguration()
        let customFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: self.webViewContainer.frame.size.width, height: self.webViewContainer.frame.size.height))
        self.webViewDetail = WKWebView (frame: customFrame , configuration: webConfiguration)
        webViewDetail.translatesAutoresizingMaskIntoConstraints = false
        self.webViewContainer.addSubview(webViewDetail)
        self.view.addConstraint(NSLayoutConstraint(item: webViewDetail, attribute: .trailing, relatedBy: .equal, toItem: self.webViewContainer, attribute: .trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webViewDetail, attribute: .leading, relatedBy: .equal, toItem: self.webViewContainer, attribute: .leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webViewDetail, attribute: .top, relatedBy: .equal, toItem: self.webViewContainer, attribute: .top, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: webViewDetail, attribute: .bottom, relatedBy: .equal, toItem: self.webViewContainer, attribute: .bottom, multiplier: 1, constant: 0))
        
        webViewDetail.navigationDelegate = self
        if let deeplinkurl: String = UserDefaults.standard.string(forKey: "link"){
            webViewDetail.load(URLRequest(url: URL(string: deeplinkurl)!))
        }
    }
    
    @IBAction func backBtnTapped(){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}

extension WebViewVC: SFSafariViewControllerDelegate{
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
}

//
//  ArticleView.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
import MBProgressHUD
import TextAttributes
import UIKit
import WebKit

protocol ArticleViewDelegate: class {
    func articleViewDidShare(_ articleView: ArticleView)
}

class ArticleView: UIView, WKNavigationDelegate {
    let webView = WKWebView()
    let button = UIButton()

    let planetData: PlanetData
    var hud: MBProgressHUD!

    weak var delegate: ArticleViewDelegate?

    init(planetData: PlanetData, frame: CGRect = .zero) {
        self.planetData = planetData
        super.init(frame: frame)

        let request = URLRequest(url: planetData.url)
        webView.navigationDelegate = self
        webView.load(request)

        addSubview(webView)
        addSubview(button)

        webView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        constrain(webView, button) {
            web, share in

            let superview = web.superview!
            web.centerX == superview.centerX
            web.width == superview.width

            share.centerX == superview.centerX
            share.width == superview.width

            web.top == superview.top
            web.bottom == share.top
            share.bottom == superview.bottom
            share.height == 88
        }

        button.addTarget(self, action: #selector(share), for: .touchUpInside)

        let attributes = TextAttributes()
            .font(name: "San Francisco Bold", size: 23)
            .foregroundColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0)
        let attributedTitle = NSAttributedString(string: "Share", attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.layer.borderColor = UIColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0).cgColor
        button.layer.borderWidth = 1
        button.backgroundColor = UIColor(red: 0.753, green: 0.878, blue: 0.878, alpha: 1.0)

        hud = MBProgressHUD.showAdded(to: webView, animated: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hud.hide(animated: true)
        print("could not load \(planetData.url): \(error)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hud.hide(animated: true)
    }

    @objc private func share(sender: UIButton) {
        delegate?.articleViewDidShare(self)
    }
}

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

/**
 * Delegate protocol for ArticleView. Notified when user taps Share button.
 */
protocol ArticleViewDelegate: class {
    /**
     * Notification that the user tapped the Share button in the ArticleView.
     * - Parameter articleView: The ArticleView that generated this event
     */
    func articleViewDidShare(_ articleView: ArticleView)
}

/**
 * Displays a WKWebView with the url property from the supplied PlanetData.
 * Displays a large Share button at the bottom to show the share sheet.
 */
class ArticleView: UIView, WKNavigationDelegate {

    // MARK: - Subviews

    let webView = WKWebView()
    let button = UIButton()

    // MARK: - Other stored properties

    let planetData: PlanetData
    var hud: MBProgressHUD!

    weak var delegate: ArticleViewDelegate?

    // MARK: - Object lifecycle

    init(planetData: PlanetData, frame: CGRect = .zero) {
        self.planetData = planetData
        super.init(frame: frame)

        addSubview(webView)
        addSubview(button)

        setupButton()
        setupWebview()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hud.hide(animated: true)
        BNCLogError("could not load \(planetData.url): \(error)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hud.hide(animated: true)
    }

    // MARK: - Button action

    @objc private func share(sender: UIButton) {
        delegate?.articleViewDidShare(self)
    }

    // MARK: - Setup methods

    private func setupButton() {
        button.addTarget(self, action: #selector(share), for: .touchUpInside)

        let attributes = TextAttributes()
            .font(name: Style.boldFontName, size: Style.titleFontSize)
            .foregroundColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0)
            .kern(2.4)
        let attributedTitle = NSAttributedString(string: "Share", attributes: attributes)
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.layer.borderColor = UIColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0).cgColor
        button.layer.borderWidth = 1
        button.backgroundColor = UIColor(red: 0.753, green: 0.878, blue: 0.878, alpha: 1.0)
    }

    private func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        /*
         * Put the button at the bottom with a fixed height.
         */
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
    }

    private func setupWebview() {
        let request = URLRequest(url: planetData.url)
        webView.navigationDelegate = self
        webView.load(request)

        hud = MBProgressHUD.showAdded(to: webView, animated: true)
    }
}

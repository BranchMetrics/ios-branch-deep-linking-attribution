//
//  ArticleView.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
import MBProgressHUD
import UIKit
import WebKit
import Branch

/**
 * Delegate protocol for ArticleView. Notified when user taps Share button.
 */
protocol ArticleViewDelegate: class {
    /**
     * Notification that the user tapped the Share button in the ArticleView.
     * - Parameter articleView: The ArticleView that generated this event
     */
    func articleViewDidShare(_ articleView: ArticleView)
    func articleViewDidNavigate(_ articleView: ArticleView)
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

    var planetData: PlanetData {
        didSet { setupWebview() }
    }
    var hud: MBProgressHUD!
    var showShareButton = true
    private var constraintGroup = ConstraintGroup()

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

    func webView(_ webView: WKWebView,
decidePolicyFor navigationAction: WKNavigationAction,
           decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        BNCLog("Navigating to URL \(String(describing: navigationAction.request.url?.description)).")
        if Branch.getInstance().handleDeepLink(withNewSession:navigationAction.request.url) {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hud.hide(animated: true)
        BNCLogError("could not load \(planetData.url): \(error)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hud.hide(animated: true)
        delegate?.articleViewDidNavigate(self)
    }

    // MARK: - Button action

    @objc private func share(sender: UIButton) {
        delegate?.articleViewDidShare(self)
    }

    // MARK: - Setup methods

    private func setupButton() {
        button.addTarget(self, action: #selector(share), for: .touchUpInside)

        /*
        let attributes = TextAttributes()
            .font(name: Style.boldFontName, size: Style.titleFontSize)
            .foregroundColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0)
            .kern(2.4)
        */
        guard let font = UIFont(name: Style.boldFontName, size: Style.titleFontSize) else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.kern: 2.6,
            NSAttributedString.Key.foregroundColor: UIColor(red: 0.133, green: 0.4, blue: 0.627, alpha: 1.0)
        ]

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
        constraintGroup = constrain(webView, button, replace: constraintGroup) {
            web, share in

            let superview = web.superview!
            web.centerX == superview.centerX
            web.width == superview.width

            share.centerX == superview.centerX
            share.width == superview.width

            web.top == superview.top
            web.bottom == share.top
            share.bottom == superview.bottom
            if showShareButton {
                share.height == 88
                button.isHidden = false
            } else {
                share.height == 0
                button.isHidden = true
            }
        }
    }

    private func setupWebview() {
        webView.navigationDelegate = self
        if planetData.url.scheme == "file" {
            let baseURL = Bundle.main.bundleURL
            let indexPath = baseURL.absoluteString + planetData.url.path
            let indexURL = URL.init(string: indexPath)!
            webView.loadFileURL(
                indexURL,
                allowingReadAccessTo: indexURL.deletingLastPathComponent()
            )
            showShareButton = false
            setupConstraints()
        } else {
            let request = URLRequest(url: planetData.url)
            webView.load(request)
        }
        hud = MBProgressHUD.showAdded(to: webView, animated: true)
    }
}

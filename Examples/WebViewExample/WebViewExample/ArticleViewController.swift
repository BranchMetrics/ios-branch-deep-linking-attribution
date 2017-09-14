//
//  ArticleViewController.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Branch
import Cartography
import UIKit

/**
 * Displays an ArticleView for the specified PlanetData and provides
 * the ArticleViewDelegate for the ArticleView.
 */
class ArticleViewController: UIViewController, ArticleViewDelegate {

    // MARK: - Stored properties

    let planetData: PlanetData
    var buo: BranchUniversalObject!

    // MARK: - Object lifecycle

    init(planetData: PlanetData) {
        self.planetData = planetData
        super.init(nibName: nil, bundle: nil)
        title = planetData.title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         * Add an ArticleView for this planetData as a subview of
         * view.
         */
        let articleView = ArticleView(planetData: planetData)
        articleView.delegate = self
        articleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(articleView)
        constrain(articleView) {
            view in
            let superview = view.superview!
            view.centerX == superview.centerX
            view.centerY == superview.centerY
            view.width == superview.width
            view.height == superview.height
        }

        // Initialize BUO at page load.
        setupBUO()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Log a BNCRegisterViewEvent each time the user views the page.
        buo.userCompletedAction(BNCRegisterViewEvent)
        BNCLog("Logged BNCRegisterViewEvent on BUO")
    }

    // MARK: - ArticleViewDelegate

    // MARK: Calls BUO.showShareSheet
    func articleViewDidShare(_ articleView: ArticleView) {
        let linkProperties = BranchLinkProperties()
        linkProperties.feature = "share"
        linkProperties.channel = "iOSApp"
        linkProperties.addControlParam("$desktop_url", withValue: planetData.url.absoluteString)
        linkProperties.addControlParam("$email_subject", withValue: "The Planet \(planetData.title)")

        let shareLink = BranchShareLink(universalObject: buo, linkProperties: linkProperties)
        shareLink?.shareText = "Read about the planet \(planetData.title)."
        shareLink?.presentActivityViewController(from: self, anchor: nil)
    }

    // MARK: - Branch Universal Object setup

    private func setupBUO() {
        // Initialization and configuration.
        buo = BranchUniversalObject(planetData: planetData)
        
        BNCLog("Created Branch Universal Object")
    }
}

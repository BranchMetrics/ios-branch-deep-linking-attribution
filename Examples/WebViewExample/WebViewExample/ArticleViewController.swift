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

    var planetData: PlanetData {
        didSet { updateViewWithPlanetData() }
    }
    let forwardBackControl = UISegmentedControl()
    var buo: BranchUniversalObject!
    var articleView = ArticleView(
        planetData: PlanetData(
             title: "",
               url:"https://no.com",
             image: "file://Branch.png"
         )
     )

    // MARK: - Object lifecycle

    init(planetData: PlanetData) {
        self.planetData = planetData
        super.init(nibName: nil, bundle: nil)
        updateViewWithPlanetData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        articleView.delegate = nil
        navigationItem.rightBarButtonItem = nil
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         * Add an ArticleView for this planetData as a subview of
         * view.
         */
        articleView = ArticleView(planetData: planetData)
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        /* Log a BNCRegisterViewEvent each time the user views the page.
         *
         * This does several things behind the scenes:
         *  - Since `automaticallyListOnSpotlight` is true for this Branch Universal Object, it is
         *    listed on Spotlight.
         *  - The 'view' ranking for searches is bumped with each organic view.
         *  - The 'view' event is tracked in analytics on the Branch dashboard.
         */
        buo.userCompletedAction(BNCRegisterViewEvent)
        BNCLog("Logged BNCRegisterViewEvent on BUO")
        addForwardBackControl()
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
        shareLink.shareText = "Read about the planet \(planetData.title)."
        shareLink.presentActivityViewController(from: self, anchor: nil)
    }

    func articleViewDidNavigate(_ articleView: ArticleView) {
        updateForwardBackControl()
    }

    // MARK: - Branch Universal Object setup

    func updateViewWithPlanetData() {
        title = planetData.title.firstWord()
        articleView.planetData = planetData
        setupBUO()
    }

    private func setupBUO() {
        // Initialization and configuration.
        buo = BranchUniversalObject(planetData: planetData)
        BNCLog("Created Branch Universal Object")
    }

    // MARK: - Forward Back Control

    private func addForwardBackControl() {
        forwardBackControl.frame = CGRect(x: 0, y: 0, width: 40, height: 26)
        forwardBackControl.removeAllSegments()
        forwardBackControl.insertSegment(withTitle: "<", at: 0, animated: false)
        forwardBackControl.insertSegment(withTitle: ">", at: 1, animated: false)
        forwardBackControl.isMomentary = true
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(customView: forwardBackControl)
        forwardBackControl.addTarget(
            self,
            action: #selector(forwardBackControlAction(sender:)),
            for: .valueChanged
        )
        updateForwardBackControl()
    }

    private func updateForwardBackControl() {
        if forwardBackControl.numberOfSegments == 2 {
            forwardBackControl.setEnabled(articleView.webView.canGoBack, forSegmentAt: 0)
            forwardBackControl.setEnabled(articleView.webView.canGoForward, forSegmentAt: 1)
        }
    }

    @IBAction func forwardBackControlAction(sender: Any) {
        switch forwardBackControl.selectedSegmentIndex {
        case 0:  articleView.webView.goBack()
        case 1:  articleView.webView.goForward()
        default: break
        }
    }
}

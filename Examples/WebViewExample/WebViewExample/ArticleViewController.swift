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

class ArticleViewController: UIViewController, ArticleViewDelegate {
    let planetData: PlanetData
    var buo: BranchUniversalObject!

    init(planetData: PlanetData) {
        self.planetData = planetData
        super.init(nibName: nil, bundle: nil)
        title = planetData.title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

        setupBUO()
    }

    func articleViewDidShare(_ articleView: ArticleView) {
        let linkProperties = BranchLinkProperties()
        linkProperties.feature = "share"
        linkProperties.channel = "iOSApp"
        linkProperties.addControlParam("$desktop_url", withValue: planetData.url.absoluteString)

        buo.showShareSheet(with: linkProperties, andShareText: "The Planet \(planetData.title)", from: self) {
            channel, success in
            print("Share to channel \(channel ?? "(nil)") complete. success = \(success)")
        }
    }

    private func setupBUO() {
        buo = BranchUniversalObject(canonicalIdentifier: "planets/\(planetData.title)")
        buo.automaticallyListOnSpotlight = true
        buo.canonicalUrl = planetData.url.absoluteString
        buo.title = planetData.title
        buo.imageUrl = planetData.url.absoluteString
        
        buo.userCompletedAction(BNCRegisterViewEvent)
        
        print("Created Branch Universal Object and registered view event")
    }
}

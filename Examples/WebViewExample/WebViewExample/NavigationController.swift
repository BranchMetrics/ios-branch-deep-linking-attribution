//
//  NavigationController.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import TextAttributes
import UIKit

class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let attributes = TextAttributes()
            .font(name: "San Francisco Bold", size: 23)
        navigationBar.titleTextAttributes = attributes.dictionary

        setViewControllers([ArticleListViewController()], animated: false)
    }
}

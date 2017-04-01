//
//  NavigationController.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import TextAttributes
import UIKit

/**
 * Custom UINavigationController to display an article list.
 */
class NavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let attributes = TextAttributes()
            .font(name: Style.boldFontName, size: Style.titleFontSize)
        navigationBar.titleTextAttributes = attributes.dictionary

        setViewControllers([ArticleListViewController()], animated: false)
    }
}

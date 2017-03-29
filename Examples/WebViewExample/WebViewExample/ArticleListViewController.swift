//
//  ArticleListViewController.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
import UIKit

class ArticleListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "The Planets"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 88

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        constrain(tableView) {
            tv in
            let superview = tv.superview!
            tv.centerX == superview.centerX
            tv.centerY == superview.centerY
            tv.width == superview.width
            tv.height == superview.height
        }

        tableView.register(PlanetCell.self, forCellReuseIdentifier: PlanetCell.identifier)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PlanetData.all.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: PlanetCell.identifier) ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < PlanetData.all.count else { return }
        guard let planetCell = cell as? PlanetCell else { return }

        planetCell.planetData = PlanetData.all[indexPath.row]
    }
}

//
//  ArticleListViewController.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
import UIKit

/**
 * Displays a list of planets from PlanetData.all in a table view using PlanetCell for each.
 * When a row is tapped, an ArticleViewController is pushed for the PlanetData corresponding
 * to that row.
 */
class ArticleListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "The Planets"

        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.rowHeight = 88
        tableView.allowsMultipleSelection = false

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        constrain(tableView) {
            view in
            let superview = view.superview!
            view.centerX == superview.centerX
            view.centerY == superview.centerY
            view.width == superview.width
            view.height == superview.height
        }

        tableView.register(PlanetCell.self, forCellReuseIdentifier: PlanetCell.identifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let selectedRow = tableView.indexPathForSelectedRow else { return }

        // Reset previous row selection when back pressed.
        tableView.deselectRow(at: selectedRow, animated: false)
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PlanetData.all.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: PlanetCell.identifier) ?? UITableViewCell()
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < PlanetData.all.count else { return }
        guard let planetCell = cell as? PlanetCell else { return }
        planetCell.planetData = PlanetData.all[indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < PlanetData.all.count else { return }
        let planetData = PlanetData.all[indexPath.row]
        let viewController = ArticleViewController(planetData: planetData)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

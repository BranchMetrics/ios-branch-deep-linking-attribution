//
//  PlanetCell.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
import TextAttributes
import UIKit

class PlanetCell: UITableViewCell {
    static let identifier = "Planet"

    var planetData: PlanetData? {
        didSet {
            updatePlanetData()
        }
    }

    let thumbnailImageView = UIImageView()
    let label = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(label)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 20

        constrain(thumbnailImageView, label) {
            image, title in
            let superview = image.superview!

            image.centerY == superview.centerY
            image.height == superview.height

            title.centerY == superview.centerY
            title.height <= superview.height - 2 * margin

            image.height == image.width

            image.left == superview.left
            image.right == title.left - margin
            title.right == superview.right - margin
        }

        constrain(contentView) {
            view in
            let superview = view.superview!
            view.centerX == superview.centerX
            view.centerY == superview.centerY
            view.width == superview.width
            view.height == superview.height
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updatePlanetData() {
        defer {
            setNeedsLayout()
        }

        guard let planetData = planetData else {
            thumbnailImageView.image = nil
            label.attributedText = nil
            return
        }

        thumbnailImageView.image = UIImage(named: planetData.title)

        let attributes = TextAttributes()
            .font(name: "San Francisco Bold", size: 17)
            .alignment(.left)

        label.attributedText = NSAttributedString(string: planetData.title, attributes: attributes)
    }
}

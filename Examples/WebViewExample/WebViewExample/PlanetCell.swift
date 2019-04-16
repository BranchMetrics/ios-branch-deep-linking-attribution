//
//  PlanetCell.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Cartography
// import TextAttributes
import UIKit

/**
 * Displays the `UIImage(named: planetData.title)` in a UIImageView at the left and
 * `planetData.title` in a label to the right.
 */
class PlanetCell: UITableViewCell {
    /// UITableViewCell reuseIdentifier for this class
    static let identifier = "Planet"

    // MARK: - Stored properties

    var planetData: PlanetData? {
        didSet {
            updatePlanetData()
        }
    }

    let thumbnailImageView = UIImageView()
    let label = UILabel()

    // MARK: - Object lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(label)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private methods

    private func setupConstraints() {
        let margin: CGFloat = 20

        contentView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        /*
         * Put the square image at the left. Center the label vertically
         * to the right with the same margin on all sides.
         */
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

        /*
         * Make contentView fill its superview.
         */
        constrain(contentView) {
            view in
            let superview = view.superview!
            view.centerX == superview.centerX
            view.centerY == superview.centerY
            view.width == superview.width
            view.height == superview.height
        }
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

        /*
        let attributes = TextAttributes()
            .font(name: Style.boldFontName, size: Style.rowFontSize)
            .alignment(.left)
            .kern(1.2)
        // */
        guard let font = UIFont(name: Style.boldFontName, size: Style.rowFontSize) else {
            label.attributedText = nil
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.kern: 1.2
        ]

        label.attributedText = NSAttributedString(string: planetData.title, attributes: attributes)
        label.textAlignment = .left
    }
}

//
//  BranchUniversalObject+PlanetData.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/30/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Branch

extension BranchUniversalObject {
    /**
     * Initializes a BUO from a PlanetData struct. Sets
     * - canonicalIdentifier = "planets/\\(planetData.title)"
     * - automaticallyListOnSpotlight = true
     * - canonicalUrl = planetData.url.absoluteString
     * - title = planetData.title
     * - imageUrl = planetData.image?.absoluteString
     *
     * - Parameter planetData: A PlanetData struct with data to initialize the BUO.
     */
    convenience init(planetData: PlanetData) {
        self.init(canonicalIdentifier: "planets/\(planetData.title)")

        locallyIndex = true
        canonicalUrl = planetData.url.absoluteString
        title = planetData.title
        imageUrl = planetData.image?.absoluteString
    }
}

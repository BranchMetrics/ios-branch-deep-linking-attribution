//
//  PlanetData.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Branch

/**
 * Struct to represent data for a WebView and Spotlight.
 */
struct PlanetData {
    // MARK: - Stored properties

    /// Title displayed in table view, nav bar and used with BUO for deep linking
    let title: String

    /// The URL to display in the WebView and use with deep links
    let url: URL

    /// (Optional) URL for a Spotlight preview image
    let image: URL?

    // MARK: - Struct lifecycle

    /**
     * Initialize a PlanetData struct from String arguments
     * - Parameters:
     *   - title: String used for title property
     *   - url: String used to construct URL for url property
     *   - image: (Optional) String used to construct URL for image property (default: nil)
     */
    init(title: String, url: String, image: String?=nil) {
        self.title = title
        self.url = URL(string: url)!
        self.image = image != nil ? URL(string: image!) : nil
    }

    /**
     * Initialize a PlanetData struct from a BranchUniversalObject. Returns nil if PlanetData cannot be constructed
     * (title or canonicalUrl is nil or unparseable canonicalUrl).
     * - Parameter branchUniversalObject: A BranchUniversalObject with data for an article
     */
    init?(branchUniversalObject: BranchUniversalObject) {
        guard let title = branchUniversalObject.title,
            let urlString = branchUniversalObject.canonicalUrl,
            let url = URL(string: urlString) else {
            BNCLogWarning("Could not get required data from BranchUniversalObject")
            return nil
        }

        self.title = title
        self.url = url

        if let imageString = branchUniversalObject.imageUrl, let image = URL(string: imageString) {
            self.image = image
        }
        else {
            self.image = nil
        }
    }

    /// Array of PlanetData structs to populate the table view
    static let all = [
        PlanetData(title: "About the App",
                     url: "file:///Web.bundle/AboutTheApp/index.html",
                   image: "https://github.com/BranchMetrics/ios-branch-deep-linking/blob/master/docs/images/Branch-88.png"
        ),
        PlanetData(title: "Mercury",
                     url: "https://en.wikipedia.org/wiki/Mercury_(planet)",
                   image: "https://upload.wikimedia.org/wikipedia/commons/d/d9/Mercury_in_color_-_Prockter07-edit1.jpg"
        ),
        PlanetData(title: "Venus",
                     url: "https://en.wikipedia.org/wiki/Venus",
                   image: "https://upload.wikimedia.org/wikipedia/commons/e/e5/Venus-real_color.jpg"
        ),
        PlanetData(title: "Earth",
                     url: "https://en.wikipedia.org/wiki/Earth",
                   image: "https://upload.wikimedia.org/wikipedia/commons/9/97/The_Earth_seen_from_Apollo_17.jpg"
        ),
        PlanetData(title: "Mars",
                     url: "https://en.wikipedia.org/wiki/Mars",
                   image: "https://upload.wikimedia.org/wikipedia/commons/0/02/OSIRIS_Mars_true_color.jpg"
        ),
        PlanetData(title: "Jupiter",
                     url: "https://en.wikipedia.org/wiki/Jupiter",
                   image: "https://upload.wikimedia.org/wikipedia/commons/2/2b/Jupiter_and_its_shrunken_Great_Red_Spot.jpg"
        ),
        PlanetData(title: "Saturn",
                     url: "https://en.wikipedia.org/wiki/Saturn",
                   image: "https://upload.wikimedia.org/wikipedia/commons/c/c0/Saturn-27-03-04.jpeg"
        ),
        PlanetData(title: "Uranus",
                     url: "https://en.wikipedia.org/wiki/Uranus",
                   image: "https://upload.wikimedia.org/wikipedia/commons/3/3d/Uranus2.jpg"
        ),
        PlanetData(title: "Neptune",
                     url: "https://en.wikipedia.org/wiki/Neptune",
                   image: "https://upload.wikimedia.org/wikipedia/commons/5/56/Neptune_Full.jpg"
        ),
        PlanetData(title: "Pluto",
                     url: "https://en.wikipedia.org/wiki/Pluto",
                   image: "https://upload.wikimedia.org/wikipedia/commons/2/2a/Nh-pluto-in-true-color_2x_JPEG-edit-frame.jpg"
        )
    ]
}

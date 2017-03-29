//
//  PlanetData.swift
//  WebViewExample
//
//  Created by Jimmy Dee on 3/29/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

struct PlanetData {
    let title: String
    let url: URL
    let image: URL

    init(title: String, url: String, image: String) {
        self.title = title
        self.url = URL(string: url)!
        self.image = URL(string: image)!
    }

    static let all = [
        PlanetData(title: "Mercury", url: "https://en.wikipedia.org/wiki/Mercury_(planet)",
                   image: "https://upload.wikimedia.org/wikipedia/commons/d/d9/Mercury_in_color_-_Prockter07-edit1.jpg"),
        PlanetData(title: "Venus", url: "https://en.wikipedia.org/wiki/Venus",
                   image: "https://upload.wikimedia.org/wikipedia/commons/e/e5/Venus-real_color.jpg"),
        PlanetData(title: "Earth", url: "https://en.wikipedia.org/wiki/Earth", image: "https://upload.wikimedia.org/wikipedia/commons/9/97/The_Earth_seen_from_Apollo_17.jpg"),
        PlanetData(title: "Mars", url: "https://en.wikipedia.org/wiki/Mars", image: "https://upload.wikimedia.org/wikipedia/commons/0/02/OSIRIS_Mars_true_color.jpg"),
        PlanetData(title: "Jupiter", url: "https://en.wikipedia.org/wiki/Jupiter", image: "https://upload.wikimedia.org/wikipedia/commons/2/2b/Jupiter_and_its_shrunken_Great_Red_Spot.jpg"),
        PlanetData(title: "Saturn", url: "https://en.wikipedia.org/wiki/Saturn", image: "https://upload.wikimedia.org/wikipedia/commons/c/c0/Saturn-27-03-04.jpeg"),
        PlanetData(title: "Uranus", url: "https://en.wikipedia.org/wiki/Uranus", image: "https://upload.wikimedia.org/wikipedia/commons/3/3d/Uranus2.jpg"),
        PlanetData(title: "Neptune", url: "https://en.wikipedia.org/wiki/Neptune", image: "https://upload.wikimedia.org/wikipedia/commons/5/56/Neptune_Full.jpg"),
        PlanetData(title: "Pluto", url: "https://en.wikipedia.org/wiki/Pluto", image: "https://upload.wikimedia.org/wikipedia/commons/2/2a/Nh-pluto-in-true-color_2x_JPEG-edit-frame.jpg")
        
    ]
}

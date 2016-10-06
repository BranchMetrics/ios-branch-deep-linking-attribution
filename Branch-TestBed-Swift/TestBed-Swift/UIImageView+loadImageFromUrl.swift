//
//  UIImageView+loadImageFromUrl.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/25/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
// This extension: http://stackoverflow.com/questions/24231680/loading-downloading-image-from-url-on-swift
import Foundation

extension UIImageView {
    
    func loadImageFromUrl(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                print("image.description=\(image.description)")
                self.image = image
            }
            }.resume()
    }
    
    func loadImageFromUrl(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        loadImageFromUrl(url: url, contentMode: mode)
    }
}

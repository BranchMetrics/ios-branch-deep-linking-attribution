//
//  String+Planets.swift
//  WebViewExample
//
//  Created by Edward Smith on 9/22/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import Foundation

extension String {
    func firstWord() -> String {
        if let range = self.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines) {
            return String(self[..<range.lowerBound])
        } else {
            return self
        }
    }
}

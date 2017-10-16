//
//  InputAccessoryView.swift
//  BareBones
//
//  Created by edward on 10/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit

class InputAccessoryView: UIView, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var doneButton: UIButton!

    static func instantiate() -> InputAccessoryView? {
        guard let objects =
            Bundle.main.loadNibNamed("InputAccessoryView", owner: nil, options: nil) as [Any]!
        else { return nil }
        for object in objects {
            if let inputAccessoryView = object as? InputAccessoryView {
                inputAccessoryView.updateAppearance()
                return inputAccessoryView
            }
        }
        return nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateAppearance() {
        guard let _ = self.textView, let _ = self.doneButton else { return }

        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 0.5

        self.textView.layer.borderColor = UIColor.lightGray.cgColor;
        self.textView.layer.borderWidth = 0.5
        self.textView.layer.cornerRadius = 1.0

        let color = self.doneButton.titleColor(for: .normal)
        self.doneButton.layer.borderColor = color?.cgColor
        self.doneButton.layer.borderWidth = 0.5
        self.doneButton.layer.cornerRadius = 3.0

        self.textView.isScrollEnabled = false
        self.textView.text = ""
    }

    @IBAction func doneButtonAction(_ sender: Any) {
    }

    func textView(_ textView: UITextView,
      shouldChangeTextIn range: NSRange,
      replacementText text: String) -> Bool {
        self.updateViewSize()
        return true
    }

    func updateViewSize() {
        var size = self.textView.bounds.size
        size.height = 1000
        size = self.textView.sizeThatFits(size)
        var height = ceil(size.height + 14 + 1) // Add in margins plus slop
        if height > 5 * 32 {
            height = 5 * 32
            self.textView.isScrollEnabled = true
        } else {
            self.textView.isScrollEnabled = false
        }

        if let heightConstraints = self.superview?.constraints[0] {
            heightConstraints.constant = height
        }
    }
}

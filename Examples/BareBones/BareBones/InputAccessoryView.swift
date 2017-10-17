//
//  InputAccessoryView.swift
//  BareBones
//
//  Created by edward on 10/16/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit

@objc protocol InputAccessoryViewDelegate {
    @objc optional func inputAccessoryViewChanged(accessory: InputAccessoryView)
    @objc optional func inputAccessoryViewDone(accessory: InputAccessoryView)
}

class InputAccessoryView: UIView, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var doneButton: UIButton!

    weak var delegate: InputAccessoryViewDelegate?

    var text: String {
        get { return self.textView.text }
        set(s) { self.textView.text = s }
    }

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(notification:)),
            name: NSNotification.Name.UIKeyboardDidShow,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardDidShow(notification: NSNotification) {
        self.textView.becomeFirstResponder()
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
        //self.updateViewSize()
    }

    @IBAction func doneButtonAction(_ sender: Any) {
        if let _ = self.delegate?.inputAccessoryViewDone(accessory:) {
            self.delegate?.inputAccessoryViewDone!(accessory: self)
        }
    }

    func dismiss() {
        self.textView.resignFirstResponder()
    }
    
    /*
    func textView(_ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String) -> Bool {
        if let textViewText = self.textView.text {
            let newText = (textViewText as NSString).replacingCharacters(in: range, with: text)
            NSLog("Text: %@ New: %@.", text, newText)
            self.textView.text = newText
            self.updateViewSize()
            //self.textView.text = text
        }
        return false
    }
    */

    func textViewDidChange(_ textView: UITextView) {
        self.updateViewSize()
        if let _ = self.delegate?.inputAccessoryViewChanged(accessory:) {
            self.delegate?.inputAccessoryViewChanged!(accessory: self)
        }
    }

    func updateViewSize() {
        var size = self.textView.bounds.size
        size.height = 1000
        size = self.textView.sizeThatFits(size)
        var height = ceil(size.height + 14 + 1) // Add margins plus slop
        if height > 5 * 32 {
            height = 5 * 32
            self.textView.isScrollEnabled = true
        } else {
            self.textView.isScrollEnabled = false
        }
        //NSLog("%f", height)
        if let heightConstraints = self.superview?.constraints[0] {
            heightConstraints.constant = height
        }
    }
}

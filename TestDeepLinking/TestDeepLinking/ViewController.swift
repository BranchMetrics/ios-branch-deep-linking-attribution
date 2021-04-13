//
//  ViewController.swift
//  TestDeepLinking
//
//  Created by Nidhi on 3/20/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addText(_ text: String) {
        textView.text = ""
        textView.insertText(text)
    }
}


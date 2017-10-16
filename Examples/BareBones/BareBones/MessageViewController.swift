//
//  MessageViewController.swift
//  BareBones
//
//  Created by edward on 10/13/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!

    var message: String? {
        didSet { updateUI() }
    }

    static func instantiate() -> MessageViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "MessageViewController")
        return controller as! MessageViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func updateUI() {
        guard let messageLabel = self.messageLabel else { return }
        if let message = message {
            messageLabel.text = message + "”"
        }
    }

}

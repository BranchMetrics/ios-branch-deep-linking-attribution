//
//  LinkViewController
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class LinkViewController: UIViewController {
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var linkButton: UIButton!

    var branchObject : BranchUniversalObject? {
        didSet { updateUI() }
    }

    var branchURL : URL? {
        didSet { updateUI() }
    }

    static func instantiate() -> LinkViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "LinkViewController")
        return controller as! LinkViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageTextView.layer.borderColor = UIColor.darkGray.cgColor
        self.messageTextView.layer.borderWidth = 0.5
        self.messageTextView.layer.cornerRadius = 3.0
        updateUI()
    }

    func updateUI() {
        guard let messageTextView = messageTextView else { return }

        if let message = branchObject?.metadata?["message"] as? String {
            messageTextView.text = message
        } else {
            messageTextView.text = ""
        }

        if let url = branchURL {
            linkTextField.text = url.absoluteString
            linkButton.setTitle("Share Link", for: UIControlState.normal)
        } else {
            linkTextField.text = ""
            linkButton.setTitle("Create Link", for: UIControlState.normal)
        }

    }

    @IBAction func linkButtonAction(_ sender: Any) {
        if linkTextField.text?.count == 0 {
            createLink()
        } else {
            shareLink()
        }
    }

    func createLink() {
        // Set some content for the Branch object:
        let buo = BranchUniversalObject.init()
        buo.title = "Bare Bones Branch Example"
        buo.contentDescription = "This is a bare bones example for using Branch links."
        buo.metadata?["message"] = self.messageTextView.text

        // Set some link properties:
        let linkProperties = BranchLinkProperties.init()
        linkProperties.channel = "Bare Bones Example"

        // Generate the link
        // TODO: Fix sync call here:
        let urlString = buo.getShortUrl(with: linkProperties)
        if let s = urlString {
            branchURL = URL.init(string: s)
            branchObject = buo
            AppStats.shared.linksCreated += 1
        } else {
            showAlert(title: "Can't create link!", message: "")
        }
    }

    func shareLink() {
        guard let buo = branchObject else { return }

        let linkProperties = BranchLinkProperties.init()
        linkProperties.channel = "Bare Bones Example"

        let shareLink = BranchShareLink.init(universalObject: buo, linkProperties: linkProperties)
        shareLink?.presentActivityViewController(from: self, anchor: nil)
    }
}

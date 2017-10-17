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
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    var message: String?

    var branchURL : URL? {
        didSet { updateUI() }
    }

    var branchImage : UIImage? {
        didSet { updateUI() }
    }

    static func instantiate() -> LinkViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "LinkViewController")
        return controller as! LinkViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.layer.borderColor = UIColor.darkGray.cgColor
        self.imageView.layer.borderWidth = 0.5
        self.imageView.layer.cornerRadius = 3.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(_ : animated)
        updateUI()
        createLink()
    }

    func updateUI() {
        linkLabel.text = branchURL?.absoluteString ?? ""
        imageView.image = branchImage
    }

    func createLink() {
        if branchURL != nil {
            return
        }
        if message?.count == 0 {
            self.showAlert(title: "No message to send!", message: "")
            return
        }

        // Set some content for the Branch object:
        let buo = BranchUniversalObject.init()
        buo.title = "Bare Bones Branch Example"
        buo.contentDescription = "This is a bare bones example for using Branch links."
        buo.metadata?["message"] = self.message ?? ""

        // Set some link properties:
        let linkProperties = BranchLinkProperties.init()
        linkProperties.channel = "Bare Bones Example"

        // Generate the link asynchronously:
        WaitingViewController.showWithMessage(
            message: "Getting link...",
            activityIndicator: true,
            disableTouches: true
        )
        buo.getShortUrl(with: linkProperties) { (urlString: String?, error: Error?) in
            WaitingViewController.hide()
            if let s = urlString {
                self.branchURL = URL.init(string: s)
                AppStats.shared.linksCreated += 1
            } else
            if let error = error {
                self.showAlert(title: "Can't create link!", message: error.localizedDescription)
            }
            else {
                self.showAlert(title: "Can't creat link!", message: "")
            }
        }
    }

    func shareLink() {
        /*
        guard let buo = branchObject else { return }

        let linkProperties = BranchLinkProperties.init()
        linkProperties.channel = "Bare Bones Example"

        let shareLink = BranchShareLink.init(universalObject: buo, linkProperties: linkProperties)
        shareLink?.presentActivityViewController(from: self, anchor: nil)
        */
    }

    @IBAction func shareLinkAction(_ sender: Any) {
        self.shareLink()
    }

}

//
//  MessageViewController
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class MessageViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var linkLabel: UILabel!

    var message: String?
    var name: String?

    var branchURL : URL? {
        didSet { updateUI() }
    }

    var branchImage : UIImage? {
        didSet { updateUI() }
    }

    static func instantiate() -> MessageViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "MessageViewController")
        return controller as! MessageViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.layer.borderColor = UIColor.darkGray.cgColor
        self.imageView.layer.borderWidth = 0.5
        self.imageView.layer.cornerRadius = 3.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(_ : animated)
        updateUI()
        createLink()
    }

    func updateUI() {
        guard let messageLabel = self.messageLabel else { return }
        linkLabel.text = branchURL?.absoluteString ?? ""
        imageView.image = branchImage
        message = message ?? ""
        if let message = message {
            messageLabel.text = message + "”"
        }
        nameLabel.text = name
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
        buo.contentDescription = "A mysterious fortune."
        buo.metadata?["message"] = self.message ?? ""
        buo.metadata?["name"] = UIDevice.current.name

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
                AppData.shared.linksCreated += 1
                self.generateQRAndStuff()
            } else
            if let error = error {
                self.showAlert(title: "Can't create link!", message: error.localizedDescription)
            }
            else {
                self.showAlert(title: "Can't creat link!", message: "")
            }
        }
    }

    func generateQRAndStuff() {
        guard let url = self.branchURL else { return }
        let data = url.absoluteString.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")
            if let ciImage = filter.outputImage {
                self.branchImage = UIImage(ciImage: ciImage)
            }
        }
    }

    func shareLink() {
        guard let url = self.branchURL, let image = self.branchImage else { return }

        let urlItem = UIActivityItemProvider.init(placeholderItem: url)
        let textItem = UIActivityItemProvider.init(placeholderItem: "Follow this link to reveal the mystic fortune...")
        let imageItem = UIActivityItemProvider.init(placeholderItem: image)

        let activityController = UIActivityViewController.init(
            activityItems: [textItem, urlItem, imageItem],
            applicationActivities: []
        )
        present(activityController, animated: true, completion: nil)
    }

    @IBAction func shareLinkAction(_ sender: Any) {
        self.shareLink()
    }

}

//
//  FortuneViewController
//  BareBones
//
//  Created by Edward Smith on 10/3/17.
//  Copyright © 2017 Branch. All rights reserved.
//

import UIKit
import Branch

class FortuneViewController: UIViewController, UITextViewDelegate {

    // MARK: - Member Variables

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var linkTextView: UITextView!
    @IBOutlet weak var shareButton: UIButton!

    var message: String?

    var branchURL : URL? {
        didSet { updateUI() }
    }

    var branchImage : UIImage? {
        didSet { updateUI() }
    }

    // MARK: - View Controller Lifecycle

    static func instantiate() -> FortuneViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "FortuneViewController")
        return controller as! FortuneViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.layer.borderColor = UIColor.darkGray.cgColor
        self.imageView.layer.borderWidth = 0.5
        self.imageView.layer.cornerRadius = 2.0
        self.linkTextView.textContainer.maximumNumberOfLines = 1
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(_ : animated)
        updateUI()
        createLink()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.linkTextView.text.count > 0 {
            self.linkTextView.selectedRange = NSMakeRange(0, self.linkTextView.text.count)
        }
    }

    // MARK: - UI Updates

    func updateUI() {
        guard let messageLabel = self.messageLabel else { return }
        linkTextView.text = branchURL?.absoluteString ?? ""
        imageView.image = branchImage
        message = message ?? ""
        if let message = message {
            messageLabel.text = message + "”"
        }
    }

    func createLink() {
        if branchURL != nil {
            return
        }
        if message?.count == 0 {
            self.showAlert(title: "No message to send!", message: "")
            return
        }

        // Add some content to the Branch object:
        let buo = BranchUniversalObject.init()
        buo.title = "Bare Bones Branch Example"
        buo.contentDescription = "A mysterious fortune."
        buo.contentMetadata.customMetadata["message"] = self.message ?? ""
        buo.contentMetadata.customMetadata["name"] = UIDevice.current.name

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
                self.generateQR()
            } else
            if let error = error {
                self.showAlert(title: "Can't create link!", message: error.localizedDescription)
            }
            else {
                self.showAlert(title: "Can't creat link!", message: "")
            }
        }
    }

    func generateQR() {
        guard let url = self.branchURL else { return }

        // Make the QR code:
        let data = url.absoluteString.data(
            using: String.Encoding.isoLatin1,
            allowLossyConversion: false
        )
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        guard var qrImage = filter?.outputImage else { return }

        // We could stop here with the qrImage. But let's scale it up and add a logo.

        // Scale:
        let scaleX = 210 * UIScreen.main.scale
        let transformScale = scaleX/qrImage.extent.size.width
        let transform = CGAffineTransform(scaleX: transformScale, y: transformScale)
        let scaleFilter = CIFilter(name: "CIAffineTransform")
        scaleFilter?.setValue(qrImage, forKey: "inputImage")
        scaleFilter?.setValue(transform, forKey: "inputTransform")
        qrImage = (scaleFilter?.outputImage)!

        // Add a logo:
        UIGraphicsBeginImageContext(CGSize(width: scaleX, height: scaleX))
        let rect = CGRect(x: 0, y: 0, width: scaleX, height: scaleX)
        let image = UIImage.init(ciImage: qrImage)
        image.draw(in:rect);
        var centerRect = CGRect(x: 0, y: 0, width: scaleX/2.5, height: scaleX/2.5)
        centerRect.origin.x = (rect.width - centerRect.width) / 2.0
        centerRect.origin.y = (rect.height - centerRect.height) / 2.0
        let branchLogo = UIImage.init(named: "BranchLogo")
        branchLogo?.draw(in:centerRect)
        self.branchImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    func shareLink() {
        guard
            let url = self.branchURL,
            let cgImage = self.branchImage?.cgImage,
            let imagePNG = UIImage.init(cgImage: cgImage).pngData()
        else { return }

        let text = "Follow this link to reveal the mystic fortune enclosed..."
        let activityController = UIActivityViewController.init(
            activityItems: [text, url, imagePNG],
            applicationActivities: []
        )
        activityController.title = "Share Your Fortune"
        activityController.popoverPresentationController?.sourceView = shareButton
        activityController.popoverPresentationController?.sourceRect = shareButton.bounds
        activityController.setValue("My Fortune", forKey: "subject")
        present(activityController, animated: true, completion: nil)
    }

    @IBAction func shareLinkAction(_ sender: Any) {
        self.shareLink()
    }

}

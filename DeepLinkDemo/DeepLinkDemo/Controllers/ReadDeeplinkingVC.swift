//
//  ReadDeeplinkingVC.swift
//  DeepLinkDemo
//
//  Created by Rakesh kumar on 4/19/22.

import UIKit
import Branch

class ReadDeeplinkingVC: ParentViewController  {
    @IBOutlet weak var txtFldCChannel: UITextField!
    @IBOutlet weak var txtFldFeature: UITextField!
    @IBOutlet weak var txtFldChampaignName: UITextField!
    @IBOutlet weak var txtFldStage: UITextField!
    @IBOutlet weak var txtFldDeskTopUrl: UITextField!
    @IBOutlet weak var txtFldAdditionalData: UITextField!
    @IBOutlet weak var scrollViewMain: UIScrollView!
    private var reachability:Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        uiSetUp()
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("ReadDeeplinking")
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollViewMain.contentSize.height = scrollViewMain.subviews.sorted(by: { $0.frame.maxY < $1.frame.maxY }).last?.frame.maxY ?? scrollViewMain.contentSize.height
    }
   
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func submitAction(sender : UIButton) {
        self.view.endEditing(true)
        
        CommonMethod.sharedInstance.branchUniversalObject.publiclyIndex = true
        CommonMethod.sharedInstance.branchUniversalObject.locallyIndex = true
        CommonMethod.sharedInstance.branchUniversalObject.contentMetadata.customMetadata["key1"] = txtFldDeskTopUrl.text!
        
        CommonMethod.sharedInstance.linkProperties.channel = txtFldCChannel.text!
        CommonMethod.sharedInstance.linkProperties.feature = txtFldFeature.text!
        CommonMethod.sharedInstance.linkProperties.campaign = txtFldChampaignName.text!
        CommonMethod.sharedInstance.linkProperties.stage = txtFldStage.text!
        CommonMethod.sharedInstance.linkProperties.addControlParam("$desktop_url", withValue: txtFldDeskTopUrl.text!)
        CommonMethod.sharedInstance.linkProperties.addControlParam("custom_data", withValue: "yes")
        CommonMethod.sharedInstance.branchUniversalObject.getShortUrl(with:CommonMethod.sharedInstance.linkProperties,  andCallback: { (optUrl: String?, error: Error?) in
                   if error == nil, let url = optUrl {
                       NSLog("got my Branch link to share: %@", url)
                       DispatchQueue.main.async {
                           UserDefaults.standard.set(true, forKey: "isCreatedDeepLink")
                           UserDefaults.standard.set(url, forKey: "link")
                           self.navigationController?.popToRootViewController(animated: true)
                       }
                   }
               })
    }
}

extension ReadDeeplinkingVC {
    
    func uiSetUp() {
        let submitBtn = UIButton(frame: CGRect(x: self.view.frame.width/2-60, y: txtFldAdditionalData.frame.maxY+30, width: 120, height: 55))
        submitBtn.setTitle("Submit", for: .normal)
        submitBtn.backgroundColor = UIColor(red: 89.0/255.0, green: 12.0/255.0, blue: 228.0/255.0, alpha: 1.0)
        submitBtn.layer.cornerRadius = 8
        submitBtn.setTitleColor(UIColor.white, for: .normal)
        submitBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22.0)
        submitBtn.addTarget(self, action: #selector(self.submitAction), for: .touchUpInside)
        scrollViewMain.addSubview(submitBtn)
        txtFldCChannel.setLeftPaddingPoints(10)
        txtFldFeature.setLeftPaddingPoints(10)
        txtFldChampaignName.setLeftPaddingPoints(10)
        txtFldStage.setLeftPaddingPoints(10)
        txtFldDeskTopUrl.setLeftPaddingPoints(10)
        txtFldAdditionalData.setLeftPaddingPoints(10)
        txtFldCChannel.attributedPlaceholder = NSAttributedString(
            string: "Channel name like Facebook",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldFeature.attributedPlaceholder = NSAttributedString(
            string: "Feature eg: Sharing",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldChampaignName.attributedPlaceholder = NSAttributedString(
            string: "Campaign name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldStage.attributedPlaceholder = NSAttributedString(
            string: "Stage",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldDeskTopUrl.attributedPlaceholder = NSAttributedString(
            string: "Desktop URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldAdditionalData.attributedPlaceholder = NSAttributedString(
            string: "Additional Data",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
    }
}

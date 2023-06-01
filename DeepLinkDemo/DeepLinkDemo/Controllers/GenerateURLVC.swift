//
//  GenerateURLVC.swift
//  DeepLinkDemo
//  Created by Rakesh kumar on 4/19/22.

import UIKit
import BranchSDK
class GenerateURLVC: ParentViewController {
    @IBOutlet weak var txtFldCChannel: UITextField!
    @IBOutlet weak var txtFldFeature: UITextField!
    @IBOutlet weak var txtFldChampaignName: UITextField!
    @IBOutlet weak var txtFldStage: UITextField!
    @IBOutlet weak var txtFldDeskTopUrl: UITextField!
    @IBOutlet weak var txtFldAndroidUrl: UITextField!
    @IBOutlet weak var txtFldiOSTopUrl: UITextField!
    @IBOutlet weak var txtFldAdditionalData: UITextField!
    @IBOutlet weak var scrollViewMain: UIScrollView!
    
    var responseStatus = ""
    var screenMode = 0
    
    var dictData = [String:Any]()
    
    var isShareDeepLink = false
    
    var isDisplayContent = false
    
    var isNavigateToContent = false
    
    var isTrackContent = false
    
    var handleLinkInWebview = false
    
    var isCreateDeepLink = false
    
    var forNotification = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uiSetUp()
        
        NSLog("dictData", dictData)
        super.reachabilityCheck()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollViewMain.contentSize.height = scrollViewMain.subviews.sorted(by: { $0.frame.maxY < $1.frame.maxY }).last?.frame.maxY ?? scrollViewMain.contentSize.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("CreateDeeplink")
    }
    
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func fireLocalNotification(linkurl: String){
        let dict = [
            "aps": [
                "alert":[
                    "title":"Hi",
                    "body":"Hi, How Are You Dear"
                ]
            ],
            "mutable-content" : false,
            "branch": "\(linkurl)"
        ] as [String : Any]
        let notification = UILocalNotification()
        notification.fireDate = Date(timeIntervalSinceNow: 1)
        notification.alertBody = "Notification for handling deeplink"
        notification.alertAction = "TestBed App"
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.userInfo = dict
        UIApplication.shared.scheduleLocalNotification(notification)
        //        sleep(2)
        // self.navigationController?.popToRootViewController(animated: true)
    }
    
    fileprivate func processShortURLGenerated(_ url: String?) {
        NSLog("Check out my ShortUrl!! \(url ?? "")")
        Utils.shared.setLogFile("CreateDeeplink")
        let alertMessage = self.getAPIDetailFromLogFile("CreateDeeplink.log")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            UserDefaults.standard.set("createdeeplinking", forKey: "isStatus")
            UserDefaults.standard.set(true, forKey: "isCreatedDeepLink")
            UserDefaults.standard.set("\(url ?? "")", forKey: "link")
            
            if self.forNotification == true {
                self.fireLocalNotification(linkurl: "\(url ?? "")")
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, forNotification: true)
            }else if self.isShareDeepLink == true {
                let bsl = BranchShareLink(universalObject: CommonMethod.sharedInstance.branchUniversalObject, linkProperties: CommonMethod.sharedInstance.linkProperties)
                if #available(iOS 13.0, *) {
                    let metaData: LPLinkMetadata = LPLinkMetadata()
                    let iconImage = UIImage(named: "qentelli_logo")
                    metaData.iconProvider = NSItemProvider(object: iconImage!)
                    metaData.title = "Share Deeplink from the app"
                    metaData.url = URL(string: "\(url ?? "")")
                    bsl.lpMetaData = metaData
                }
                bsl.presentActivityViewController(from: self, anchor: nil)
            } else if self.isTrackContent == true {
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, TrackContentWeb: true)
            } else if self.isNavigateToContent == true {
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, NavigateToContent: true)
            } else if self.isDisplayContent == true {
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, displayContent: true)
            } else if self.handleLinkInWebview == true {
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, handleLinkInWebview: true)
            } else if self.isCreateDeepLink == true{
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage, CreateDeepLink: true)
            } else {
                self.launchTextViewController(url: "\(url ?? "")", message: alertMessage)
            }
        }
    }
    
    func launchTextViewController(url: String? = "",message: String? = "", ShareDeepLink: Bool? = false, displayContent: Bool? = false, NavigateToContent: Bool? = false, TrackContent: Bool? = false, TrackContentWeb: Bool? = false, handleLinkInWebview: Bool? = false, CreateDeepLink: Bool? = false, forNotification: Bool? = false) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController {
            vc.isTrackContent = TrackContent!
            vc.forNotification = forNotification!
            vc.isCreateDeepLink = CreateDeepLink!
            vc.isShareDeepLink = ShareDeepLink!
            vc.isNavigateToContent = NavigateToContent!
            vc.handleLinkInWebview = handleLinkInWebview!
            vc.isDisplayContent = displayContent!
            vc.isTrackContenttoWeb = TrackContentWeb!
            vc.textViewText = message ?? ""
            vc.responseStatus = self.responseStatus
            vc.url = url ?? ""
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func loadTextWithFileName(_ fileName: String) -> String? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                return nil
            }
            return text
        }
        return nil
    }
    
    fileprivate func getAPIDetailFromLogFile(_ fileName: String) -> String{
        var alertMessage = "LogFilePath : \(self.getLogFilepath(fileName)!) \n\n"
        alertMessage = alertMessage + "\n\n"
        if let fileContent = self.loadTextWithFileName(fileName), !fileContent.isEmpty {
            let startlocation = fileContent.range(of: "BranchSDK API LOG START OF FILE")
            let endlocation = fileContent.range(of: "BranchSDK API LOG END OF FILE")
            let apiResponse = fileContent[startlocation!.lowerBound..<endlocation!.lowerBound]
            alertMessage = alertMessage + apiResponse
        }
        return alertMessage
    }
    
    fileprivate func getLogFilepath(_ fileName: String) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = dir?.appendingPathComponent(fileName)
        let fileURLStr = fileURL?.path
        return fileURLStr
    }
    
    @IBAction func submitAction(sender : UIButton) {
        self.view.endEditing(true)
        let linkProperties = BranchLinkProperties()
        linkProperties.feature = txtFldFeature.text
        linkProperties.channel = txtFldCChannel.text
        linkProperties.campaign = txtFldChampaignName.text
        linkProperties.stage = txtFldStage.text
        linkProperties.addControlParam("$desktop_url", withValue: txtFldDeskTopUrl.text)
        linkProperties.addControlParam("$ios_url", withValue: txtFldiOSTopUrl.text)
        linkProperties.addControlParam("$android_url", withValue: txtFldAndroidUrl.text)
        linkProperties.addControlParam("custom", withValue: txtFldAdditionalData.text)
        if isNavigateToContent == true {
            linkProperties.addControlParam("nav_to", withValue: "landing_page")
        } else if isDisplayContent == true {
            linkProperties.addControlParam("display_Cont", withValue: "landing_page")
        }
        
        
        CommonMethod.sharedInstance.branchUniversalObject.getShortUrl(with: linkProperties, andCallback: {[weak self] url, error in
            if error == nil {
                self?.responseStatus = "Success"
                self?.processShortURLGenerated(url)
            } else {
                self?.responseStatus = "Failure"
            }
        })
        
        
    }
    
}

extension GenerateURLVC {
    func uiSetUp() {
        let submitBtn = UIButton(frame: CGRect(x: self.view.frame.width/2-60, y: txtFldAdditionalData.frame.maxY+15, width: 120, height: 55))
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
        txtFldAndroidUrl.setLeftPaddingPoints(10)
        txtFldiOSTopUrl.setLeftPaddingPoints(10)
        
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
        txtFldAndroidUrl.attributedPlaceholder = NSAttributedString(
            string: "Android URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldiOSTopUrl.attributedPlaceholder = NSAttributedString(
            string: "iOS URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldAdditionalData.attributedPlaceholder = NSAttributedString(
            string: "Additional Data",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
    }
}

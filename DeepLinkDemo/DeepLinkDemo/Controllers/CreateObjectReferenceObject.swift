//  CreateObjectReferenceObject.swift
//  DeepLinkDemo
//  Created by Rakesh kumar on 4/19/22.

import UIKit
import BranchSDK


class CreateObjectReferenceObject: ParentViewController {
    @IBOutlet weak var txtFldContentTitle: UITextField!
    @IBOutlet weak var txtFldCanonicalIdentifier: UITextField!
    @IBOutlet weak var txtFldDescription: UITextField!
    @IBOutlet weak var txtFldImageUrl: UITextField!
    @IBOutlet weak var scrollViewMain: UIScrollView!
    
    var screenMode = 0
    var txtFldValue = ""
    var responseStatus = ""
    
    enum ScreenMode  {
        static let createBUO = 0
        static let readdeeplink = 1
        static let sharedeeplink = 2
        static let navigatetoContent = 3
        static let handlLinkinWebview = 4
        static let createdeeplink = 5
        static let sendnotification = 6
        static let trackContent = 7
        static let displayContent = 8
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uiSetUp()
        
        super.reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.screenMode == ScreenMode.trackContent {
            Utils.shared.setLogFile("TrackContent")
        }
        else {
            Utils.shared.setLogFile("CreateBUO")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollViewMain.contentSize.height = scrollViewMain.subviews.sorted(by: { $0.frame.maxY < $1.frame.maxY }).last?.frame.maxY ?? scrollViewMain.contentSize.height
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func addMetaDataAction(sender: UIButton) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "AddMetaDataVC") as? AddMetaDataVC {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    fileprivate func handleOkBtnAction(dict : [String:Any], alertMessage: String) {
        Utils.shared.setLogFile("CreateBUO")
        if self.screenMode == ScreenMode.displayContent {
            launchGenerateURLVC(dict: dict, displayContent: true)
        }else if self.screenMode == ScreenMode.trackContent {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, message: alertMessage, TrackContent: true)
        }else if self.screenMode == ScreenMode.sendnotification {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, forNotification: true)
        }else if self.screenMode == ScreenMode.createdeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, CreateDeepLink: true)
        }else if self.screenMode == ScreenMode.sharedeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, ShareDeepLink: true)
        }else if self.screenMode == ScreenMode.readdeeplink {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict)
        }else if self.screenMode == ScreenMode.navigatetoContent {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, NavigateToContent: true)
        }else if self.screenMode == ScreenMode.handlLinkinWebview {
            NSLog("screenMode:", self.screenMode)
            launchGenerateURLVC(dict: dict, handleLinkInWebview: true)
        }else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func launchGenerateURLVC(dict: [String:Any], message: String? = "", ShareDeepLink: Bool? = false, displayContent: Bool? = false, NavigateToContent: Bool? = false, TrackContent: Bool? = false, handleLinkInWebview: Bool? = false, CreateDeepLink: Bool? = false, forNotification: Bool? = false) {
        if self.screenMode == ScreenMode.trackContent {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            if let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController {
                vc.isTrackContent = TrackContent!
                vc.forNotification = forNotification!
                vc.isCreateDeepLink = CreateDeepLink!
                vc.isShareDeepLink = ShareDeepLink!
                vc.isNavigateToContent = NavigateToContent!
                vc.handleLinkInWebview = handleLinkInWebview!
                vc.isDisplayContent = displayContent!
                vc.dictData = dict
                vc.textViewText = message!
                vc.responseStatus = self.responseStatus
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            if let vc = storyBoard.instantiateViewController(withIdentifier: "GenerateURLVC") as? GenerateURLVC {
                vc.isTrackContent = TrackContent!
                vc.forNotification = forNotification!
                vc.isCreateDeepLink = CreateDeepLink!
                vc.isShareDeepLink = ShareDeepLink!
                vc.isNavigateToContent = NavigateToContent!
                vc.handleLinkInWebview = handleLinkInWebview!
                vc.isDisplayContent = displayContent!
                vc.dictData = dict
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc func submitAction(sender : UIButton) {
        
        self.view.endEditing(true)
        CommonMethod.sharedInstance.branchUniversalObject = BranchUniversalObject(canonicalIdentifier: txtFldCanonicalIdentifier.text!)
        CommonMethod.sharedInstance.branchUniversalObject.title = txtFldContentTitle.text!
        CommonMethod.sharedInstance.branchUniversalObject.contentDescription = txtFldDescription.text!
        CommonMethod.sharedInstance.branchUniversalObject.imageUrl = txtFldImageUrl.text!
        let linkProperties = BranchLinkProperties()
        
        
        var dict = [String:Any]()
        dict["$canonicalIdentifier"] = txtFldCanonicalIdentifier.text!
        dict["title"] = txtFldContentTitle.text!
        dict["description"] = txtFldDescription.text!
        dict["imgurl"] = txtFldImageUrl.text!
        
        CommonMethod.sharedInstance.branchUniversalObject.locallyIndex = true
        CommonMethod.sharedInstance.branchUniversalObject.publiclyIndex = true
        if CommonMethod.sharedInstance.contentMetaData != nil {
            CommonMethod.sharedInstance.branchUniversalObject.contentMetadata = CommonMethod.sharedInstance.contentMetaData!
        }
        print("universalObject:", CommonMethod.sharedInstance.branchUniversalObject)
        NSLog("CommonMethod.sharedInstance.branchUniversalObject:",CommonMethod.sharedInstance.branchUniversalObject)
        
        if self.screenMode == ScreenMode.trackContent {
            let selectedEvent: BranchStandardEvent = BranchStandardEvent(rawValue: txtFldValue)
            BranchEvent.standardEvent(selectedEvent, withContentItem: CommonMethod.sharedInstance.branchUniversalObject).logEvent {[weak self] isLogged, loggingErr in
                if isLogged {
                    self?.responseStatus = "Success"
                    NSLog("BranchEvent Logged")
                    Utils.shared.setLogFile("TrackContent")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        //AJAY
                        let alertMessage = self?.getAPIDetailFromLogFile(fileName: "TrackContent.log")
                        
                        self?.handleOkBtnAction(dict: dict, alertMessage: alertMessage ?? "")
                    }
                }else{
                    NSLog("BranchEvent failed to log \(loggingErr?.localizedDescription ?? "NA")")
                }
            }
            
        }
        else {
            CommonMethod.sharedInstance.branchUniversalObject.listOnSpotlight(with: linkProperties) { (url, error) in
                if (error == nil) {
                    NSLog("Successfully indexed on spotlight \(url)")
                }
            }
            let alert = UIAlertController(title: "Alert", message: "BranchUniversalObject reference created", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                UserDefaults.standard.set("buo", forKey: "isStatus")
                UserDefaults.standard.set(true, forKey: "isCreatedBUO")
                self.handleOkBtnAction(dict: dict, alertMessage: "")
            }))
            self.present(alert, animated: true, completion: nil)
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
    
    fileprivate func getAPIDetailFromLogFile(fileName: String) -> String{
        var alertMessage = "LogFilePath : \(self.getLogFilepath(fileName)!) \n\n"
        alertMessage = alertMessage + "\n\n"
        if let fileContent = self.loadTextWithFileName(fileName), !fileContent.isEmpty {
            
            if let startlocation = fileContent.range(of: "BranchSDK API LOG START OF FILE"),let endlocation = fileContent.range(of: "BranchSDK API LOG END OF FILE"){
                let apiResponse = fileContent[startlocation.lowerBound..<endlocation.lowerBound]
                alertMessage = alertMessage + apiResponse
            }
            if alertMessage.isEmpty{
                alertMessage = "No Content available in File"
            }
            NSLog("test == ,\(fileContent)")
        }
        return alertMessage
    }
    
    fileprivate func getLogFilepath(_ fileName: String) -> String? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = dir?.appendingPathComponent(fileName)
        let fileURLStr = fileURL?.path
        return fileURLStr
    }
}

extension CreateObjectReferenceObject {
    func uiSetUp() {
        
        let addMetaDataBtn = UIButton(frame: CGRect(x: self.view.frame.width/2-90, y: txtFldImageUrl.frame.maxY+30, width: 180, height: 55))
        addMetaDataBtn.setTitle("Add Metadata", for: .normal)
        addMetaDataBtn.backgroundColor = UIColor(red: 89.0/255.0, green: 12.0/255.0, blue: 228.0/255.0, alpha: 1.0)
        addMetaDataBtn.layer.cornerRadius = 8
        addMetaDataBtn.setTitleColor(UIColor.white, for: .normal)
        addMetaDataBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22.0)
        addMetaDataBtn.addTarget(self, action: #selector(addMetaDataAction), for: .touchUpInside)
        scrollViewMain.addSubview(addMetaDataBtn)
        
        let submitBtn = UIButton(frame: CGRect(x: self.view.frame.width/2-60, y: addMetaDataBtn.frame.maxY+30, width: 120, height: 55))
        submitBtn.setTitle("Submit", for: .normal)
        submitBtn.backgroundColor = UIColor(red: 89.0/255.0, green: 12.0/255.0, blue: 228.0/255.0, alpha: 1.0)
        submitBtn.layer.cornerRadius = 8
        submitBtn.setTitleColor(UIColor.white, for: .normal)
        submitBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22.0)
        submitBtn.addTarget(self, action: #selector(self.submitAction), for: .touchUpInside)
        scrollViewMain.addSubview(submitBtn)
        
        
        txtFldContentTitle.setLeftPaddingPoints(10)
        txtFldDescription.setLeftPaddingPoints(10)
        txtFldImageUrl.setLeftPaddingPoints(10)
        txtFldCanonicalIdentifier.setLeftPaddingPoints(10)
        txtFldCanonicalIdentifier.attributedPlaceholder = NSAttributedString(
            string: "Canonical Identifier",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        
        txtFldContentTitle.attributedPlaceholder = NSAttributedString(
            string: "Content Title",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        
        txtFldDescription.attributedPlaceholder = NSAttributedString(
            string: "Content Description",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        txtFldImageUrl.attributedPlaceholder = NSAttributedString(
            string: "Image URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
    }
}

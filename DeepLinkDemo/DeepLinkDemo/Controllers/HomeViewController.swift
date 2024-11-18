//  ViewController.swift
//  DeepLinkDemo
//  Created by Rakesh kumar on 4/15/22

import UIKit
import BranchSDK
class HomeViewController: UITableViewController {
    private var reachability:Reachability?
    
    @IBOutlet weak var btnCreatBUO: UIButton!
    @IBOutlet weak var btnTrackingEnabled: UIButton!
    @IBOutlet weak var btnCreateDeepLinking: UIButton!
    @IBOutlet weak var btnShareLink: UIButton!
    @IBOutlet weak var btnSendNotification: UIButton!
    @IBOutlet weak var btnTrackUser: UIButton!
    @IBOutlet weak var btnLoadWebView: UIButton!
    @IBOutlet weak var btReadDeeplink: UIButton!
    @IBOutlet weak var btnTrackContent: UIButton!
    @IBOutlet weak var btnNavigateToContent: UIButton!
    @IBOutlet weak var btnDisplayContent: UIButton!
    @IBOutlet weak var btnReadLog: UIButton!
    @IBOutlet weak var btnSetDMAParams: UIButton!
    @IBOutlet weak var btnSendV2Event: UIButton!
    @IBOutlet weak var btnSetAttributionLevel: UIButton!
    
    @IBOutlet weak var switchControl: UISwitch!
    
    @IBOutlet weak var labelStatus: UILabel!
    
    let branchObj:Branch! = nil
    var logData: String! = ""
    var branchSDKInitialized = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnTrackingEnabled.layer.cornerRadius = 8.0
        btnCreatBUO.layer.cornerRadius = 8.0
        btnCreateDeepLinking.layer.cornerRadius = 8.0
        btnShareLink.layer.cornerRadius = 8.0
        btnShareLink.layer.cornerRadius = 8.0
        btnTrackUser.layer.cornerRadius = 8.0
        btnSendNotification.layer.cornerRadius = 8.0
        btReadDeeplink.layer.cornerRadius = 8.0
        btnTrackContent.layer.cornerRadius = 8.0
        btnNavigateToContent.layer.cornerRadius = 8.0
        btnReadLog.layer.cornerRadius = 8.0
        btnLoadWebView.layer.cornerRadius = 8.0
        btnSetDMAParams.layer.cornerRadius = 8.0
        btnSendV2Event.layer.cornerRadius = 8.0
        btnSetAttributionLevel.layer.cornerRadius = 8.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name("NotificationIdentifier"), object: nil)
        
        reachabilityCheck(textValue:"")
        
        if Branch.trackingDisabled(){
            switchControl.isOn = false
        }else{
            switchControl.isOn = true
        }
        
        btnReadLog.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("Homepage")
    }
    
    func reachabilityCheck(textValue:String?) {
        CommonMethod.sharedInstance.contentMetaData = nil
        reachability = Reachability()!
        reachability!.whenReachable = { reachability in
            Branch.setBranchKey("key_test_om2EWe1WBeBYmpz9Z1mdpopouDmoN72T")
            DispatchQueue.main.async {
                if textValue == "displayContent" {
                    self.initBranch()
                    self.launchBUOVC(mode: 8)
                } else if textValue == "navigatetoContent" {
                    self.initBranch()
                    self.launchBUOVC(mode: 3)
                } else if textValue == "sendNotification" {
                    self.initBranch()
                    self.launchBUOVC(mode: 6)
                } else if textValue == "loadUrlInWeb" {
                    self.initBranch()
                    self.launchBUOVC(mode: 4)
                } else if textValue == "createDeep" {
                    self.initBranch()
                    self.launchBUOVC(mode: 5)
                } else if textValue == "shareDeeplinking" {
                    self.initBranch()
                    self.launchBUOVC(mode: 2)
                } else if textValue == "readDeeplinking" {
                    self.initBranch()
                    self.launchBUOVC(mode: 1)
                } else if textValue == "trackContent" {
                    self.initBranch()
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "TrackContentVC") as? TrackContentVC {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else if textValue == "trackUser" {
                    self.initBranch()
                    Branch.getInstance().setIdentity("qentelli_test_user") { params, error in
                        
                        if let referringParams = params as? [String :AnyObject] {
                            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                            if let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController {
                                vc.isTrackUser = true
                                vc.textViewText = "Result \(referringParams)"
                                vc.responseStatus = "Success"
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        }else{
                            NSLog("track user  error--> \(error!.localizedDescription)")
                        }
                    }
                } else if textValue == "swichAction" {
                    
                } else if textValue == "createObject" {
                    self.initBranch()
                    self.launchBUOVC(mode: 0)
                } else if textValue == "readSystemLog" {
                    self.initBranch()
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "LogFileListViewController") as? LogFileListViewController {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else if textValue == "setDMAParams" {
                    self.setDMAParamsWrapper()
               } else if textValue == "sendV2Event" {
                   self.sendV2EventWrapper()
               } else if textValue == "setAttributionLevel" {
                   self.setAttributionLevelWrapper()
               }
            }
        }
        
        reachability?.whenUnreachable = { reachability in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.networkError()
            }
        }
        do {
            try reachability?.startNotifier()
        } catch {
            NSLog("Unable to start notifier")
        }
    }
    func launchBUOVC(mode: Int) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "CreateObjectReferenceObject") as? CreateObjectReferenceObject {
            vc.screenMode = mode
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func networkError() {
        CommonAlert.shared.showActionAlertView(title: "Failure", message: "Your internet/network connection appears to be offline. Please check your internet/network connection.", actions: [], preferredStyle: .alert, viewController: self)
    }
    
    func enableBranchLogging(callback: @escaping BranchLogCallback){
        Branch.enableLogging(at: .verbose, withCallback: callback)
    }
    
    func initBranch(){
        if branchSDKInitialized {
            return
        }
        self.enableBranchLogging(){(message:String, loglevel:BranchLogLevel, error:Error?)->() in
            if (message.contains("BranchSDK")){
                self.logData = self.logData + message + "\n"
                Utils.shared.printLogMessage(message + "\n")
            }
        }
        AppDelegate.shared.getBranchData(AppDelegate.shared.launchOption)
        branchSDKInitialized = true
    }
    
    func logEvent(){
        let event = BranchEvent.standardEvent(.purchase)
        // Add a populated `BranchUniversalObject` to the event
        let buo = BranchUniversalObject(canonicalIdentifier: "item/12345")
        event.contentItems     = [ buo ]
        // Add additional event data
        event.alias = "my custom alias"
        event.transactionID = "12344555"
        event.eventDescription = "event_description"
        event.searchQuery = "item 123"
        event.customData = [
            "Custom_Event_Property_Key1": "Custom_Event_Property_val1",
            "Custom_Event_Property_Key2": "Custom_Event_Property_val2"
        ]
        // Log the event
        event.logEvent()
    }
    
    func setAttributionLevelWrapper() {
        self.logData = "Error: Missing testData.\n"

        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController
        vc?.isSetAttributionLevel = true
        
        do {
            let argCount = ProcessInfo.processInfo.arguments.count
            if  argCount >= 2 {
                
                for i in (1 ..< argCount) {
                    let data = ProcessInfo.processInfo.arguments[i].data(using: .utf8)!
                    
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:AnyObject]
                    {
                        if jsonObject["consumer_protection_attribution_level"] != nil {
                            let attribution_level = jsonObject["consumer_protection_attribution_level"] as! String
                            self.logData = ""
                            self.enableBranchLogging(){(msg:String,msg2:BranchLogLevel,msg3:Error?)->() in
                                if (msg.contains("BranchSDK")){
                                    self.logData = self.logData + msg + "\n"
                                }
                                vc?.updateText(msg: self.logData)
                            }
                            if(self.branchSDKInitialized){
                                Branch.getInstance().resetUserSession()
                            }
                            
                            switch attribution_level {
                            case "0":
                                Branch.getInstance().setConsumerProtectionAttributionLevel(.full)
                            case "1":
                                Branch.getInstance().setConsumerProtectionAttributionLevel(.reduced)
                            case "2":
                                Branch.getInstance().setConsumerProtectionAttributionLevel(.minimal)
                            case "3":
                                Branch.getInstance().setConsumerProtectionAttributionLevel(.none)
                            default:
                                Branch.getInstance().setConsumerProtectionAttributionLevel(.full)
                            }
                            
                            AppDelegate.shared.getBranchData(AppDelegate.shared.launchOption)
                            self.branchSDKInitialized = true
                        } else {
                            self.logData = "Missing params from JSON Object: \n" + jsonObject.description
                        }
                    } else {
                        self.logData = "Bad JSON : \n" + ProcessInfo.processInfo.arguments[i]
                    }
                }

                
            }
        } catch let error as NSError {
            print(error)
            self.logData += error.localizedDescription
        }
        vc?.updateText(msg: self.logData)
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func setDMAParamsWrapper() {
        self.logData = "Error: Missing testData.\n"
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController
        vc?.isSetDMAParams = true
        
        do {
            let argCount = ProcessInfo.processInfo.arguments.count
            if  argCount >= 2 {
                
                for i in (1 ..< argCount) {
                    let data = ProcessInfo.processInfo.arguments[i].data(using: .utf8)!
                    
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String:AnyObject]
                    {
                        if ((jsonObject["dma_eea"] != nil) && (jsonObject["dma_eea"] != nil) && (jsonObject["dma_eea"] != nil)) {
                            let dma_eea = jsonObject["dma_eea"] as! Bool
                            let dma_ad_personalization = jsonObject["dma_ad_personalization"] as! Bool
                            let dma_ad_user_data = jsonObject["dma_ad_user_data"] as! Bool
                            self.logData = ""
                            self.enableBranchLogging(){(msg:String,msg2:BranchLogLevel,msg3:Error?)->() in
                                if (msg.contains("BranchSDK")){
                                    self.logData = self.logData + msg + "\n"
                                }
                                vc?.updateText(msg: self.logData)
                            }
                            if(self.branchSDKInitialized){
                                Branch.getInstance().resetUserSession()
                            }
                            
                            Branch.setDMAParamsForEEA(dma_eea, adPersonalizationConsent: dma_ad_personalization, adUserDataUsageConsent: dma_ad_user_data)
                            AppDelegate.shared.getBranchData(AppDelegate.shared.launchOption)
                            self.branchSDKInitialized = true
                        } else {
                            self.logData = "Missing params from JSON Object: \n" + jsonObject.description
                        }
                    } else {
                        self.logData = "Bad JSON : \n" + ProcessInfo.processInfo.arguments[i]
                    }
                }

                
            }
        } catch let error as NSError {
            print(error)
            self.logData += error.localizedDescription
        }
        vc?.updateText(msg: self.logData)
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func sendV2EventWrapper(){
        self.logData = ""
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "TextViewController") as? TextViewController
        
        self.enableBranchLogging(){(msg:String,msg2:BranchLogLevel,msg3:Error?)->() in
            if (msg.contains("BranchSDK")){
                self.logData = self.logData + msg + "\n"
                vc?.updateText(msg: self.logData)
            }
        }
        self.logEvent()
        self.navigationController?.pushViewController(vc!, animated: true)
        vc?.isSendV2Event = true
        vc?.updateText(msg: self.logData)
        self.branchSDKInitialized = true
    }
    
    @IBAction func sendNotificationAction(_ sender: Any) {
        reachabilityCheck(textValue: "sendNotification")
    }
    
    @objc func methodOfReceivedNotification(notification: Notification) {
        
        Branch.getInstance().initSession( launchOptions: AppDelegate.shared.launchOption,
                                          andRegisterDeepLinkHandlerUsingBranchUniversalObject: { [self] universalObject, linkProperties, error in
            if universalObject != nil {
                NSLog("UniversalObject", universalObject ?? "NA")
                NSLog("LinkProperties", linkProperties ?? "NA")
                NSLog("UniversalObject Metadata:", universalObject?.contentMetadata.customMetadata ?? "NA")
                if let isRead =  UserDefaults.standard.value(forKey: "isRead") as? Bool, isRead == true {
                    if let dictData = universalObject?.contentMetadata.customMetadata as? NSDictionary {
                        let referedlink = dictData.value(forKey: "~referring_link") as? String ?? ""
                        //                                    let linkurl = UserDefaults.standard.value(forKey: "link") as? String ?? ""
                        NSLog("referedlink:", referedlink)
                        UserDefaults.standard.set(referedlink, forKey: "link")
                        NSLog("Deep linked with object: %@.", universalObject ?? BranchUniversalObject());
                        let deeplinkText = universalObject?.contentMetadata.customMetadata.value(forKey: "deeplink_text")
                        let textDetail = "Successfully Deeplinked:\n\n%@\nSession Details:\n\n%@, \(String(describing: deeplinkText)) \(String(describing: Branch.getInstance().getLatestReferringParams()?.description))"
                        UserDefaults.standard.setValue(textDetail, forKey: "textDetail")
                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                        if let vc = storyBoard.instantiateViewController(withIdentifier: "DispalyVC") as? DispalyVC {
                            vc.textDescription = textDetail
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                } else {
                    NSLog("No Deep linked object");
                }
            }
        })
    }
    
    @IBAction func displayContentBtnAction(_ sender: Any) {
        reachabilityCheck(textValue: "displayContent")
    }
    
    @IBAction func navigatetoContentBtnAction(_ sender: Any) {
        reachabilityCheck(textValue: "navigatetoContent")
    }
    
    @IBAction func loadUrlInWebViewAction(_ sender: Any) {
        reachabilityCheck(textValue: "loadUrlInWeb")
    }
    
    @IBAction func createDeeplinking(_ sender: Any) {
        reachabilityCheck(textValue: "createDeep")
    }
    
    @IBAction func shareDeeplinking(_ sender: Any) {
        reachabilityCheck(textValue: "shareDeeplinking")
    }
    
    @IBAction func readDeeplinking(_ sender: Any) {
        reachabilityCheck(textValue: "readDeeplinking")
    }
    
    @IBAction func trackContentAction(_ sender: Any) {
        reachabilityCheck(textValue: "trackContent")
    }
    
    @IBAction func trackUserAction(_ sender: Any) {
        reachabilityCheck(textValue: "trackUser")
    }
    
    @IBAction func swichAction(_ sender: UISwitch) {
        reachabilityCheck(textValue: "swichAction")
        if sender.isOn == true {
            NSLog("is OFF", "ison")
            btnTrackingEnabled.setTitle("Tracking Enabled", for: .normal)
            btnTrackingEnabled.titleLabel?.font = UIFont.boldSystemFont(ofSize: 36)
            Branch.setTrackingDisabled(true)
            
        } else {
            NSLog("is ON", "isOFF")
            Branch.setTrackingDisabled(false)
            btnTrackingEnabled.setTitle("Tracking Disabled", for: .normal)
            btnTrackingEnabled.titleLabel?.font = UIFont(name: "Helvetica", size:36)
        }
    }
    
    @IBAction func createObject(_ sender: Any) {
        reachabilityCheck(textValue: "createObject")
        
    }
    
    @IBAction func readSystemLog(){
        reachabilityCheck(textValue: "readSystemLog")
        
        
    }
    
    @IBAction func setDMAParams(){
        reachabilityCheck(textValue: "setDMAParams")
    }
    
    @IBAction func sendV2Event(){
        reachabilityCheck(textValue: "sendV2Event")
    }
    
    @IBAction func setAttributionLevel(){
        reachabilityCheck(textValue: "setAttributionLevel")
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

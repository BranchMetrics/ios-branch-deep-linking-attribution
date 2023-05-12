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
    
    @IBOutlet weak var switchControl: UISwitch!
    
    @IBOutlet weak var labelStatus: UILabel!
    
    let branchObj:Branch! = nil
    
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
            
            DispatchQueue.main.async {
                if textValue == "displayContent" {
                    self.launchBUOVC(mode: 8)
                } else if textValue == "navigatetoContent" {
                    self.launchBUOVC(mode: 3)
                } else if textValue == "sendNotification" {
                    self.launchBUOVC(mode: 6)
                } else if textValue == "loadUrlInWeb" {
                    self.launchBUOVC(mode: 4)
                } else if textValue == "createDeep" {
                    self.launchBUOVC(mode: 5)
                } else if textValue == "shareDeeplinking" {
                    self.launchBUOVC(mode: 2)
                } else if textValue == "readDeeplinking" {
                    self.launchBUOVC(mode: 1)
                } else if textValue == "trackContent" {
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "TrackContentVC") as? TrackContentVC {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } else if textValue == "trackUser" {
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
                    self.launchBUOVC(mode: 0)
                } else if textValue == "readSystemLog" {
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    if let vc = storyBoard.instantiateViewController(withIdentifier: "LogFileListViewController") as? LogFileListViewController {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
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

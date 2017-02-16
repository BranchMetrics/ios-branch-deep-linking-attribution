//
//  ViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class ViewController: UITableViewController {
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var userIDTextField: UITextField!
    @IBOutlet weak var loadLinkPropertiesButton: UIButton!
    @IBOutlet weak var loadObjectPropertiesButton: UIButton!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var rewardsBucketTextField: UITextField!
    @IBOutlet weak var rewardsBalanceOfBucketTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var rewardPointsToRedeemTextField: UITextField!
    @IBOutlet weak var customEventNameTextField: UITextField!
    @IBOutlet weak var customEventMetadataTextView: UITextView!
    @IBOutlet weak var activeBranchKeyTextField: UITextField!
    @IBOutlet weak var activeSetDebugEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingBranchKeyTextField: UITextField!
    @IBOutlet weak var pendingSetDebugEnabledSwitch: UISwitch!
    
    var linkProperties = [String: AnyObject]()
    var universalObjectProperties = [String: AnyObject]()
    var creditHistory: Array<AnyObject>?
    var customEventMetadata = [String: AnyObject]()
    
    let branchLinkProperties = BranchLinkProperties()
    var branchUniversalObject = BranchUniversalObject()

    let shareText = "Shared from Branch's TestBed-Swift"
    
    let linkKeys: Set = ["~channel","~feature","~campaign","~stage",
                         "~tags","+spotlight_type","$fallback_url","$desktop_url",
                         "$ios_url","$ipad_url","$android_url","$windows_phone_url",
                         "$blackberry_url","$fire_url","$ios_wechat_url","$ios_weibo_url",
                         "$after_click_url","$web_only","$deeplink_path","$android_deeplink_path",
                         "$ios_deeplink_path","$match_duration","$always_deeplink","$ios_redirect_timeout",
                         "$android_redirect_timeout","$one_time_use","$ios_deepview","$android_deepview",
                         "$desktop_deepview"]
    
    let objectKeys: Set = ["$publicly_indexable","$keywords","$canonical_identifier",
                           "$exp_date","$content_type", "$og_title",
                           "$og_description","$og_image_url", "$og_image_width",
                           "$og_image_height","$og_video", "$og_url",
                           "$og_type","$og_redirect", "$og_app_id",
                           "$twitter_card","$twitter_title", "$twitter_description",
                           "$twitter_site","$twitter_app_country", "$twitter_player",
                           "$twitter_player_width","$twitter_player_height"]
    
    let systemKeys: Set = ["+clicked_branch_link","+referrer","~referring_link","+is_first_session",
                           "~id","~creation_source","+match_guaranteed","$identity_id",
                           "$one_time_use_used","+click_timestamp"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITableViewCell.appearance().backgroundColor = UIColor.white
        
        let notificationCenter = NotificationCenter.default
        
        // Add observer:
        notificationCenter.addObserver(self,
                                       selector: #selector(self.applicationDidBecomeActive),
                                       name:NSNotification.Name.UIApplicationDidBecomeActive,
                                       object:nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(self.refreshEnabledButtons),
                                       name: Notification.Name("BranchCallbackCompleted"),
                                       object: nil)
        
        linkTextField.text = ""
        refreshControlValues()
        refreshEnabledButtons()
    }
    
    func applicationDidBecomeActive() {
        refreshEnabledButtons()
    }
    
    func refreshEnabledButtons() {
        var enableButtons = false
        
        if let clickedBranchLink = Branch.getInstance().getLatestReferringParams()["+clicked_branch_link"] as! Bool? {
            enableButtons = clickedBranchLink
        }
        if enableButtons == true {
            loadLinkPropertiesButton.isEnabled = true
            loadObjectPropertiesButton.isEnabled = true
        } else {
            loadLinkPropertiesButton.isEnabled = false
            loadObjectPropertiesButton.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshControlValues()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0,0) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "userID")
        case (1,2) :
            self.performSegue(withIdentifier: "ShowLinkPropertiesTableView", sender: "LinkProperties")
        case (1,3) :
            self.performSegue(withIdentifier: "ShowBranchUniversalObjectPropertiesTableView", sender: "BranchUniversalObjectProperties")
        case (1,4) :
            guard linkTextField.text?.characters.count > 0 else {
                break
            }
            UIPasteboard.general.string = linkTextField.text
            showAlert("Link copied to clipboard", withDescription: linkTextField.text!)
        case (2,0) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "RewardsBucket")
        case (2,3) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "RewardPointsToRedeem")
        case (2,5) :
            let branch = Branch.getInstance()
            branch?.getCreditHistory { (creditHistory, error) in
                if (error == nil) {
                    self.creditHistory = creditHistory as Array?
                    self.performSegue(withIdentifier: "ShowCreditHistoryTableView", sender: "CreditHistory")
                } else {
                    print(String(format: "Branch TestBed: Error retrieving credit history: %@", error!.localizedDescription))
                    self.showAlert("Error retrieving credit history", withDescription:error!.localizedDescription)
                }
            }
        case (3,0) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "CustomEventName")
        case (3,1) :
            self.performSegue(withIdentifier: "ShowDictionaryTableView", sender: "CustomEventMetadata")
        case (3,3) :
            self.sendCommerceEvent(self)
        case (4,0) :
            if let params = Branch.getInstance().getLatestReferringParams() {
                let content = String(format:"LatestReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "ShowContentView", sender: "LatestReferringParams")
                print("Branch TestBed: LatestReferringParams:\n", content)
            }
        case (4,1) :
            if let params = Branch.getInstance().getFirstReferringParams() {
                let content = String(format:"FirstReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "ShowContentView", sender: "FirstReferringParams")
                print("Branch TestBed: FirstReferringParams:\n", content)
            }
        case (6,0) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "pendingBranchKey")
        default : break
        }
    }
    
    @IBAction func actionButtonTouchUpInside(_ sender: AnyObject) {
        
        for key in linkProperties.keys {
            setBranchLinkProperty(key)
        }
        
        if let canonicalIdentifier = universalObjectProperties["$canonical_identifier"] as? String {
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        } else {
            var canonicalIdentifier = ""
            for _ in 1...18 {
                canonicalIdentifier.append(String(arc4random_uniform(10)))
            }
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        }
        
        for key in universalObjectProperties.keys {
            setBranchUniversalObjectProperty(key)
        }

        branchUniversalObject.showShareSheet(with: branchLinkProperties, andShareText: shareText, from: self, anchor: actionButton) { (activityType, completed) in
            if (completed) {
                print(String(format: "Branch TestBed: Completed sharing to %@", activityType!))
            } else {
                print("Branch TestBed: Link Sharing Cancelled\n")
            }
        }
    }
    
    
    @IBAction func loadLinkPropertiesButtonTouchUpInside(_ sender: AnyObject) {
        let branch = Branch.getInstance()
        let params: Dictionary = (branch?.getLatestReferringParams())!
        
        linkProperties.removeAll()
        for key in linkKeys {
            if let value = params[key] {
                linkProperties[key] = value as AnyObject?
            }
        }
        self.showAlert("Link Properties Loadded", withDescription: "")
    }
    
    
    @IBAction func loadObjectPropertiesButtonTouchUpInside(_ sender: AnyObject) {
        let branch = Branch.getInstance()
        var params: Dictionary = (branch?.getLatestReferringParams())!
        
        universalObjectProperties.removeAll()
        for key in linkKeys { params.removeValue(forKey: key) }
        for key in systemKeys { params.removeValue(forKey: key) }
        for key in objectKeys {
            if let value = params[key] {
                universalObjectProperties[key] = value as AnyObject?
                params.removeValue(forKey: key)
            }
        }
        universalObjectProperties["customData"] = params as AnyObject?
        
        self.showAlert("Branch Universal Object Properties Loadded", withDescription: "")
    }
    
    @IBAction func createBranchLinkButtonTouchUpInside(_ sender: AnyObject) {
        
        for key in linkProperties.keys {
            setBranchLinkProperty(key)
        }
        
        if let canonicalIdentifier = universalObjectProperties["$canonical_identifier"] as? String {
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        } else {
            var canonicalIdentifier = ""
            for _ in 1...18 {
                canonicalIdentifier.append(String(arc4random_uniform(10)))
            }
            branchUniversalObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        }
        
        for key in universalObjectProperties.keys {
            setBranchUniversalObjectProperty(key)
        }
        
        branchUniversalObject.getShortUrl(with: branchLinkProperties) { (url, error) in
            if (error == nil) {
                print(self.branchLinkProperties.description())
                print(self.branchUniversalObject.description())
                print("Link Created: \(url?.description)")
                self.linkTextField.text = url
            } else {
                print(String(format: "Branch TestBed: %@", error as! CVarArg))
                self.showAlert("Link Creation Failed", withDescription: error!.localizedDescription)
            }
            
        }
    }
    
    @IBAction func redeemPointsButtonTouchUpInside(_ sender: AnyObject) {
        let points = rewardPointsToRedeemTextField.text != "" ? Int(rewardPointsToRedeemTextField.text!) : 5
        let bucket = rewardsBucketTextField.text != "" ? rewardsBucketTextField.text : "default"
        
        let branch = Branch.getInstance()
        branch?.redeemRewards(points!, forBucket: bucket) { (changed, error) in
            
            defer {
                self.rewardsBalanceOfBucketTextField.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            
            if (error != nil || !changed) {
                print(String(format: "Branch TestBed: Didn't redeem anything: %@", error as! CVarArg))
                self.showAlert("Redemption Unsuccessful", withDescription: error!.localizedDescription)
            } else {
                print("Branch TestBed: Five Points Redeemed!")
            }
            
            self.refreshRewardsBalanceOfBucket()
        }
        
    }
    
    @IBAction func reloadBalanceButtonTouchUpInside(_ sender: AnyObject) {
        refreshRewardsBalanceOfBucket()
    }
    
    @IBAction func sendEventButtonTouchUpInside(_ sender: AnyObject) {
        var customEventName = "button"
        let branch = Branch.getInstance()
        
        if customEventNameTextField.text != "" {
            customEventName = customEventNameTextField.text!
        }

        if customEventMetadata.count == 0 {
            branch?.userCompletedAction(customEventName)
        } else {
            branch?.userCompletedAction(customEventName, withState: customEventMetadata)
        }
        refreshRewardsBalanceOfBucket()
        self.showAlert(String(format: "Custom event '%@' dispatched", customEventName), withDescription: "")
    }

    @IBAction func sendCommerceEvent(_ sender: AnyObject) {
        let product = BNCProduct.init()
        product.price = NSDecimalNumber.init(string:"1000.99")
        product.sku = "acme007"
        product.name = "Acme brand 1 ton weight"
        product.quantity = 1.0;
        product.brand = "Acme";
        product.category = BNCProductCategoryMedia;
        product.variant = "Lite Weight";

        let commerceEvent = BNCCommerceEvent.init()
        commerceEvent.revenue = NSDecimalNumber.init(string:"1101.99")
        commerceEvent.currency = "USD"
        commerceEvent.transactionID = "tr00x8"
        commerceEvent.shipping = NSDecimalNumber.init(string:"100.00")
        commerceEvent.tax = NSDecimalNumber.init(string:"1.00");
        commerceEvent.coupon = "Acme weights coupon"
        commerceEvent.affiliation = "ACME by Amazon"
        commerceEvent.products = [ product ];

        Branch.getInstance()?.send(
            commerceEvent,
            metadata: ["Meta": "Never meta dog I didn't like." ],
            withCompletion: { (response, error) in
                let errorMessage: String = (error?.localizedDescription != nil) ?
                    error!.localizedDescription : "<nil>"
                let responseMessage  = (response?.description != nil) ?
                    response!.description : "<nil>"
                let message = String.init(
                    format:"Commerce event completion called.\nError: %@\nResponse:\n%@",
                    errorMessage,
                    responseMessage
                )
                NSLog("%@", message)
                self.showAlert("Commerce Event", withDescription: message)
            }
        )
    }

    @IBAction func showRewardsHistoryButtonTouchUpInside(_ sender: AnyObject) {
        let branch = Branch.getInstance()
        branch?.getCreditHistory { (creditHistory, error) in
            if (error == nil) {
                self.creditHistory = creditHistory as Array?
                self.performSegue(withIdentifier: "ShowCreditHistoryTableView", sender: nil)
            } else {
                print(String(format: "Branch TestBed: Error retrieving credit history: %@", error!.localizedDescription))
                self.showAlert("Error retrieving credit history", withDescription:error!.localizedDescription)
            }
        }
    }
    
    @IBAction func pendingSetDebugEnabledButtonValueChanged(_ sender: AnyObject) {
        DataStore.setPendingPendingSetDebugEnabled(self.pendingSetDebugEnabledSwitch.isOn)
    }
    
    
    func textFieldDidChange(_ sender:UITextField) {
        sender.resignFirstResponder()
    }
    
    func refreshRewardsBalanceOfBucket() {
        rewardsBalanceOfBucketTextField.isHidden = true
        activityIndicator.startAnimating()
        let branch = Branch.getInstance()
        branch?.loadRewards { (changed, error) in
            if (error == nil) {
                if self.rewardsBucketTextField.text == "" {
                    self.rewardsBalanceOfBucketTextField.text = String(format: "%ld", (branch?.getCredits())!)
                } else {
                    self.rewardsBalanceOfBucketTextField.text = String(format: "%ld", (branch?.getCreditsForBucket(self.rewardsBucketTextField.text))!)
                }
            }
        }
        activityIndicator.stopAnimating()
        rewardsBalanceOfBucketTextField.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        linkTextField.text = ""
        
        switch sender as! String {
        case "userID":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
            vc.viewTitle = "User ID"
            vc.header = "User ID"
            vc.footer = "This User ID (or developer_id) is the application-assigned ID of the user. If not assigned, referrals from links created by the user will show up as 'Anonymous' in reporting."
            vc.keyboardType = UIKeyboardType.alphabet
            vc.incumbantValue = userIDTextField.text!
        case "LinkProperties":
            let vc = (segue.destination as! LinkPropertiesTableViewController)
            vc.linkProperties = self.linkProperties
        case "BranchUniversalObjectProperties":
            let vc = (segue.destination as! BranchUniversalObjectPropertiesTableViewController)
            vc.universalObjectProperties = self.universalObjectProperties
        case "CreditHistory":
            let vc = (segue.destination as! CreditHistoryViewController)
            vc.creditTransactions = creditHistory
        case "RewardsBucket":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
            vc.viewTitle = "Rewards Bucket"
            vc.header = "Rewards Bucket"
            vc.footer = "Rewards are granted via rules configured in the Rewards Rules section of the dashboard. Rewards are normally accumulated in a 'default' bucket, however any bucket name can be specified in rewards rules. Use this setting to specify the name of a non-default rewards bucket."
            vc.keyboardType = UIKeyboardType.alphabet
            vc.incumbantValue = rewardsBucketTextField.text!
        case "RewardPointsToRedeem":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
            vc.viewTitle = "Reward Points"
            vc.header = "Number of Reward Points to Redeem"
            vc.footer = "This is the quantity of points to subtract from the selected bucket's balance."
            vc.keyboardType = UIKeyboardType.numberPad
            vc.incumbantValue = rewardPointsToRedeemTextField.text!
        case "CustomEventName":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
            vc.viewTitle = "Custom Event"
            vc.header = "Custom Event Name"
            vc.footer = "This is the name of the event that is referenced when creating rewards rules and webhooks."
            vc.keyboardType = UIKeyboardType.alphabet
            vc.incumbantValue = customEventNameTextField.text!
        case "CustomEventMetadata":
            let vc = segue.destination as! DictionaryTableViewController
            customEventMetadata = DataStore.getCustomEventMetadata()
            vc.dictionary = customEventMetadata
            vc.viewTitle = "Custom Event Metadata"
            vc.keyHeader = "Key"
            vc.keyPlaceholder = "key"
            vc.keyFooter = ""
            vc.valueHeader = "Value"
            vc.valueFooter = ""
            vc.keyKeyboardType = UIKeyboardType.default
            vc.valueKeyboardType = UIKeyboardType.default
        case "LatestReferringParams":
            let vc = (segue.destination as! ContentViewController)
            let dict: Dictionary = Branch.getInstance().getLatestReferringParams()
        
            if dict["~referring_link"] != nil {
                vc.contentType = "LatestReferringParams"
            } else {
                vc.contentType = "\nNot a referred session"
            }
        case "FirstReferringParams":
            let vc = (segue.destination as! ContentViewController)
            let dict: Dictionary = Branch.getInstance().getFirstReferringParams()
            if dict.count > 0 {
                vc.contentType = "FirstReferringParams"
            } else {
                vc.contentType = "\nApp has not yet been opened via a Branch link"
            }
        case "pendingBranchKey":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
            vc.viewTitle = "Branch Key"
            vc.header = "Branch Key"
            vc.footer = "This Branch key will be used the next time the application is closed (not merely backgrounded) and re-opened."
            vc.keyboardType = UIKeyboardType.alphabet
            vc.incumbantValue = DataStore.getPendingBranchKey()!
        default:
            break
        }
    }
    
    @IBAction func unwindTextViewFormTableViewController(_ segue:UIStoryboardSegue) {

        if let vc = segue.source as? TextViewFormTableViewController {
            
            switch vc.sender {
            case "userID":
                    
                if let userID = vc.textView.text {
                    
                    guard self.userIDTextField.text != userID else {
                        return
                    }
                    
                    let branch = Branch.getInstance()
                    
                    guard userID != "" else {
                        
                        branch?.logout { (changed, error) in
                            if (error != nil || !changed) {
                                print(String(format: "Branch TestBed: Unable to clear User ID: %@", error! as CVarArg))
                                self.showAlert("Error simulating logout", withDescription: error!.localizedDescription)
                            } else {
                                print("Branch TestBed: User ID cleared")
                                self.userIDTextField.text = userID
                                DataStore.setUserID(userID)
                                self.refreshRewardsBalanceOfBucket()
                            }
                        }
                        return
                    }
                    
                    branch?.setIdentity(userID) { (params, error) in
                        if (error == nil) {
                            print(String(format: "Branch TestBed: Identity set: %@", userID))
                            self.userIDTextField.text = userID
                            DataStore.setUserID(userID)
                            self.refreshRewardsBalanceOfBucket()
                            
                            let defaultContainer = UserDefaults.standard
                            defaultContainer.setValue(userID, forKey: "userID")
                            
                        } else {
                            print(String(format: "Branch TestBed: Error setting identity: %@", error! as CVarArg))
                            self.showAlert("Unable to Set Identity", withDescription:error!.localizedDescription)
                        }
                    }
                    
                }
            case "RewardsBucket":
                if let rewardsBucket = vc.textView.text {
                    
                    guard self.rewardsBucketTextField.text != rewardsBucket else {
                        return
                    }
                    DataStore.setRewardsBucket(rewardsBucket)
                    self.rewardsBucketTextField.text = rewardsBucket
                    self.refreshRewardsBalanceOfBucket()
                    
                }
            case "RewardPointsToRedeem":
                if let rewardPointsToRedeem = vc.textView.text {
                    
                    guard self.rewardPointsToRedeemTextField.text != rewardPointsToRedeem else {
                        return
                    }
                    DataStore.setRewardPointsToRedeem(rewardPointsToRedeem)
                    self.rewardPointsToRedeemTextField.text = rewardPointsToRedeem
                }
            case "CustomEventName":
                if let customEventName = vc.textView.text {
                    
                    guard self.customEventNameTextField.text != customEventName else {
                        return
                    }
                    DataStore.setCustomEventName(customEventName)
                    self.customEventNameTextField.text = customEventName
                }
            case "pendingBranchKey":
                if let pendingBranchKey = vc.textView.text {
                    guard self.pendingBranchKeyTextField.text != pendingBranchKey else {
                        return
                    }
                    DataStore.setPendingBranchKey(pendingBranchKey)
                    self.pendingBranchKeyTextField.text = pendingBranchKey
                }
            default: break
            }
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindDictionaryTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? DictionaryTableViewController {
            customEventMetadata = vc.dictionary
            DataStore.setCustomEventMetadata(customEventMetadata)
            if customEventMetadata.count > 0 {
                customEventMetadataTextView.text = customEventMetadata.description
            } else {
                customEventMetadataTextView.text = ""
            }
        }
    }
    
    @IBAction func unwindLinkPropertiesTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? LinkPropertiesTableViewController {
            linkProperties = vc.linkProperties
            DataStore.setLinkProperties(linkProperties)
        }
    }
    
    @IBAction func unwindBranchUniversalObjectTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? BranchUniversalObjectPropertiesTableViewController {
            universalObjectProperties = vc.universalObjectProperties
            DataStore.setUniversalObjectProperties(universalObjectProperties)
        }
    }
    
    func setBranchLinkProperty(_ key: String) {
        
        guard linkProperties[key] != nil else {
            return
        }
        print(key)
        switch key {
        case "~alias":
            branchLinkProperties.alias = linkProperties[key] as! String
        case "~channel":
            branchLinkProperties.channel = linkProperties[key] as! String
        case "~feature":
            branchLinkProperties.feature = linkProperties[key] as! String
        case "~stage":
            branchLinkProperties.stage = linkProperties[key] as! String
        case "~tags":
            branchLinkProperties.tags = linkProperties[key] as! [AnyObject]
        default:
            branchLinkProperties.addControlParam(key, withValue: linkProperties[key] as! String)
        }
    }
    
    func setBranchUniversalObjectProperty(_ key: String) {
        
        guard universalObjectProperties[key] != nil else {
            return
        }

        switch key {
        case "$canonical_identifier":
            branchUniversalObject.canonicalIdentifier = universalObjectProperties[key] as! String
        case "$og_description":
            if let description = universalObjectProperties[key] {
                branchUniversalObject.contentDescription = description as? String
            }
        case "$exp_date":
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let expirationDate = dateFormatter.date(from: universalObjectProperties[key] as! String)
            branchUniversalObject.expirationDate = expirationDate
        case "$og_image_url":
            if let imageURL = universalObjectProperties[key] {
                branchUniversalObject.imageUrl = imageURL as? String
            }
        case "$keywords":
            branchUniversalObject.keywords = universalObjectProperties[key] as! [AnyObject]
        case "$og_title":
            if let title = universalObjectProperties[key] {
                branchUniversalObject.title = title as? String
            }
        case "$content_type":
            if let contentType = universalObjectProperties[key] {
                branchUniversalObject.type = contentType as? String
            }
        case "$price":
            if let price = universalObjectProperties[key] as? String {
                if let float_price = Float(price) {
                    branchUniversalObject.price = CGFloat(float_price)
                } else {
                    branchUniversalObject.price = 0.0
                }
            }
        case "$currency":
            if let currency = universalObjectProperties[key] as? String {
                branchUniversalObject.currency = currency
            }
        case "customData":
            if let data = universalObjectProperties[key] as? [String: String] {
                for customDataKey in data.keys {
                    branchUniversalObject.addMetadataKey(customDataKey, value: data[customDataKey]!)
                }
            }
        default:
            branchUniversalObject.addMetadataKey(key, value: universalObjectProperties[key] as! String)
        }
        print(branchUniversalObject.description())
    }
    
    func refreshControlValues() {
        // First load the three values required to refresh the rewards balance
        userIDTextField.text = DataStore.getUserID()
        rewardsBucketTextField.text = DataStore.getRewardsBucket()
        rewardsBalanceOfBucketTextField.text = DataStore.getRewardsBalanceOfBucket()
        
        // Then initiate a refresh of the rewards balance
        refreshRewardsBalanceOfBucket()
        
        // Now get about populating the other controls
        linkProperties = DataStore.getLinkProperties()
        universalObjectProperties = DataStore.getUniversalObjectProperties()
        rewardPointsToRedeemTextField.text = DataStore.getRewardPointsToRedeem()
        customEventNameTextField.text = DataStore.getCustomEventName()
        customEventMetadata = DataStore.getCustomEventMetadata()
        if (customEventMetadata.count > 0) {
            customEventMetadataTextView.text = customEventMetadata.description
        } else {
            customEventMetadataTextView.text = ""
        }
        activeBranchKeyTextField.text = DataStore.getActiveBranchKey()
        activeSetDebugEnabledSwitch.isOn = DataStore.getActiveSetDebugEnabled()!
        pendingBranchKeyTextField.text = DataStore.getPendingBranchKey()
        pendingSetDebugEnabledSwitch.isOn = DataStore.getPendingSetDebugEnabled()!
        
        if activeBranchKeyTextField.text == "" {
            showAlert("Initialization Failure", withDescription: "Close and re-open app to initialize Branch")
        }
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            self.refreshRewardsBalanceOfBucket()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
}


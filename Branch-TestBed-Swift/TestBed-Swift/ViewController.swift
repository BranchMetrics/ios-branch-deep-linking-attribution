//
//  ViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
// TODO: rearrange Branch Link section layout
// TODO: fix wording when latestReferringParams are shown
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

class ViewController: UITableViewController, BranchShareLinkDelegate {
    
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
    @IBOutlet weak var commerceEventCustomMetadataTextView: UITextView!
    @IBOutlet weak var activeBranchKeyTextField: UITextField!
    @IBOutlet weak var activeSetDebugEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingBranchKeyTextField: UITextField!
    @IBOutlet weak var pendingSetDebugEnabledSwitch: UISwitch!
    
    var _dateFormatter: DateFormatter?
    var creditHistory: Array<AnyObject>?
    var customEventMetadata = [String: AnyObject]()
    var commerceEventCustomMetadata = [String: AnyObject]()
    
    let shareText = "Shared from Branch's TestBed-Swift"
    
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
        
        // Add version to footer
        let footerView = UILabel.init(frame: CGRect.zero);
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        footerView.text = String(format:"iOS %@ / v%@ / SDK v%@",
                                 UIDevice.current.systemVersion,
                                 appVersion as! CVarArg,
                                 BNC_SDK_VERSION
        )
        footerView.font = UIFont.systemFont(ofSize:11.0)
        footerView.textAlignment = NSTextAlignment.center
        footerView.textColor = UIColor.darkGray
        footerView.sizeToFit()
        var box = footerView.bounds
        box.size.height += 10.0
        footerView.frame = box
        self.tableView.tableFooterView = footerView;
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
        case (4,0) :
            self.performSegue(withIdentifier: "ShowCommerceEventDetailsTableView", sender: "CommerceEventDetails")
        case (4,1) :
            self.performSegue(withIdentifier: "ShowDictionaryTableView", sender: "CommerceEventCustomMetadata")
        case (5,0) :
            if let params = Branch.getInstance().getLatestReferringParams() {
                let content = String(format:"LatestReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "ShowContentView", sender: "LatestReferringParams")
                print("Branch TestBed: LatestReferringParams:\n", content)
            }
        case (6,1) :
            if let params = Branch.getInstance().getFirstReferringParams() {
                let content = String(format:"FirstReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "ShowContentView", sender: "FirstReferringParams")
                print("Branch TestBed: FirstReferringParams:\n", content)
            }
        case (7,0) :
            self.performSegue(withIdentifier: "ShowTextViewFormNavigationBar", sender: "pendingBranchKey")
        default : break
        }
    }
    
    func dateFormatter() -> DateFormatter {
        if _dateFormatter != nil {
            return _dateFormatter!;
        }
        _dateFormatter = DateFormatter()
        _dateFormatter?.locale = Locale(identifier: "en_US_POSIX");
        _dateFormatter?.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        _dateFormatter?.timeZone = TimeZone(secondsFromGMT: 0)
        return _dateFormatter!
    }
    
    //MARK: - Share a Branch Universal Object with BranchShareLink
    
    @IBAction func shareBranchLinkAction(_ sender: AnyObject) {
        let canonicalIdentifier = "id-" + self.dateFormatter().string(from: Date.init())
        
        let shareBranchObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        shareBranchObject.title = "Share Branch Link Example"
        shareBranchObject.canonicalUrl = "https://developer.branch.io/"
        shareBranchObject.imageUrl = "https://branch.io/img/press/kit/badge-black.png"
        shareBranchObject.keywords = [ "example", "short", "share", "link" ]
        shareBranchObject.contentDescription = "This is an example shared short link."
        shareBranchObject.addMetadataKey("publicSlug", value: canonicalIdentifier)
        
        let shareLinkProperties = BranchLinkProperties()
        shareLinkProperties.controlParams = ["$fallback_url": "https://support.branch.io/support/home"]
        
        if let branchShareLink = BranchShareLink.init(
            universalObject: shareBranchObject,
            linkProperties:  shareLinkProperties
            ) {
            branchShareLink.title = "Share your test link!"
            branchShareLink.shareText = "Shared from Branch's TestBed-Swift at \(self.dateFormatter().string(from: Date()))"
            branchShareLink.presentActivityViewController(
                from: self,
                anchor: actionButton
            )
        }
    }
    
    @IBAction func shareAliasBranchLinkAction(_ sender: AnyObject) {
        //  Share an alias Branch link:
        
        let alias = "Share-Alias-Link-Example"
        let canonicalIdentifier = alias
        
        let shareBranchObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        shareBranchObject.title = "Share Branch Link Example"
        shareBranchObject.canonicalUrl = "https://developer.branch.io/"
        shareBranchObject.imageUrl = "https://branch.io/img/press/kit/badge-black.png"
        shareBranchObject.keywords = [ "example", "short", "share", "link" ]
        shareBranchObject.contentDescription = "This is an example shared alias link."
        shareBranchObject.addMetadataKey("publicSlug", value: canonicalIdentifier)
        
        let shareLinkProperties = BranchLinkProperties()
        shareLinkProperties.alias = alias
        shareLinkProperties.controlParams = ["$fallback_url": "https://support.branch.io/support/home"]
        
        if let branchShareLink = BranchShareLink.init(
            universalObject: shareBranchObject,
            linkProperties:  shareLinkProperties
            ) {
            branchShareLink.title = "Share your alias link!"
            branchShareLink.delegate = self
            branchShareLink.shareText =
            "Shared from Branch's TestBed-Swift at \(self.dateFormatter().string(from: Date()))"
            branchShareLink.presentActivityViewController(
                from: self,
                anchor: actionButton
            )
        }
    }
    
    @IBAction func shareAliasActivityViewController(_ sender: AnyObject) {
        //  Share an alias Branch link:
        let alias = "Share-Alias-Link-Example"
        let canonicalIdentifier = alias
        
        let shareBranchObject = BranchUniversalObject.init(canonicalIdentifier: canonicalIdentifier)
        shareBranchObject.title = "Share Branch Link Example"
        shareBranchObject.canonicalUrl = "https://developer.branch.io/"
        shareBranchObject.imageUrl = "https://branch.io/img/press/kit/badge-black.png"
        shareBranchObject.keywords = [ "example", "short", "share", "link" ]
        shareBranchObject.contentDescription = "This is an example shared alias link."
        shareBranchObject.addMetadataKey("publicSlug", value: canonicalIdentifier)
        
        let shareLinkProperties = BranchLinkProperties()
        shareLinkProperties.alias = alias
        shareLinkProperties.controlParams = ["$fallback_url": "https://support.branch.io/support/home"]
        
        if let branchShareLink = BranchShareLink.init(
            universalObject: shareBranchObject,
            linkProperties:  shareLinkProperties
            ) {
            branchShareLink.shareText = "Shared with TestBed-Swift"
            branchShareLink.delegate = self
            let activityViewController = UIActivityViewController.init(
                activityItems: branchShareLink.activityItems(),
                applicationActivities: nil
            )
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func branchShareLinkWillShare(_ shareLink: BranchShareLink) {
        // Link properties, such as alias or channel can be overridden here based on the users'
        // choice stored in shareSheet.activityType.
        shareLink.shareText =
            "Shared through '\(shareLink.linkProperties.channel!)'\nfrom Branch's TestBed-Swift" +
        "\nat \(self.dateFormatter().string(from: Date()))."
        
        // In this example, we over-ride the channel so that the channel in the Branch short link
        // is always 'ios-share'. This allows a short alias link to always be created.
        shareLink.linkProperties.channel = "ios-share"
    }
    
    func branchShareLink(_ shareLink: BranchShareLink, didComplete completed: Bool, withError error: Error?) {
        if (error != nil) {
            print("Branch: Error while sharing! Error: \(error!.localizedDescription).")
        } else if (completed) {
            if let channel = shareLink.activityType {
                print("Branch: User completed sharing with activity '\(channel)'.")
                Branch.getInstance().userCompletedAction("UserShared", withState: ["Channel": channel])
            }
        } else {
            print("Branch: User cancelled sharing.")
        }
    }
    
    //MARK: - Link Properties
    
    @IBAction func loadLinkPropertiesButtonTouchUpInside(_ sender: AnyObject) {
        let branch = Branch.getInstance()
        
        if let params = branch?.getLatestReferringParams() as? [String: AnyObject] {
            DataStore.setLinkProperties(params)
            self.showAlert("Link Properties Loadded", withDescription: "")
        } else {
            // The button should be greyed out to prevent this, but just in case...
            self.showAlert("Error: No Link Properties", withDescription: "This is not a referred session")
        }
    }
    
    
    @IBAction func loadObjectPropertiesButtonTouchUpInside(_ sender: AnyObject) {
        let branch = Branch.getInstance()
        
        if let params = branch?.getLatestReferringParams() as? [String: AnyObject] {
            DataStore.setUniversalObject(params)
        } else {
            DataStore.clearUniversalObject()
        }
        
        self.showAlert("Branch Universal Object Properties Loadded", withDescription: "")
    }
    
    @IBAction func createBranchLinkButtonTouchUpInside(_ sender: AnyObject) {
        
        let branchLinkProperties = DataStore.getBranchLinkProperties()
        let branchUniversalObject = DataStore.getBranchUniversalObject()
        
        branchUniversalObject.getShortUrl(with: branchLinkProperties) { (url, error) in
            if (url != nil) {
                print(branchLinkProperties.description())
                print(branchUniversalObject.description())
                print("Link Created: \(String(describing: url?.description))")
                self.linkTextField.text = url
            } else {
                print(String(format: "Branch TestBed: %@", error! as CVarArg))
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
                print(String(format: "Branch TestBed: Didn't redeem anything: %@", error! as CVarArg))
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
        
        let commerceEvent = DataStore.getBNCCommerceEvent()
        
        WaitingViewController.showWithMessage(
            message: "Getting parameters...",
            activityIndicator:true,
            disableTouches:true
        )
        
        Branch.getInstance()?.send(
            commerceEvent,
            metadata: commerceEventCustomMetadata,
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
                WaitingViewController.hide()
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
            vc.linkProperties = DataStore.getLinkProperties()
        case "BranchUniversalObjectProperties":
            let vc = (segue.destination as! BranchUniversalObjectPropertiesTableViewController)
            vc.universalObject = DataStore.getUniversalObject()
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
            vc.sender = sender as! String
        case "CommerceEventCustomMetadata":
            let vc = segue.destination as! DictionaryTableViewController
            commerceEventCustomMetadata = DataStore.getCommerceEventCustomMetadata()
            vc.dictionary = commerceEventCustomMetadata
            vc.viewTitle = "Commerce Metadata"
            vc.keyHeader = "Key"
            vc.keyPlaceholder = "key"
            vc.keyFooter = ""
            vc.valueHeader = "Value"
            vc.valueFooter = ""
            vc.keyKeyboardType = UIKeyboardType.default
            vc.valueKeyboardType = UIKeyboardType.default
            vc.sender = sender as! String
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
            
            if vc.sender == "CustomEventMetadata" {
                customEventMetadata = vc.dictionary
                DataStore.setCustomEventMetadata(customEventMetadata)
                if customEventMetadata.count > 0 {
                    customEventMetadataTextView.text = customEventMetadata.description
                } else {
                    customEventMetadataTextView.text = ""
                }
            } else if vc.sender == "CommerceEventCustomMetadata" {
                commerceEventCustomMetadata = vc.dictionary
                DataStore.setCommerceEventCustomMetadata(commerceEventCustomMetadata)
                if commerceEventCustomMetadata.count > 0 {
                    commerceEventCustomMetadataTextView.text = commerceEventCustomMetadata.description
                } else {
                    commerceEventCustomMetadataTextView.text = ""
                }
            }
        }
    }
    
    @IBAction func unwindLinkPropertiesTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? LinkPropertiesTableViewController {
            DataStore.setLinkProperties(vc.linkProperties)
        }
    }
    
    @IBAction func unwindBranchUniversalObjectTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? BranchUniversalObjectPropertiesTableViewController {
            DataStore.setUniversalObject(vc.universalObject)
        }
    }
    
    @IBAction func unwindCommerceEventDetailsTableViewController(_ segue:UIStoryboardSegue) {}
    
    func refreshControlValues() {
        // First load the three values required to refresh the rewards balance
        userIDTextField.text = DataStore.getUserID()
        rewardsBucketTextField.text = DataStore.getRewardsBucket()
        rewardsBalanceOfBucketTextField.text = DataStore.getRewardsBalanceOfBucket()
        
        // Then initiate a refresh of the rewards balance
        refreshRewardsBalanceOfBucket()
        
        // Now get about populating the other controls
        rewardPointsToRedeemTextField.text = DataStore.getRewardPointsToRedeem()
        customEventNameTextField.text = DataStore.getCustomEventName()
        customEventMetadata = DataStore.getCustomEventMetadata()
        if (customEventMetadata.count > 0) {
            customEventMetadataTextView.text = customEventMetadata.description
        } else {
            customEventMetadataTextView.text = ""
        }
        commerceEventCustomMetadata = DataStore.getCommerceEventCustomMetadata()
        if (commerceEventCustomMetadata.count > 0) {
            commerceEventCustomMetadataTextView.text = commerceEventCustomMetadata.description
        } else {
            commerceEventCustomMetadataTextView.text = ""
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

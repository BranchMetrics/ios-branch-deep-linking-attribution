//
//  HomeViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
// TODO: rearrange Branch Link section layout
// TODO: fix wording when latestRereferringParams are shown
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

class HomeViewController: UITableViewController, BranchShareLinkDelegate {
    
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var userIDTextField: UITextField!
    
    @IBOutlet weak var linkTextField: UITextField!
    
    @IBOutlet weak var createBranchLinkButton: UIButton!
    @IBOutlet weak var shareBranchLinkButton: UIButton!
    @IBOutlet weak var linkPropertiesLabel: UILabel!
    @IBOutlet weak var branchUniversalObjectsLabel: UILabel!
    @IBOutlet weak var ApplicationEventsLabel: UILabel!
    @IBOutlet weak var CommerceEventsLabel: UILabel!
    @IBOutlet weak var ReferralRewardsLabel: UILabel!
    @IBOutlet weak var LatestReferringParamsLabel: UILabel!
    @IBOutlet weak var FirstReferringParamsLabel: UILabel!
    @IBOutlet weak var TestBedStartupOptionsLabel: UILabel!
    @IBOutlet weak var ThirdpartySDKIntegrationsLabel: UILabel!
    
    var _dateFormatter: DateFormatter?
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
    
    @objc func applicationDidBecomeActive() {
        refreshEnabledButtons()
    }
    
    @objc func refreshEnabledButtons() {
        var enableButtons = false
        
        if let clickedBranchLink = Branch.getInstance().getLatestReferringParams()["+clicked_branch_link"] as! Bool? {
            enableButtons = clickedBranchLink
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
            self.performSegue(withIdentifier: "HomeViewToTextViewFormTableView", sender: "userID")
        case (1,0) :
            guard linkTextField.text?.characters.count > 0 else {
                break
            }
            UIPasteboard.general.string = linkTextField.text
            showAlert("Link copied to clipboard", withDescription: linkTextField.text!)
        case (1,3) :
            self.performSegue(withIdentifier: "HomeTableViewToLinkPropertiesTableView", sender: "LinkProperties")
        case (1,4) :
            self.performSegue(withIdentifier: "HomeTableViewToBranchUniversalObjectsTableView", sender: "BranchUniversalObjects")
        case (2,0) :
            self.performSegue(withIdentifier: "HomeTableViewToCustomEventTableView", sender: "CustomEvents")
        case (2,1) :
            self.performSegue(withIdentifier: "HomeTableViewToCommerceEventTableView", sender: "CommerceEvents")
        case (2,2) :
            self.performSegue(withIdentifier: "HomeTableViewToReferralRewardsTableView", sender: "ReferralRewards")
        case (3,0) :
            if let params = Branch.getInstance().getLatestReferringParams() {
                let content = String(format:"LatestReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "HomeTableViewToContentView", sender: "LatestReferringParams")
                print("Branch TestBed: LatestReferringParams:\n", content)
            }
        case (3,1) :
            if let params = Branch.getInstance().getFirstReferringParams() {
                let content = String(format:"FirstReferringParams:\n\n%@", (params.JSONDescription()))
                self.performSegue(withIdentifier: "HomeTableViewToContentView", sender: "FirstReferringParams")
                print("Branch TestBed: FirstReferringParams:\n", content)
            }
        case (4,0) :
            self.performSegue(withIdentifier: "HomeTableViewToStartupOptionsTableView", sender: "TestBedStartupOptions")
        case (4,1) :
            self.performSegue(withIdentifier: "HomeTableViewToIntegratedSDKsTableView", sender: "IntegratedSDKs")
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
        shareBranchObject.contentMetadata.customMetadata["publicSlug"] = canonicalIdentifier;
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
        shareBranchObject.contentMetadata.customMetadata["publicSlug"] = canonicalIdentifier
        
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
        shareBranchObject.canonicalIdentifier = "Share-Link-Example-ID"
        shareBranchObject.canonicalUrl = "https://developer.branch.io/"
        shareBranchObject.imageUrl = "https://branch.io/img/press/kit/badge-black.png"
        shareBranchObject.keywords = [ "example", "short", "share", "link" ]
        shareBranchObject.contentDescription = "This is an example shared alias link."

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
    
    @IBAction func createBranchLinkButtonTouchUpInside(_ sender: AnyObject) {
        
        let branchLinkProperties = LinkPropertiesData.getBranchLinkProperties()
        let branchUniversalObject = BranchUniversalObjectsData.getBranchUniversalObject()
        
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
    @IBAction func shareBranchLinkButtonTouchUpInside(_ sender: Any) {
    }
    
    func textFieldDidChange(_ sender:UITextField) {
        sender.resignFirstResponder()
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
            vc.linkProperties = LinkPropertiesData.getLinkProperties()
        case "BranchUniversalObjects":
            let vc = (segue.destination as! BranchUniversalObjectPropertiesTableViewController)
            vc.universalObject = BranchUniversalObjectsData.getUniversalObject()
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
                                HomeData.setUserID(userID)
                                
                                // Amplitude
                                if IntegratedSDKsData.activeAmplitudeEnabled()! {
                                    Amplitude.instance().setUserId(userID)
                                    branch?.setRequestMetadataKey("$amplitude_user_id",
                                                                 value: userID as NSObject)
                                }
                                
                                // Mixpanel
                                if IntegratedSDKsData.activeMixpanelEnabled()! {
                                    Mixpanel.sharedInstance()?.identify(userID)
                                    branch?.setRequestMetadataKey("$mixpanel_distinct_id",
                                                                  value: userID as NSObject)
                                }
                                
                            }
                        }
                        return
                    }
                    
                    branch?.setIdentity(userID) { (params, error) in
                        if (error == nil) {
                            print(String(format: "Branch TestBed: Identity set: %@", userID))
                            self.userIDTextField.text = userID
                            HomeData.setUserID(userID)
                            
//                            let defaultContainer = UserDefaults.standard
//                            defaultContainer.setValue(userID, forKey: "userID")
                            
                            // Amplitude
                            if IntegratedSDKsData.activeMixpanelEnabled()! {
                                Amplitude.instance().setUserId(userID)
                                branch?.setRequestMetadataKey("$amplitude_user_id",
                                                              value: userID as NSObject)
                            }
                            
                            // Mixpanel
                            if IntegratedSDKsData.activeMixpanelEnabled()! {
                                Mixpanel.sharedInstance()?.identify(userID)
                                branch?.setRequestMetadataKey("$mixpanel_distinct_id",
                                                              value: userID as NSObject)
                            }
                            
                        } else {
                            print(String(format: "Branch TestBed: Error setting identity: %@", error! as CVarArg))
                            self.showAlert("Unable to Set Identity", withDescription:error!.localizedDescription)
                        }
                    }
                    
                }
            default: break
            }
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindLinkPropertiesTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? LinkPropertiesTableViewController {
            LinkPropertiesData.setLinkProperties(vc.linkProperties)
        }
    }
    
    @IBAction func unwindBranchUniversalObjectTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? BranchUniversalObjectPropertiesTableViewController {
            BranchUniversalObjectsData.setUniversalObject(vc.universalObject)
        }
    }
    
    @IBAction func unwindCommerceEventsTableViewController(_ segue:UIStoryboardSegue) {
        print("unwindCommerceEvents!")
    }
    
    @IBAction func unwindStartupOptionsTableViewController(_ segue:UIStoryboardSegue) {
        print("unwindStartupOptions!")
    }
    
    @IBAction func unwindIntegratedSDKsTableViewController(_ segue:UIStoryboardSegue) {
        print("unwindIntegratedSDKs!")
    }
    
    func refreshControlValues() {
        userIDTextField.text = HomeData.getUserID()
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func sendPurchaseEvent(_ sender: AnyObject) {
        let universalObject = BranchUniversalObject.init()
        universalObject.title = "Big Bad Dog"
        universalObject.contentDescription = "This dog is big. And bad. Bad dog."
        universalObject.keywords = [ "big", "bad", "dog" ]
        universalObject.contentMetadata.contentSchema = BranchContentSchema.commerceProduct
        universalObject.contentMetadata.price = 10.00
        universalObject.contentMetadata.currency = BNCCurrencyUSD
        universalObject.contentMetadata.productCondition = BranchProductCondition.poor

        let event = BranchEvent.standardEvent(
            BranchStandardEvent.viewItem,
            withContentItem: universalObject
        )

        event.revenue = 10.00;
        event.currency = BNCCurrencyUSD
        event.contentItems = [ universalObject ]
        event.customData = [ "DiggityDog": "Hot" ]
        event.customData["snoop"] = "dog"
        BranchEvent.standardEvent(BranchStandardEvent.purchase,
            withContentItem: universalObject).logEvent()
    }
}

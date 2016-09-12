//
//  LinkPropertiesTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class LinkPropertiesTableViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: - Controls
    
    @IBOutlet weak var clearAllValuesButton: UIButton!
    @IBOutlet weak var channelTextField: UITextField!
    @IBOutlet weak var featureTextField: UITextField!
    @IBOutlet weak var campaignTextField: UITextField!
    @IBOutlet weak var stageTextField: UITextField!
    @IBOutlet weak var tagsTextView: UITextView!
    @IBOutlet weak var aliasTextField: UITextField!
    @IBOutlet weak var fallbackURLTextField: UITextField!
    @IBOutlet weak var desktopURLTextField: UITextField!
    @IBOutlet weak var iosURLTextField: UITextField!
    @IBOutlet weak var ipadURLTextField: UITextField!
    @IBOutlet weak var androidURLTextField: UITextField!
    @IBOutlet weak var windowsPhoneURLTextField: UITextField!
    @IBOutlet weak var blackberryURLTextField: UITextField!
    @IBOutlet weak var fireURLTextField: UITextField!
    @IBOutlet weak var iosWeChatURLTextField: UITextField!
    @IBOutlet weak var iosWeiboURLTextField: UITextField!
    @IBOutlet weak var afterClickURLTextField: UITextField!
    @IBOutlet weak var webOnlySwitch: UISwitch!
    @IBOutlet weak var deeplinkPathTextField: UITextField!
    @IBOutlet weak var androidDeeplinkPathTextField: UITextField!
    @IBOutlet weak var iosDeeplinkPathTextField: UITextField!
    @IBOutlet weak var matchDurationTextField: UITextField!
    @IBOutlet weak var alwaysDeeplinkSwitch: UISwitch!
    @IBOutlet weak var iosRedirectTimeoutTextField: UITextField!
    @IBOutlet weak var androidRedirectTimeoutTextField: UITextField!
    @IBOutlet weak var oneTimeUseSwitch: UISwitch!
    @IBOutlet weak var iosDeepviewTextField: UITextField!
    @IBOutlet weak var androidDeepviewTextField: UITextField!
    @IBOutlet weak var desktopDeepviewTextField: UITextField!
    
    var linkProperties = [String: AnyObject]()
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        channelTextField.delegate = self
        featureTextField.delegate = self
        campaignTextField.delegate = self
        stageTextField.delegate = self
        aliasTextField.delegate = self
        fallbackURLTextField.delegate = self
        desktopURLTextField.delegate = self
        iosURLTextField.delegate = self
        ipadURLTextField.delegate = self
        androidURLTextField.delegate = self
        windowsPhoneURLTextField.delegate = self
        blackberryURLTextField.delegate = self
        fireURLTextField.delegate = self
        iosWeChatURLTextField.delegate = self
        iosWeiboURLTextField.delegate = self
        afterClickURLTextField.delegate = self
        deeplinkPathTextField.delegate = self
        androidDeeplinkPathTextField.delegate = self
        iosDeeplinkPathTextField.delegate = self
        matchDurationTextField.delegate = self
        iosRedirectTimeoutTextField.delegate = self
        androidRedirectTimeoutTextField.delegate = self
        iosDeepviewTextField.delegate = self
        androidDeepviewTextField.delegate = self
        desktopDeepviewTextField.delegate = self
        
        UITableViewCell.appearance().backgroundColor = UIColor.whiteColor()
        refreshControls()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Navigation
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func clearAllValuesTouchUpInside(sender: AnyObject) {
        linkProperties.removeAll()
        refreshControls()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch(indexPath.section) {
            case 5 :
                self.performSegueWithIdentifier("ShowTags", sender: "Tags")
            default : break
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        refreshLinkProperties()
        
        if segue.identifier! == "ShowTags" {
            let vc = segue.destinationViewController as! ArrayTableViewController
            if let tags = linkProperties["tags"] as? [String] {
                vc.array = tags
            }
            vc.viewTitle = "Link Tags"
            vc.header = "Tag"
            vc.placeholder = "tag"
            vc.footer = "Enter a new tag to associate with the link."
            vc.keyboardType = UIKeyboardType.Default
        }
    }
    
    @IBAction func unwindByCancelling(segue:UIStoryboardSegue) { }
    
    @IBAction func unwindArrayTableViewController(segue:UIStoryboardSegue) {
        if let vc = segue.sourceViewController as? ArrayTableViewController {
            let tags = vc.array
            linkProperties["~tags"] = tags
            if tags.count > 0 {
                tagsTextView.text = tags.description
            } else {
                tagsTextView.text = ""
            }
        }
    }
    
    // MARK: - Refresh Functions
    
    func refreshControls() {
        channelTextField.text = linkProperties["~channel"] as? String
        featureTextField.text = linkProperties["~feature"] as? String
        campaignTextField.text = linkProperties["~campaign"] as? String
        stageTextField.text = linkProperties["~stage"] as? String
        
        if let tags = linkProperties["~tags"] as? [String] {
            if tags.count > 0 {
                tagsTextView.text = tags.description
            } else {
                tagsTextView.text = ""
            }
        } else {
            tagsTextView.text = ""
        }
        
        aliasTextField.text = linkProperties["alias"] as? String
        fallbackURLTextField.text = linkProperties["$fallback_url"] as? String
        desktopURLTextField.text = linkProperties["$desktop_url"] as? String
        iosURLTextField.text = linkProperties["$ios_url"] as? String
        ipadURLTextField.text = linkProperties["$ipad_url"] as? String
        androidURLTextField.text = linkProperties["$android_url"] as? String
        windowsPhoneURLTextField.text = linkProperties["$windows_phone_url"] as? String
        blackberryURLTextField.text = linkProperties["$blackberry_url"] as? String
        fireURLTextField.text = linkProperties["$fire_url"] as? String
        iosWeChatURLTextField.text = linkProperties["$ios_wechat_url"] as? String
        iosWeiboURLTextField.text = linkProperties["$ios_weibo_url"] as? String
        afterClickURLTextField.text = linkProperties["$after_click_url"] as? String
        
        webOnlySwitch.on = false
        if let webOnly = linkProperties["$web_only"] as? String {
            if webOnly == "1" {
                webOnlySwitch.on = true
            } else {
                webOnlySwitch.on = false
            }
        }
        
        deeplinkPathTextField.text = linkProperties["$deeplink_path"] as? String
        androidDeeplinkPathTextField.text = linkProperties["$android_deeplink_path"] as? String
        iosDeeplinkPathTextField.text = linkProperties["$ios_deeplink_path"] as? String
        matchDurationTextField.text = linkProperties["$match_duration"] as? String
        
        alwaysDeeplinkSwitch.on = false
        if let alwaysDeeplink = linkProperties["$always_deeplink"] as? String {
            if alwaysDeeplink == "1" {
                alwaysDeeplinkSwitch.on = true
            } else {
                alwaysDeeplinkSwitch.on = false
            }
        }
        
        iosRedirectTimeoutTextField.text = linkProperties["$ios_redirect_timeout"] as? String
        androidRedirectTimeoutTextField.text = linkProperties["$android_redirect_timeout"] as? String
        
        oneTimeUseSwitch.on = false
        if let oneTimeUse = linkProperties["$one_time_use"] as? String {
            if oneTimeUse == "1" {
                oneTimeUseSwitch.on = true
            } else {
                oneTimeUseSwitch.on = false
            }
        }
        
        iosDeepviewTextField.text = linkProperties["$ios_deepview"] as? String
        androidDeepviewTextField.text = linkProperties["$android_deepview"] as? String
        desktopDeepviewTextField.text = linkProperties["$desktop_deepview"] as? String
        
    }
    
    func refreshLinkProperties() {
        addProperty("~channel", value: channelTextField.text!)
        addProperty("~feature", value: featureTextField.text!)
        addProperty("~campaign", value: campaignTextField.text!)
        addProperty("~stage", value: stageTextField.text!)
        addProperty("alias", value: aliasTextField.text!)
        addProperty("$fallback_url", value: fallbackURLTextField.text!)
        addProperty("$desktop_url", value: desktopURLTextField.text!)
        addProperty("$ios_url", value: iosURLTextField.text!)
        addProperty("$ipad_url", value: ipadURLTextField.text!)
        addProperty("$android_url", value: androidURLTextField.text!)
        addProperty("$windows_phone_url", value: windowsPhoneURLTextField.text!)
        addProperty("$blackberry_url", value: blackberryURLTextField.text!)
        addProperty("$fire_url", value: fireURLTextField.text!)
        addProperty("$ios_wechat_url", value: iosWeChatURLTextField.text!)
        addProperty("$ios_weibo_url", value: iosWeiboURLTextField.text!)
        addProperty("$after_click_url", value: afterClickURLTextField.text!)

        if webOnlySwitch.on {
            linkProperties["$web_only"] = "1"
        } else {
            linkProperties.removeValueForKey("$web_only")
        }
        
        addProperty("$deeplink_path", value: deeplinkPathTextField.text!)
        addProperty("$android_deeplink_path", value: androidDeeplinkPathTextField.text!)
        addProperty("$ios_deeplink_path", value: iosDeeplinkPathTextField.text!)
        addProperty("$match_duration", value: matchDurationTextField.text!)
        
        if alwaysDeeplinkSwitch.on {
            linkProperties["$always_deeplink"] = "1"
        } else {
            linkProperties.removeValueForKey("$always_deeplink")
        }
        
        addProperty("$ios_redirect_timeout", value: iosRedirectTimeoutTextField.text!)
        addProperty("$android_redirect_timeout", value: androidRedirectTimeoutTextField.text!)
        
        if oneTimeUseSwitch.on {
            linkProperties["$one_time_use"] = "1"
        } else {
            linkProperties.removeValueForKey("$one_time_use")
        }
        
        addProperty("$ios_deepview", value: iosDeepviewTextField.text!)
        addProperty("$android_deepview", value: androidDeepviewTextField.text!)
        addProperty("$desktop_deepview", value: desktopDeepviewTextField.text!)
    }
    
    func addProperty(key: String, value: String) {
        guard value.characters.count > 0 else {
            linkProperties.removeValueForKey(key)
            return
        }
        linkProperties[key] = value
    }
    
}

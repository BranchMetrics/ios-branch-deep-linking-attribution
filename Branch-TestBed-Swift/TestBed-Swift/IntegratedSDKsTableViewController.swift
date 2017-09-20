//
//  IntegratedSDKsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class IntegratedSDKsTableViewController: UITableViewController {
    
    @IBOutlet weak var activeAdjustKeyTextField: UITextField!
    @IBOutlet weak var activeAdjustEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAdobeKeyTextField: UITextField!
    @IBOutlet weak var activeAdobeEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAmplitudeKeyTextField: UITextField!
    @IBOutlet weak var activeAmplitudeEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAppsflyerKeyTextField: UITextField!
    @IBOutlet weak var activeAppsflyerEnabledSwitch: UISwitch!
    @IBOutlet weak var activeGoogleAnalyticsKeyTextField: UITextField!
    @IBOutlet weak var activeGoogleAnalyticsEnabledSwitch: UISwitch!
    @IBOutlet weak var activeMixpanelKeyTextField: UITextField!
    @IBOutlet weak var activeMixpanelEnabledSwitch: UISwitch!
    @IBOutlet weak var activeTuneAdvertisingIDTextField: UITextField!
    @IBOutlet weak var activeTuneConversionKeyTextField: UITextField!
    @IBOutlet weak var activeTuneEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAdjustKeyTextField: UITextField!
    @IBOutlet weak var pendingAdjustEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAdobeKeyTextField: UITextField!
    @IBOutlet weak var pendingAdobeEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAmplitudeKeyTextField: UITextField!
    @IBOutlet weak var pendingAmplitudeEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAppsflyerKeyTextField: UITextField!
    @IBOutlet weak var pendingAppsflyerEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingGoogleAnalyticsKeyTextField: UITextField!
    @IBOutlet weak var pendingGoogleAnalyticsEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingMixpanelKeyTextField: UITextField!
    @IBOutlet weak var pendingMixpanelEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingTuneAdvertisingIDTextField: UITextField!
    @IBOutlet weak var pendingTuneConversionKeyTextField: UITextField!
    @IBOutlet weak var pendingTuneEnabledSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControlValues()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (1,0) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingAdjustKey")
        case (1,2) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingAdobeKey")
        case (1,4) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingAmplitudeKey")
        case (1,6) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingAppsflyerKey")
        case (1,8) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingGoogleAnalyticsKey")
        case (1,10) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingMixpanelKey")
        case (1,12) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingTuneAdvertisingID")
        case (1,13) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingTuneConversionKey")
        default : break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let senderString = sender as? String {
            switch senderString {
            case "pendingAdjustKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Adjust Key"
                vc.header = "Adjust Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingAdjustKey()!
            case "pendingAdobeKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Adobe Key"
                vc.header = "Adobe Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingAdobeKey()!
            case "pendingAmplitudeKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Amplitude Key"
                vc.header = "Amplitude Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingAmplitudeKey()!
            case "pendingAppsflyerKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Appsflyer Key"
                vc.header = "Appsflyer Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingAppsflyerKey()!
            case "pendingGoogleAnalyticsKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Google Analytics Key"
                vc.header = "Google Analyitcs Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingGoogleAnalyticsKey()!
            case "pendingMixpanelKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Mixpanel Key"
                vc.header = "Mixpanel Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingMixpanelKey()!
            case "pendingTuneAdvertisingID":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Tune Advertising ID"
                vc.header = "Tune Advertising ID"
                vc.footer = "This Advertising ID will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingTuneAdvertisingID()!
            case "pendingTuneConversionKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Tune Conversion Key"
                vc.header = "Tune Convsrsion Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingTuneConversionKey()!
            default:
                break
            }
        }

    }
    
    @IBAction func unwindTextViewFormTableViewController(_ segue:UIStoryboardSegue) {
        
        if let vc = segue.source as? TextViewFormTableViewController {
            
            switch vc.sender {
            case "pendingAdjustKey":
                if let pendingAdjustKey = vc.textView.text {
                    guard self.pendingAdjustKeyTextField.text != pendingAdjustKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingAdjustKey(pendingAdjustKey)
                    self.pendingAdjustKeyTextField.text = pendingAdjustKey
                }
            case "pendingAdobeKey":
                if let pendingAdobeKey = vc.textView.text {
                    guard self.pendingAdobeKeyTextField.text != pendingAdobeKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingAdobeKey(pendingAdobeKey)
                    self.pendingAdobeKeyTextField.text = pendingAdobeKey
                }
            case "pendingAmplitudeKey":
                if let pendingAmplitudeKey = vc.textView.text {
                    guard self.pendingAmplitudeKeyTextField.text != pendingAmplitudeKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingAmplitudeKey(pendingAmplitudeKey)
                    self.pendingAmplitudeKeyTextField.text = pendingAmplitudeKey
                }
            case "pendingAppsflyerKey":
                if let pendingAppsflyerKey = vc.textView.text {
                    guard self.pendingAppsflyerKeyTextField.text != pendingAppsflyerKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingAppsflyerKey(pendingAppsflyerKey)
                    self.pendingAppsflyerKeyTextField.text = pendingAppsflyerKey
                }
            case "pendingGoogleAnalyticsKey":
                if let pendingGoogleAnalyticsKey = vc.textView.text {
                    guard self.pendingGoogleAnalyticsKeyTextField.text != pendingGoogleAnalyticsKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingGoogleAnalyticsKey(pendingGoogleAnalyticsKey)
                    self.pendingGoogleAnalyticsKeyTextField.text = pendingGoogleAnalyticsKey
                }
            case "pendingMixpanelKey":
                if let pendingMixpanelKey = vc.textView.text {
                    guard self.pendingMixpanelKeyTextField.text != pendingMixpanelKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingMixpanelKey(pendingMixpanelKey)
                    self.pendingMixpanelKeyTextField.text = pendingMixpanelKey
                }
            case "pendingTuneAdvertisingID":
                if let pendingTuneAdvertisingID = vc.textView.text {
                    guard self.pendingTuneAdvertisingIDTextField.text != pendingTuneAdvertisingID else {
                        return
                    }
                    IntegratedSDKsData.setPendingTuneAdvertisingID(pendingTuneAdvertisingID)
                    self.pendingTuneAdvertisingIDTextField.text = pendingTuneAdvertisingID
                }
            case "pendingTuneConversionKey":
                if let pendingTuneConversionKey = vc.textView.text {
                    guard self.pendingTuneConversionKeyTextField.text != pendingTuneConversionKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingTuneConversionKey(pendingTuneConversionKey)
                    self.pendingTuneConversionKeyTextField.text = pendingTuneConversionKey
                }
            default: break
            }
        }
    }
    
    @IBAction func pendingAdjustEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingAdjustEnabled(self.pendingAdjustEnabledSwitch.isOn)
    }
    
    @IBAction func pendingAdobeEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingAdobeEnabled(self.pendingAdobeEnabledSwitch.isOn)
    }
    
    @IBAction func pendingAmplitudeEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingAmplitudeEnabled(self.pendingAmplitudeEnabledSwitch.isOn)
    }
    
    @IBAction func pendingAppsflyerEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingAppsflyerEnabled(self.pendingAppsflyerEnabledSwitch.isOn)
    }
    
    @IBAction func pendingGoogleAnalyticsEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingGoogleAnalyticsEnabled(self.pendingGoogleAnalyticsEnabledSwitch.isOn)
    }
    
    @IBAction func pendingMixpanelEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingMixpanelEnabled(self.pendingMixpanelEnabledSwitch.isOn)
    }
    
    @IBAction func pendingTuneEnabledSwitchValueChanged(_ sender: Any) {
        IntegratedSDKsData.setPendingTuneEnabled(self.pendingTuneEnabledSwitch.isOn)
    }
    
    func refreshControlValues() {
        activeAdjustKeyTextField.text = IntegratedSDKsData.activeAdjustKey()
        activeAdjustEnabledSwitch.isOn = IntegratedSDKsData.activeAdjustEnabled()!
        activeAdobeKeyTextField.text = IntegratedSDKsData.activeAdobeKey()
        activeAdobeEnabledSwitch.isOn = IntegratedSDKsData.activeAdobeEnabled()!
        activeAmplitudeKeyTextField.text = IntegratedSDKsData.activeAmplitudeKey()
        activeAmplitudeEnabledSwitch.isOn = IntegratedSDKsData.activeAmplitudeEnabled()!
        activeAppsflyerKeyTextField.text = IntegratedSDKsData.activeAppsflyerKey()
        activeAppsflyerEnabledSwitch.isOn = IntegratedSDKsData.activeAppsflyerEnabled()!
        activeGoogleAnalyticsKeyTextField.text = IntegratedSDKsData.activeGoogleAnalyticsKey()
        activeGoogleAnalyticsEnabledSwitch.isOn = IntegratedSDKsData.activeGoogleAnalyticsEnabled()!
        activeMixpanelKeyTextField.text = IntegratedSDKsData.activeMixpanelKey()
        activeMixpanelEnabledSwitch.isOn = IntegratedSDKsData.activeMixpanelEnabled()!
        activeTuneAdvertisingIDTextField.text = IntegratedSDKsData.activeTuneAdvertisingID()
        activeTuneConversionKeyTextField.text = IntegratedSDKsData.activeTuneConversionKey()
        activeTuneEnabledSwitch.isOn = IntegratedSDKsData.activeTuneEnabled()!
        pendingAdjustKeyTextField.text = IntegratedSDKsData.pendingAdjustKey()
        pendingAdjustEnabledSwitch.isOn = IntegratedSDKsData.pendingAdjustEnabled()!
        pendingAdobeKeyTextField.text = IntegratedSDKsData.pendingAdobeKey()
        pendingAdobeEnabledSwitch.isOn = IntegratedSDKsData.pendingAdobeEnabled()!
        pendingAmplitudeKeyTextField.text = IntegratedSDKsData.pendingAmplitudeKey()
        pendingAmplitudeEnabledSwitch.isOn = IntegratedSDKsData.pendingAmplitudeEnabled()!
        pendingAppsflyerKeyTextField.text = IntegratedSDKsData.pendingAppsflyerKey()
        pendingAppsflyerEnabledSwitch.isOn = IntegratedSDKsData.pendingAppsflyerEnabled()!
        pendingGoogleAnalyticsKeyTextField.text = IntegratedSDKsData.pendingGoogleAnalyticsKey()
        pendingGoogleAnalyticsEnabledSwitch.isOn = IntegratedSDKsData.pendingGoogleAnalyticsEnabled()!
        pendingMixpanelKeyTextField.text = IntegratedSDKsData.pendingMixpanelKey()
        pendingMixpanelEnabledSwitch.isOn = IntegratedSDKsData.pendingMixpanelEnabled()!
        pendingTuneAdvertisingIDTextField.text = IntegratedSDKsData.pendingTuneAdvertisingID()
        pendingTuneConversionKeyTextField.text = IntegratedSDKsData.pendingTuneConversionKey()
        pendingTuneEnabledSwitch.isOn = IntegratedSDKsData.pendingTuneEnabled()!
    }

}

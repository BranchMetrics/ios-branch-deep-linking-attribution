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
    @IBOutlet weak var activeMixpanelKeyTextField: UITextField!
    @IBOutlet weak var activeMixpanelEnabledSwitch: UISwitch!
    @IBOutlet weak var activeTuneKeyTextField: UITextField!
    @IBOutlet weak var activeTuneEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAdjustKeyTextField: UITextField!
    @IBOutlet weak var pendingAdjustEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAdobeKeyTextField: UITextField!
    @IBOutlet weak var pendingAdobeEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAmplitudeKeyTextField: UITextField!
    @IBOutlet weak var pendingAmplitudeEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingAppsflyerKeyTextField: UITextField!
    @IBOutlet weak var pendingAppsflyerEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingMixpanelKeyTextField: UITextField!
    @IBOutlet weak var pendingMixpanelEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingTuneKeyTextField: UITextField!
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
                              sender: "pendingMixpanelKey")
        case (1,10) :
            self.performSegue(withIdentifier: "IntegratedSDKsToTextViewForm",
                              sender: "pendingTuneKey")
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
            case "pendingMixpanelKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Mixpanel Key"
                vc.header = "Mixpanel Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingMixpanelKey()!
            case "pendingTuneKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Tune Key"
                vc.header = "Tune Key"
                vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = IntegratedSDKsData.pendingTuneKey()!
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
            case "pendingMixpanelKey":
                if let pendingMixpanelKey = vc.textView.text {
                    guard self.pendingMixpanelKeyTextField.text != pendingMixpanelKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingMixpanelKey(pendingMixpanelKey)
                    self.pendingMixpanelKeyTextField.text = pendingMixpanelKey
                }
            case "pendingTuneKey":
                if let pendingTuneKey = vc.textView.text {
                    guard self.pendingTuneKeyTextField.text != pendingTuneKey else {
                        return
                    }
                    IntegratedSDKsData.setPendingTuneKey(pendingTuneKey)
                    self.pendingTuneKeyTextField.text = pendingTuneKey
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
        activeMixpanelKeyTextField.text = IntegratedSDKsData.activeMixpanelKey()
        activeMixpanelEnabledSwitch.isOn = IntegratedSDKsData.activeMixpanelEnabled()!
        activeTuneKeyTextField.text = IntegratedSDKsData.activeTuneKey()
        activeTuneEnabledSwitch.isOn = IntegratedSDKsData.activeTuneEnabled()!
        pendingAdjustKeyTextField.text = IntegratedSDKsData.pendingAdjustKey()
        pendingAdjustEnabledSwitch.isOn = IntegratedSDKsData.pendingAdjustEnabled()!
        pendingAdobeKeyTextField.text = IntegratedSDKsData.pendingAdobeKey()
        pendingAdobeEnabledSwitch.isOn = IntegratedSDKsData.pendingAdobeEnabled()!
        pendingAmplitudeKeyTextField.text = IntegratedSDKsData.pendingAmplitudeKey()
        pendingAmplitudeEnabledSwitch.isOn = IntegratedSDKsData.pendingAmplitudeEnabled()!
        pendingAppsflyerKeyTextField.text = IntegratedSDKsData.pendingAppsflyerKey()
        pendingAppsflyerEnabledSwitch.isOn = IntegratedSDKsData.pendingAppsflyerEnabled()!
        pendingMixpanelKeyTextField.text = IntegratedSDKsData.pendingMixpanelKey()
        pendingMixpanelEnabledSwitch.isOn = IntegratedSDKsData.pendingMixpanelEnabled()!
        pendingTuneKeyTextField.text = IntegratedSDKsData.pendingTuneKey()
        pendingTuneEnabledSwitch.isOn = IntegratedSDKsData.pendingTuneEnabled()!
    }

}

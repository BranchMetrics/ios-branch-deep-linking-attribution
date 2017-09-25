//
//  IntegratedSDKsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class IntegratedSDKsTableViewController: UITableViewController {
    
    
    @IBOutlet weak var activeAdjustEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAdobeEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAmplitudeEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAppsflyerEnabledSwitch: UISwitch!
    @IBOutlet weak var activeGoogleAnalyticsEnabledSwitch: UISwitch!
    @IBOutlet weak var activeMixpanelEnabledSwitch: UISwitch!
    @IBOutlet weak var activeTuneEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAppboyEnabledSwitch: UISwitch!
    @IBOutlet weak var activeAppMetricaEnabledSwitch: UISwitch!
    @IBOutlet weak var activeClearTapEnabledSwitch: UISwitch!
    @IBOutlet weak var activeConvertroEnabledSwitch: UISwitch!
    @IBOutlet weak var activeKochavaEnabledSwitch: UISwitch!
    @IBOutlet weak var activeLocalyticsEnabledSwitch: UISwitch!
    @IBOutlet weak var activemParticleEnabledSwitch: UISwitch!
    @IBOutlet weak var activeSegmentEnabledSwitch: UISwitch!
    @IBOutlet weak var activeSingularEnabledSwitch: UISwitch!
    @IBOutlet weak var activeStitchEnabledSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControlValues()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).row) {
        case 0 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAdjustEnabled")
        case 1 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAdobeEnabled")
        case 2 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAmplitudeEnabled")
        case 3 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAppsflyerEnabled")
        case 4 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeGoogleAnalyticsEnabled")
        case 5 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeMixpanelEnabled")
        case 6 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeTuneEnabled")
        case 7 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAppboyEnabled")
        case 8 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeAppMetricaEnabled")
        case 9 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeClearTapEnabled")
        case 10 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeConvertroEnabled")
        case 11 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeKochavaEnabled")
        case 12 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeLocalyticsEnabled")
        case 13 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activemParticleEnabled")
        case 14 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeSegmentEnabled")
        case 15 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeSingularEnabled")
        case 16 :
            self.performSegue(withIdentifier: "TableFormView",
                              sender: "activeStitchEnabled")
        default :
            self.performSegue(withIdentifier: "PendingIntegratedSDKs",
                              sender: "IntegratedSDKs")
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let senderString = sender as? String {
            switch senderString {
            case "activeAdjustEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Adjust SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Adjust SDK Settings",
                    "Footer":"These are the currently active Adjust SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAdjustAppToken",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeAdjustAppToken() ?? "",
                            "Placeholder":"Adjust App Token"
                        ],[
                            "Name":"ActiveAdjustEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAdjustEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Adjust SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAdjustAppToken",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingAdjustAppToken() ?? "",
                                "Placeholder":"Adjust App Token",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingAdjustEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAdjustEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeAdobeEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Adobe SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Adobe SDK Settings",
                    "Footer":"These are the currently active Adobe SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAdobeEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAdobeEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Adobe SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAdobeEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAdobeEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeAmplitudeEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Amplitude SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Amplitude SDK Settings",
                    "Footer":"These are the currently active Amplitude SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAmplitudeKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeAmplitudeKey() ?? "",
                            "Placeholder":"Amplitude Key"
                        ],[
                            "Name":"ActiveAmplitudeEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAmplitudeEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Amplitude SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAmplitudeKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingAmplitudeKey() ?? "",
                                "Placeholder":"Amplitude Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingAmplitudeEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAmplitudeEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeAppsflyerEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Appsflyer SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Appsflyer SDK Settings",
                    "Footer":"These are the currently active Appsflyer SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAppsflyerKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeAppsflyerKey() ?? "",
                            "Placeholder":"Appsflyer Key"
                        ],[
                            "Name":"ActiveAppsflyerEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAppsflyerEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Appsflyer SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAppsflyerKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingAppsflyerKey() ?? "",
                                "Placeholder":"Appsflyer Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingAppsflyerEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAppsflyerEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeGoogleAnalyticsEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Google Analytics SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Google Analytics SDK Settings",
                    "Footer":"These are the currently active Google Analytics SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveGoogleAnalyticsTrackingID",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeGoogleAnalyticsTrackingID() ?? "",
                            "Placeholder":"Google Analytics Tracking ID"
                        ],[
                            "Name":"ActiveGoogleAnalyticsEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeGoogleAnalyticsEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Google Analytics SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingGoogleAnalyticsTrackingID",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingGoogleAnalyticsTrackingID() ?? "",
                                "Placeholder":"Google Analytics Tracking ID",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingGoogleAnalyticsEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingGoogleAnalyticsEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeMixpanelEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Mixpanel SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Mixpanel SDK Settings",
                    "Footer":"These are the currently active Mixpanel SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveMixpanelKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeMixpanelKey() ?? "",
                            "Placeholder":"Mixpanel Key"
                        ],[
                            "Name":"ActiveMixpanelEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeMixpanelEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Mixpanel SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingMixpanelKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingMixpanelKey() ?? "",
                                "Placeholder":"Mixpanel Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingMixpanelEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingMixpanelEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeTuneEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Tune SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Tune SDK Settings",
                    "Footer":"These are the currently active Tune SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveTuneAdvertisingID",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeTuneAdvertisingID() ?? "",
                            "Placeholder":"Tune Advertising ID"
                        ],[
                            "Name":"ActiveTuneConversionKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeTuneConversionKey() ?? "",
                            "Placeholder":"Tune Conversion Key"
                        ],[
                            "Name":"ActiveTuneEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeTuneEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Tune SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingTuneAdvertisingID",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingTuneAdvertisingID() ?? "",
                                "Placeholder":"Tune Advertising ID",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingTuneConversionKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingTuneConversionKey() ?? "",
                                "Placeholder":"Tune Conversion Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingTuneEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingTuneEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeAppboyEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Appboy SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Appboy SDK Settings",
                    "Footer":"These are the currently active Appboy SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAppboyAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeAppboyAPIKey() ?? "",
                            "Placeholder":"Appboy API Key"
                        ],[
                            "Name":"ActiveAppboyEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAppboyEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Appboy SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAppboyAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingAppboyAPIKey() ?? "",
                                "Placeholder":"Appboy API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingAppboyEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAppboyEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeAppMetricaEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "AppMetrica SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active AppMetrica SDK Settings",
                    "Footer":"These are the currently active AppMetrica SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveAppMetricaAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeAppMetricaAPIKey() ?? "",
                            "Placeholder":"AppMetrica API Key"
                        ],[
                            "Name":"ActiveAppMetricaEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeAppMetricaEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending AppMetrica SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingAppMetricaAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingAppMetricaAPIKey() ?? "",
                                "Placeholder":"AppMetrica API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingAppMetricaEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingAppMetricaEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeClearTapEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "ClearTap SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active ClearTap SDK Settings",
                    "Footer":"These are the currently active ClearTap SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveClearTapAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeClearTapAPIKey() ?? "",
                            "Placeholder":"ClearTap API Key"
                        ],[
                            "Name":"ActiveClearTapEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeClearTapEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending ClearTap SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingClearTapAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingClearTapAPIKey() ?? "",
                                "Placeholder":"ClearTap API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingClearTapEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingClearTapEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeConvertroEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Convertro SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Convertro SDK Settings",
                    "Footer":"These are the currently active Convertro SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveConvertroAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeConvertroAPIKey() ?? "",
                            "Placeholder":"Convertro API Key"
                        ],[
                            "Name":"ActiveConvertroEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeConvertroEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Convertro SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingConvertroAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingConvertroAPIKey() ?? "",
                                "Placeholder":"Convertro API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingConvertroEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingConvertroEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeKochavaEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Kochava SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Kochava SDK Settings",
                    "Footer":"These are the currently active Kochava SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveKochavaAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeKochavaAPIKey() ?? "",
                            "Placeholder":"Kochava API Key"
                        ],[
                            "Name":"ActiveKochavaEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeKochavaEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Kochava SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingKochavaAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingKochavaAPIKey() ?? "",
                                "Placeholder":"Kochava API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingKochavaEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingKochavaEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeLocalyticsEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Localytics SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Localytics SDK Settings",
                    "Footer":"These are the currently active Localytics SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveLocalyticsAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeLocalyticsAPIKey() ?? "",
                            "Placeholder":"Localytics API Key"
                        ],[
                            "Name":"ActiveLocalyticsEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeLocalyticsEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Localytics SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingLocalyticsAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingLocalyticsAPIKey() ?? "",
                                "Placeholder":"Localytics API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingLocalyticsEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingLocalyticsEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activemParticleEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "mParticle SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active mParticle SDK Settings",
                    "Footer":"These are the currently active mParticle SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActivemParticleAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activemParticleAPIKey() ?? "",
                            "Placeholder":"mParticle API Key"
                        ],[
                            "Name":"ActivemParticleEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activemParticleEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending mParticle SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingmParticleAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingmParticleAPIKey() ?? "",
                                "Placeholder":"mParticle API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingmParticleEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingmParticleEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeSegmentEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Segment SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Segment SDK Settings",
                    "Footer":"These are the currently active Segment SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveSegmentAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeSegmentAPIKey() ?? "",
                            "Placeholder":"Segment API Key"
                        ],[
                            "Name":"ActiveSegmentEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeSegmentEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Segment SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingSegmentAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingSegmentAPIKey() ?? "",
                                "Placeholder":"Segment API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingSegmentEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingSegmentEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeSingularEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Singular SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Singular SDK Settings",
                    "Footer":"These are the currently active Singular SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveSingularAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeSingularAPIKey() ?? "",
                            "Placeholder":"Singular API Key"
                        ],[
                            "Name":"ActiveSingularEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeSingularEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Singular SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingSingularAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingSingularAPIKey() ?? "",
                                "Placeholder":"Singular API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingSingularEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingSingularEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            case "activeStitchEnabled":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TableFormViewController
                vc.sender = senderString
                vc.viewTitle = "Stitch SDK"
                vc.keyboardType = UIKeyboardType.alphabet
                let tableViewSections = [[
                    "Header":"Active Stitch SDK Settings",
                    "Footer":"These are the currently active Stitch SDK settings.",
                    "TableViewCells":[
                        [
                            "Name":"ActiveStitchAPIKey",
                            "CellReuseIdentifier":"TextFieldCell",
                            "Text":IntegratedSDKsData.activeStitchAPIKey() ?? "",
                            "Placeholder":"Stitch API Key"
                        ],[
                            "Name":"ActiveStitchEnabled",
                            "CellReuseIdentifier":"ToggleSwitchCell",
                            "Label":"Enabled",
                            "isEnabled":"false",
                            "isOn": IntegratedSDKsData.activeStitchEnabled()!.description as String
                        ]
                    ]
                    ],[
                        "Header":"Pending Stitch SDK Settings",
                        "Footer":"These settings will be used the next time the application is closed (not merely backgrounded) and re-opened.",
                        "TableViewCells":[
                            [
                                "Name":"PendingStitchAPIKey",
                                "CellReuseIdentifier":"TextFieldCell",
                                "Text":IntegratedSDKsData.pendingStitchAPIKey() ?? "",
                                "Placeholder":"Stitch API Key",
                                "InputForm":"TextViewForm"
                            ],[
                                "Name":"PendingStitchEnabled",
                                "CellReuseIdentifier":"ToggleSwitchCell",
                                "Label":"Enabled",
                                "isEnabled":"true",
                                "isOn":IntegratedSDKsData.pendingStitchEnabled()!.description as String
                            ]
                        ]
                    ]]
                vc.tableViewSections = tableViewSections
            default:
                break
            }
        }
        
    }
    
    @IBAction func unwindTableFormView(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? TableFormViewController {
            // Adjust
            if let pendingAdjustAppToken = vc.returnValues["PendingAdjustAppToken"] {
                IntegratedSDKsData.setPendingAdjustAppToken(pendingAdjustAppToken)
            }
            if let pendingAdjustEnabled = vc.returnValues["PendingAdjustEnabled"] {
                IntegratedSDKsData.setPendingAdjustEnabled(pendingAdjustEnabled == "true")
            }
            // Adobe
            if let pendingAdobeEnabled = vc.returnValues["PendingAdobeEnabled"] {
                IntegratedSDKsData.setPendingAdobeEnabled(pendingAdobeEnabled == "true")
            }
            // Amplitude
            if let pendingAmplitudeKey = vc.returnValues["PendingAmplitudeKey"] {
                IntegratedSDKsData.setPendingAmplitudeKey(pendingAmplitudeKey)
            }
            if let pendingAmplitudeEnabled = vc.returnValues["PendingAmplitudeEnabled"] {
                IntegratedSDKsData.setPendingAmplitudeEnabled(pendingAmplitudeEnabled == "true")
            }
            // Appsflyer
            if let pendingAppsflyerKey = vc.returnValues["PendingAppsflyerKey"] {
                IntegratedSDKsData.setPendingAppsflyerKey(pendingAppsflyerKey)
            }
            if let pendingAppsflyerEnabled = vc.returnValues["PendingAppsflyerEnabled"] {
                IntegratedSDKsData.setPendingAppsflyerEnabled(pendingAppsflyerEnabled == "true")
            }
            // GoogleAnalytics
            if let pendingGoogleAnalyticsTrackingID = vc.returnValues["PendingGoogleAnalyticsTrackingID"] {
                IntegratedSDKsData.setPendingGoogleAnalyticsTrackingID(pendingGoogleAnalyticsTrackingID)
            }
            if let pendingGoogleAnalyticsEnabled = vc.returnValues["PendingGoogleAnalyticsEnabled"] {
                IntegratedSDKsData.setPendingGoogleAnalyticsEnabled(pendingGoogleAnalyticsEnabled == "true")
            }
            // Mixpanel
            if let pendingMixpanelKey = vc.returnValues["PendingMixpanelKey"] {
                IntegratedSDKsData.setPendingMixpanelKey(pendingMixpanelKey)
            }
            if let pendingMixpanelEnabled = vc.returnValues["PendingMixpanelEnabled"] {
                IntegratedSDKsData.setPendingMixpanelEnabled(pendingMixpanelEnabled == "true")
            }
            // Tune
            if let pendingTuneAdvertisingID = vc.returnValues["PendingTuneAdvertisingID"] {
                IntegratedSDKsData.setPendingTuneAdvertisingID(pendingTuneAdvertisingID)
            }
            if let pendingTuneConversionKey = vc.returnValues["PendingTuneConversionKey"] {
                IntegratedSDKsData.setPendingTuneConversionKey(pendingTuneConversionKey)
            }
            if let pendingTuneEnabled = vc.returnValues["PendingTuneEnabled"] {
                IntegratedSDKsData.setPendingTuneEnabled(pendingTuneEnabled == "true")
            }
            // Appboy
            if let pendingAppboyAPIKey = vc.returnValues["PendingAppboyAPIKey"] {
                IntegratedSDKsData.setPendingAppboyAPIKey(pendingAppboyAPIKey)
            }
            if let pendingAppboyEnabled = vc.returnValues["PendingAppboyEnabled"] {
                IntegratedSDKsData.setPendingAppboyEnabled(pendingAppboyEnabled == "true")
            }
            // AppMetrica
            if let pendingAppMetricaAPIKey = vc.returnValues["PendingAppMetricaAPIKey"] {
                IntegratedSDKsData.setPendingAppMetricaAPIKey(pendingAppMetricaAPIKey)
            }
            if let pendingAppMetricaEnabled = vc.returnValues["PendingAppMetricaEnabled"] {
                IntegratedSDKsData.setPendingAppMetricaEnabled(pendingAppMetricaEnabled == "true")
            }
            // ClearTap
            if let pendingClearTapAPIKey = vc.returnValues["PendingClearTapAPIKey"] {
                IntegratedSDKsData.setPendingClearTapAPIKey(pendingClearTapAPIKey)
            }
            if let pendingClearTapEnabled = vc.returnValues["PendingClearTapEnabled"] {
                IntegratedSDKsData.setPendingClearTapEnabled(pendingClearTapEnabled == "true")
            }
            // Convertro
            if let pendingConvertroAPIKey = vc.returnValues["PendingConvertroAPIKey"] {
                IntegratedSDKsData.setPendingConvertroAPIKey(pendingConvertroAPIKey)
            }
            if let pendingConvertroEnabled = vc.returnValues["PendingConvertroEnabled"] {
                IntegratedSDKsData.setPendingConvertroEnabled(pendingConvertroEnabled == "true")
            }
            // Kochava
            if let pendingKochavaAPIKey = vc.returnValues["PendingKochavaAPIKey"] {
                IntegratedSDKsData.setPendingKochavaAPIKey(pendingKochavaAPIKey)
            }
            if let pendingKochavaEnabled = vc.returnValues["PendingKochavaEnabled"] {
                IntegratedSDKsData.setPendingKochavaEnabled(pendingKochavaEnabled == "true")
            }
            // Localytics
            if let pendingLocalyticsAPIKey = vc.returnValues["PendingLocalyticsAPIKey"] {
                IntegratedSDKsData.setPendingLocalyticsAPIKey(pendingLocalyticsAPIKey)
            }
            if let pendingLocalyticsEnabled = vc.returnValues["PendingLocalyticsEnabled"] {
                IntegratedSDKsData.setPendingLocalyticsEnabled(pendingLocalyticsEnabled == "true")
            }
            // mParticle
            if let pendingmParticleAPIKey = vc.returnValues["PendingmParticleAPIKey"] {
                IntegratedSDKsData.setPendingmParticleAPIKey(pendingmParticleAPIKey)
            }
            if let pendingmParticleEnabled = vc.returnValues["PendingmParticleEnabled"] {
                IntegratedSDKsData.setPendingmParticleEnabled(pendingmParticleEnabled == "true")
            }
            // Segment
            if let pendingSegmentAPIKey = vc.returnValues["PendingSegmentAPIKey"] {
                IntegratedSDKsData.setPendingSegmentAPIKey(pendingSegmentAPIKey)
            }
            if let pendingSegmentEnabled = vc.returnValues["PendingSegmentEnabled"] {
                IntegratedSDKsData.setPendingSegmentEnabled(pendingSegmentEnabled == "true")
            }
            // Singular
            if let pendingSingularAPIKey = vc.returnValues["PendingSingularAPIKey"] {
                IntegratedSDKsData.setPendingSingularAPIKey(pendingSingularAPIKey)
            }
            if let pendingSingularEnabled = vc.returnValues["PendingSingularEnabled"] {
                IntegratedSDKsData.setPendingSingularEnabled(pendingSingularEnabled == "true")
            }
            // Stitch
            if let pendingStitchAPIKey = vc.returnValues["PendingStitchAPIKey"] {
                IntegratedSDKsData.setPendingStitchAPIKey(pendingStitchAPIKey)
            }
            if let pendingStitchEnabled = vc.returnValues["PendingStitchEnabled"] {
                IntegratedSDKsData.setPendingStitchEnabled(pendingStitchEnabled == "true")
            }
        }
    }
    
//    @IBAction func unwindAppboySDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindAppMetricaSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindClearTapSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindConvertroSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindKochavaSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindLocalyticsSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindmParticleSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindSegmentSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindSingularSDKStatus(_ segue:UIStoryboardSegue) {}
//    @IBAction func unwindStitchSDKStatus(_ segue:UIStoryboardSegue) {}
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) {}
    
    @IBAction func unwindPendingIntegratedSDKsTableView(_ segue:UIStoryboardSegue) {
        
        //        if let vc = segue.source as? TextViewFormTableViewController {
        //
        //            switch vc.sender {
        //            case "activeAdjustKey":
        //                if let activeAdjustKey = vc.textView.text {
        //                    guard self.activeAdjustKeyTextField.text != activeAdjustKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingAdjustAppToken(activeAdjustKey)
        //                    self.activeAdjustKeyTextField.text = activeAdjustKey
        //                }
        //            case "activeAdobeKey":
        //                if let activeAdobeKey = vc.textView.text {
        //                    guard self.activeAdobeKeyTextField.text != activeAdobeKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingAdobeKey(activeAdobeKey)
        //                    self.activeAdobeKeyTextField.text = activeAdobeKey
        //                }
        //            case "activeAmplitudeKey":
        //                if let activeAmplitudeKey = vc.textView.text {
        //                    guard self.activeAmplitudeKeyTextField.text != activeAmplitudeKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingAmplitudeKey(activeAmplitudeKey)
        //                    self.activeAmplitudeKeyTextField.text = activeAmplitudeKey
        //                }
        //            case "activeAppsflyerKey":
        //                if let activeAppsflyerKey = vc.textView.text {
        //                    guard self.activeAppsflyerKeyTextField.text != activeAppsflyerKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingAppsflyerKey(activeAppsflyerKey)
        //                    self.activeAppsflyerKeyTextField.text = activeAppsflyerKey
        //                }
        //            case "activeGoogleAnalyticsTrackingID":
        //                if let activeGoogleAnalyticsTrackingID = vc.textView.text {
        //                    guard self.activeGoogleAnalyticsTrackingIDTextField.text != activeGoogleAnalyticsTrackingID else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingGoogleAnalyticsTrackingID(activeGoogleAnalyticsTrackingID)
        //                    self.activeGoogleAnalyticsTrackingIDTextField.text = activeGoogleAnalyticsTrackingID
        //                }
        //            case "activeMixpanelKey":
        //                if let activeMixpanelKey = vc.textView.text {
        //                    guard self.activeMixpanelKeyTextField.text != activeMixpanelKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingMixpanelKey(activeMixpanelKey)
        //                    self.activeMixpanelKeyTextField.text = activeMixpanelKey
        //                }
        //            case "activeTuneAdvertisingID":
        //                if let activeTuneAdvertisingID = vc.textView.text {
        //                    guard self.activeTuneAdvertisingIDTextField.text != activeTuneAdvertisingID else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingTuneAdvertisingID(activeTuneAdvertisingID)
        //                    self.activeTuneAdvertisingIDTextField.text = activeTuneAdvertisingID
        //                }
        //            case "activeTuneConversionKey":
        //                if let activeTuneConversionKey = vc.textView.text {
        //                    guard self.activeTuneConversionKeyTextField.text != activeTuneConversionKey else {
        //                        return
        //                    }
        //                    IntegratedSDKsData.setPendingTuneConversionKey(activeTuneConversionKey)
        //                    self.activeTuneConversionKeyTextField.text = activeTuneConversionKey
        //                }
        //            default: break
        //            }
        //        }
    }
    
    func refreshControlValues() {
        
        activeAdjustEnabledSwitch.isOn = IntegratedSDKsData.activeAdjustEnabled()!
        activeAdobeEnabledSwitch.isOn = IntegratedSDKsData.activeAdobeEnabled()!
        activeAmplitudeEnabledSwitch.isOn = IntegratedSDKsData.activeAmplitudeEnabled()!
        activeAppsflyerEnabledSwitch.isOn = IntegratedSDKsData.activeAppsflyerEnabled()!
        activeGoogleAnalyticsEnabledSwitch.isOn = IntegratedSDKsData.activeGoogleAnalyticsEnabled()!
        activeMixpanelEnabledSwitch.isOn = IntegratedSDKsData.activeMixpanelEnabled()!
        activeTuneEnabledSwitch.isOn = IntegratedSDKsData.activeTuneEnabled()!
        activeAppboyEnabledSwitch.isOn = IntegratedSDKsData.activeAppboyEnabled()!
        activeAppMetricaEnabledSwitch.isOn = IntegratedSDKsData.activeAppMetricaEnabled()!
        activeClearTapEnabledSwitch.isOn = IntegratedSDKsData.activeClearTapEnabled()!
        activeConvertroEnabledSwitch.isOn = IntegratedSDKsData.activeConvertroEnabled()!
        activeKochavaEnabledSwitch.isOn = IntegratedSDKsData.activeKochavaEnabled()!
        activeLocalyticsEnabledSwitch.isOn = IntegratedSDKsData.activeLocalyticsEnabled()!
        activemParticleEnabledSwitch.isOn = IntegratedSDKsData.activemParticleEnabled()!
        activeSegmentEnabledSwitch.isOn = IntegratedSDKsData.activeSegmentEnabled()!
        activeSingularEnabledSwitch.isOn = IntegratedSDKsData.activeSingularEnabled()!
        activeStitchEnabledSwitch.isOn = IntegratedSDKsData.activeStitchEnabled()!
    }
    
}

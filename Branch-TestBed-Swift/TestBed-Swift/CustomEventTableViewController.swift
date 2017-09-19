//
//  ApplicationEventsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//
// TODO: Make sure stored values are being retrieved and fed to downstream viewcontrollers

import UIKit

class CustomEventTableViewController: UITableViewController {
    
    @IBOutlet weak var customEventNameTextField: UITextField!
    @IBOutlet weak var customEventMetadataTextView: UITextView!
    
    var customEventMetadata = [String: AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UITableViewCell.appearance().backgroundColor = UIColor.white
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0,0) :
            self.performSegue(withIdentifier: "CustomEventTableViewToTextViewFormNavigationBar", sender: "CustomEventName")
        case (0,1) :
            self.performSegue(withIdentifier: "CustomEventTableViewToDictionaryTableView", sender: "CustomEventMetadata")
        default : break
        }
    }

     // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch sender as! String {
        case "RewardsBucket":
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender as! String
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
            customEventMetadata = CustomEventData.getCustomEventMetadata()
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
        default:
            break
        }
    }
    
    @IBAction func unwindTextViewFormTableViewController(_ segue:UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    
    @IBAction func unwindDictionaryTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? DictionaryTableViewController {
            
            if vc.sender == "CustomEventMetadata" {
                customEventMetadata = vc.dictionary
                CustomEventData.setCustomEventMetadata(customEventMetadata)
                if customEventMetadata.count > 0 {
                    customEventMetadataTextView.text = customEventMetadata.description
                } else {
                    customEventMetadataTextView.text = ""
                }
            }
        }
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
        self.showAlert(String(format: "Custom event '%@' dispatched", customEventName), withDescription: "")
    }
    
    func refreshControlValues() {
        customEventNameTextField.text = CustomEventData.getCustomEventName()
        customEventMetadata = CustomEventData.getCustomEventMetadata()
        if (customEventMetadata.count > 0) {
            customEventMetadataTextView.text = customEventMetadata.description
        } else {
            customEventMetadataTextView.text = ""
        }
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
}

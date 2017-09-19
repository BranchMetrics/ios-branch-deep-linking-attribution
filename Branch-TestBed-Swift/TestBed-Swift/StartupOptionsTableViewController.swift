//
//  StartupOptionsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class StartupOptionsTableViewController: UITableViewController {

    @IBOutlet weak var activeBranchKeyTextField: UITextField!
    @IBOutlet weak var activeSetDebugEnabledSwitch: UISwitch!
    @IBOutlet weak var pendingBranchKeyTextField: UITextField!
    @IBOutlet weak var pendingSetDebugEnabledSwitch: UISwitch!
    
    
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
            self.performSegue(withIdentifier: "StartupOptionsTableViewToTextViewFormTableView", sender: "pendingBranchKey")
        default : break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.source as? TextViewFormTableViewController {
            switch sender as! String {
            case "pendingBranchKey":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.sender = sender as! String
                vc.viewTitle = "Branch Key"
                vc.header = "Branch Key"
                vc.footer = "This Branch key will be used the next time the application is closed (not merely backgrounded) and re-opened."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = StartupOptionsData.getPendingBranchKey()!
            default:
                break
            }
        }
    }
    
    @IBAction func unwindTextViewFormTableViewController(_ segue:UIStoryboardSegue) {
        
        if let vc = segue.source as? TextViewFormTableViewController {
            
            switch vc.sender {
            case "pendingBranchKey":
                if let pendingBranchKey = vc.textView.text {
                    guard self.pendingBranchKeyTextField.text != pendingBranchKey else {
                        return
                    }
                    StartupOptionsData.setPendingBranchKey(pendingBranchKey)
                    self.pendingBranchKeyTextField.text = pendingBranchKey
                }
            default: break
            }
        }
    }

    @IBAction func pendingSetDebugEnabledButtonValueChanged(_ sender: AnyObject) {
        StartupOptionsData.setPendingSetDebugEnabled(self.pendingSetDebugEnabledSwitch.isOn)
    }
    
    func refreshControlValues() {
        pendingBranchKeyTextField.text = StartupOptionsData.getPendingBranchKey()
        pendingSetDebugEnabledSwitch.isOn = StartupOptionsData.getPendingSetDebugEnabled()!
        
        if activeBranchKeyTextField.text == "" {
            showAlert("Initialization Failure", withDescription: "Close and re-open app to initialize Branch")
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

//
//  TestTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class TableFormViewController: UITableViewController {
    
    // MARK: Control
    
    var tableViewSections = [[String:Any]]()
    var senderName = ""
    var viewTitle = "Default Title"
    var keyboardType = UIKeyboardType.default
    var uiSwitches = [String:UISwitch]()
    var returnValues = [String:String]()
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = tableViewSections[section]
        let cells = section["TableViewCells"] as! [[String:String]]
        
        return cells.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = tableViewSections[indexPath.section]
        let cells = section["TableViewCells"] as! [[String:String]]
        let cell = cells[indexPath.row] as [String:String]?

        if let segueIdentifier = cell!["InputForm"] {
            self.performSegue(withIdentifier: segueIdentifier, sender: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = tableViewSections[indexPath.section]
        let cells = section["TableViewCells"] as! [[String:String]]
        let cellParameters = cells[indexPath.row] as [String:String]?
        let identifier = cellParameters!["CellReuseIdentifier"]

        switch(identifier!) {
        case "TextFieldCell":
            let cell: TextFieldCell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath) as! TextFieldCell
            cell.textField.text = cellParameters!["Text"]
            cell.textField.placeholder = cellParameters!["Placeholder"]
            cell.textField.accessibilityHint = cellParameters!["AccessibilityHint"]
            cell.textField.isUserInteractionEnabled = false
            if let _ = cellParameters!["InputForm"] {
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            }
            return cell
        case "ToggleSwitchCell":
            let cell: ToggleSwitchCell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath) as! ToggleSwitchCell
            cell.toggleSwitch.isOn = cellParameters!["isOn"] == "true"
            cell.toggleSwitchLabel.isEnabled = cellParameters!["isEnabled"] == "true"
            cell.toggleSwitch.isEnabled = cellParameters!["isEnabled"] == "true"
            cell.toggleSwitchLabel.text = cellParameters!["Label"]
            uiSwitches[cellParameters!["Name"]!] = cell.toggleSwitch
            return cell
        default:
            let cell: TextFieldCell = tableView.dequeueReusableCell(withIdentifier: identifier!, for: indexPath) as! TextFieldCell
            cell.textField.text = "Application Error"
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let formSection = tableViewSections[section]
        return formSection["Header"] as? String
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let formSection = tableViewSections[section]
        return formSection["Footer"] as? String
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TextViewForm" {
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextViewFormTableViewController
            vc.sender = sender
            vc.header = "Key"
            vc.footer = "This key will be used the next time the application is closed (not merely backgrounded) and re-opened."
            vc.keyboardType = UIKeyboardType.alphabet
            
            if let cell: TextFieldCell = tableView.cellForRow(at: sender as! IndexPath) as? TextFieldCell {
                vc.incumbantValue = cell.textField.text ?? ""
                vc.viewTitle = cell.textField.placeholder ?? ""
                vc.header = cell.textField.placeholder ?? ""
                vc.footer = cell.textField.accessibilityHint ?? ""
            }
        } else {
            for toggleSwitch in uiSwitches {
                returnValues[toggleSwitch.key] = toggleSwitch.value.isOn.description
            }
        }
    }

    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) {
    }
    
    @IBAction func unwindTextViewForm(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? TextViewFormTableViewController {
            if let indexPath = vc.sender as? IndexPath {
                if let tableViewCell: TextFieldCell = tableView.cellForRow(at: indexPath) as? TextFieldCell {
                    let section = tableViewSections[indexPath.section]
                    let cells = section["TableViewCells"] as! [[String:String]]
                    let cell = cells[indexPath.row] as [String:String]?
                    let text = vc.textView.text
                    
                    tableViewCell.textField.text = text
                    returnValues[cell!["Name"]!] = text
                }
            }
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

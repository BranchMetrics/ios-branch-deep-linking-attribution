//
//  DictionaryTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class DictionaryTableViewController: UITableViewController {
    
    var incumbantKey = ""
    var incumbantValue = ""
    var viewTitle = "Default Dictionary Title"
    var keyHeader = "Default Key Header"
    var keyPlaceholder = "Default Key Placeholder"
    var keyFooter = "Default Key Footer"
    var valueHeader = "Default Value Header"
    var valueFooter = "Default Value Footer"
    var keyKeyboardType = UIKeyboardType.default
    var valueKeyboardType = UIKeyboardType.default
    var dictionary = [String: AnyObject]()
    var sender = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionary.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "DictionaryTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! DictionaryTableViewCell
        
        let keys = Array(dictionary.keys)
        cell.keyLabel.text = keys[(indexPath as NSIndexPath).row]
        cell.valueLabel.text = self.dictionary[keys[(indexPath as NSIndexPath).row]] as? String
        
        return cell
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let keys = Array(dictionary.keys)
            dictionary.removeValue(forKey: keys[(indexPath as NSIndexPath).row])
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddKeyValuePair" {
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! KeyValuePairTableViewController
            vc.incumbantKey = incumbantKey
            vc.incumbantValue = incumbantValue
            vc.viewTitle = viewTitle
            vc.keyHeader = keyHeader
            vc.keyPlaceholder = keyPlaceholder
            vc.keyFooter = keyFooter
            vc.valueHeader = valueHeader
            vc.valueFooter = valueFooter
            vc.keyKeyboardType = UIKeyboardType.default
            vc.valueKeyboardType = UIKeyboardType.default
            
            // Get the cell that generated this segue.
            if let selectedCell = sender as? DictionaryTableViewCell {
                let indexPath = tableView.indexPath(for: selectedCell)!
                let keys = Array(dictionary.keys)
                let selectedParameterKey = keys[(indexPath as NSIndexPath).row]
                let selectedParameterValue = self.dictionary[keys[(indexPath as NSIndexPath).row]] as? String
                vc.incumbantKey = selectedParameterKey
                vc.incumbantValue = selectedParameterValue!
            }
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindKeyValuePairTableViewController(_ sender: UIStoryboardSegue) {
        if let sourceVC = sender.source as? KeyValuePairTableViewController {
            
            guard sourceVC.keyTextField.text!.count > 0 else {
                return
            }
            dictionary[sourceVC.keyTextField.text!] = sourceVC.valueTextView.text as AnyObject?
            tableView.reloadData()
        }
    }
    
}

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
    var keyKeyboardType = UIKeyboardType.Default
    var valueKeyboardType = UIKeyboardType.Default
    var dictionary = [String: AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dictionary.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "DictionaryTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! DictionaryTableViewCell
        
        let keys = Array(dictionary.keys).sort()
        cell.keyLabel.text = keys[indexPath.row]
        cell.valueLabel.text = self.dictionary[keys[indexPath.row]] as? String

        return cell
    }
    

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let keys = Array(dictionary.keys)
            dictionary.removeValueForKey(keys[indexPath.row])

            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddKeyValuePair" {
            let nc = segue.destinationViewController as! UINavigationController
            let vc = nc.topViewController as! KeyValuePairTableViewController
            vc.incumbantKey = incumbantKey
            vc.incumbantValue = incumbantValue
            vc.viewTitle = viewTitle
            vc.keyHeader = keyHeader
            vc.keyPlaceholder = keyPlaceholder
            vc.keyFooter = keyFooter
            vc.valueHeader = valueHeader
            vc.valueFooter = valueFooter
            vc.keyKeyboardType = UIKeyboardType.Default
            vc.valueKeyboardType = UIKeyboardType.Default
            
            // Get the cell that generated this segue.
            if let selectedCell = sender as? DictionaryTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                let keys = Array(dictionary.keys)
                let selectedParameterKey = keys[indexPath.row]
                let selectedParameterValue = self.dictionary[keys[indexPath.row]] as? String
                vc.incumbantKey = selectedParameterKey
                vc.incumbantValue = selectedParameterValue!
            }
        }
    }
    
    @IBAction func unwindByCancelling(segue:UIStoryboardSegue) { }
    
    @IBAction func unwindKeyValuePairTableViewController(sender: UIStoryboardSegue) {
        if let sourceVC = sender.sourceViewController as? KeyValuePairTableViewController {
            
            guard sourceVC.keyTextField.text!.characters.count > 0 else {
                return
            }
            dictionary[sourceVC.keyTextField.text!] = sourceVC.valueTextView.text
            tableView.reloadData()
        }
    }
    
}

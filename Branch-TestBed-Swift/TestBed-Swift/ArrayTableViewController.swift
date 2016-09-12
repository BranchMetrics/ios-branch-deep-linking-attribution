//
//  ArrayTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class ArrayTableViewController: UITableViewController {
    
    var array = [String]()
    var incumbantValue = ""
    var viewTitle = "Default Array Title"
    var header = "Default Array Header"
    var placeholder = "Default Array Placeholder"
    var footer = "Default Array Footer"
    var keyboardType = UIKeyboardType.Default
    
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
        return array.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "ArrayTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ArrayTableViewCell
        
        cell.elementLabel.text = array[indexPath.row]
        
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
            array.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddElement" {
            let nc = segue.destinationViewController as! UINavigationController
            let vc = nc.topViewController as! TextFieldFormTableViewController
            vc.incumbantValue = incumbantValue
            vc.viewTitle = viewTitle
            vc.header = header
            vc.placeholder = placeholder
            vc.footer = footer
            vc.keyboardType = UIKeyboardType.Default
        }
    }
    
    @IBAction func unwindByCancelling(segue:UIStoryboardSegue) { }
    
    @IBAction func unwindTextFieldFormTableViewController(sender: UIStoryboardSegue) {
        if let vc = sender.sourceViewController as? TextFieldFormTableViewController {
            
            if let receivedValue = vc.textField.text {
                
                guard receivedValue.characters.count > 0 else {
                    return
                }
                
                guard !array.contains(receivedValue) else {
                    return
                }
                
                array.append(receivedValue)
                array.sortInPlace()
                tableView.reloadData()
                
            }
        }
    }
    
}

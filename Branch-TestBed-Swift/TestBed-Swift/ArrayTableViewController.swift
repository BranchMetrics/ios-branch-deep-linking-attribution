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
    var keyboardType = UIKeyboardType.default
    
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
        return array.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "ArrayTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ArrayTableViewCell
        
        cell.elementLabel.text = array[(indexPath as NSIndexPath).row]
        
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
            array.remove(at: (indexPath as NSIndexPath).row)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddElement" {
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! TextFieldFormTableViewController
            vc.incumbantValue = incumbantValue
            vc.viewTitle = viewTitle
            vc.header = header
            vc.placeholder = placeholder
            vc.footer = footer
            vc.keyboardType = UIKeyboardType.default
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindTextFieldForm(_ sender: UIStoryboardSegue) {
        if let vc = sender.source as? TextFieldFormTableViewController {
            
            if let receivedValue = vc.textField.text {
                
                guard receivedValue.count > 0 else {
                    return
                }
                
                guard !array.contains(receivedValue) else {
                    return
                }
                
                array.append(receivedValue)
                array.sort()
                tableView.reloadData()
                
            }
        }
    }
    
}

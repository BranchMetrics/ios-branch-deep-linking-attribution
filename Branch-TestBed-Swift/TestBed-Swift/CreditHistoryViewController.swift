//
//  CreditHistoryViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class CreditHistoryViewController: UITableViewController {
    
    var creditTransactions: Array<AnyObject>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.creditTransactions == nil {
            return 0
        }
        return self.creditTransactions!.count > 0 ? self.creditTransactions!.count : 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "CreditTransactionRow")! as UITableViewCell
        
        if (cell == nil) {
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "CreditTransactionRow")
        }
        
        
        if (self.creditTransactions!.count > 0) {
            let creditItem: Dictionary = self.creditTransactions![(indexPath as NSIndexPath).row] as! Dictionary<String, AnyObject>
            let transaction = creditItem["transaction"] as! Dictionary<String, AnyObject>
            let amount = transaction["amount"] as! Int
            let bucket = transaction["bucket"] as! String
            var amountAsString: String
            if (amount >= 0) {
                amountAsString = String(format: "+%d", amount)
            } else {
                amountAsString = String(format: "%d", amount)
            }
            
            var text = String(format: "%@ to %@", amountAsString, bucket)
            
            if transaction.keys.contains("referrer") {
                text = String(format: "%@ - Referred by: %@", text, transaction["referrer"] as! CVarArg)
            }
            if transaction.keys.contains("referrer") {
                text = String(format: "%@ - User Referred: %@", text, transaction["referree"] as! CVarArg)
            }
            cell!.textLabel!.text = text
            
            
            let dateString = transaction["date"] as! String
            let dateFormatter = DateFormatter()

            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = dateFormatter.date(from: dateString) {
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                cell!.detailTextLabel!.text = dateFormatter.string(from: date)
            }
        } else {
            cell!.textLabel!.text = "None found";
            cell!.detailTextLabel!.text = "";
        }
        
        return cell!
    }

}

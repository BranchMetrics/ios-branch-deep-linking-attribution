//
//  ProductArrayTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//
import UIKit

class ProductArrayTableViewController: UITableViewController {
    
    var array = CommerceEventData.products()
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
        
        let cellIdentifier = "ProductArrayTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ProductArrayTableViewCell
        
        let product = array[(indexPath as NSIndexPath).row]
        cell.elementLabel.text = product["name"]
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            array.remove(at: (indexPath as NSIndexPath).row)
            CommerceEventData.setProducts(array)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindProductTableViewController(_ sender: UIStoryboardSegue) {
        if let vc = sender.source as? ProductTableViewController {
            
            let productProperties = [
                "name": (vc.productNameTextField.text?.count)! > 0 ? vc.productNameTextField.text : vc.productNameTextField.placeholder,
                "brand": (vc.productBrandTextField.text?.count)! > 0 ? vc.productBrandTextField.text : vc.productBrandTextField.placeholder,
                "sku": (vc.productSKUTextField.text?.count)! > 0 ? vc.productSKUTextField.text : vc.productSKUTextField.placeholder,
                "quantity": (vc.productQuantityTextField.text?.count)! > 0 ? vc.productQuantityTextField.text : vc.productQuantityTextField.placeholder,
                "price": (vc.productPriceTextField.text?.count)! > 0 ? vc.productPriceTextField.text : vc.productPriceTextField.placeholder,
                "variant": (vc.productVariantTextField.text?.count)! > 0 ? vc.productVariantTextField.text : vc.productVariantTextField.placeholder,
                "category": (vc.productCategoryTextField.text?.count)! > 0 ? vc.productCategoryTextField.text : vc.productCategoryTextField.placeholder
            ]
            
            array = CommerceEventData.productsWithAddedProduct(productProperties as! [String : String])
            tableView.reloadData()

        }
    }
    
}

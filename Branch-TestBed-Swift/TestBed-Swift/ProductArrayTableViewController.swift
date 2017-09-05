//
//  ProductArrayTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//
import UIKit

class ProductArrayTableViewController: UITableViewController {
    
    var array = DataStore.getProducts()
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
    
    
//    // Override to support conditional editing of the table view.
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            array.remove(at: (indexPath as NSIndexPath).row)
            DataStore.setProducts(array)
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//    }
    
    
    // MARK: - Navigation
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "AddProduct" {
//            let nc = segue.destination as! UINavigationController
//            let vc = nc.topViewController as! ProductTableViewController
//        }
//    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindProductTableViewController(_ sender: UIStoryboardSegue) {
        if let vc = sender.source as? ProductTableViewController {
            
            let productProperties = [
                "name": (vc.productNameTextField.text?.characters.count)! > 0 ? vc.productNameTextField.text : vc.productNameTextField.placeholder,
                "brand": (vc.productBrandTextField.text?.characters.count)! > 0 ? vc.productBrandTextField.text : vc.productBrandTextField.placeholder,
                "sku": (vc.productSKUTextField.text?.characters.count)! > 0 ? vc.productSKUTextField.text : vc.productSKUTextField.placeholder,
                "quantity": (vc.productQuantityTextField.text?.characters.count)! > 0 ? vc.productQuantityTextField.text : vc.productQuantityTextField.placeholder,
                "price": (vc.productPriceTextField.text?.characters.count)! > 0 ? vc.productPriceTextField.text : vc.productPriceTextField.placeholder,
                "variant": (vc.productVariantTextField.text?.characters.count)! > 0 ? vc.productVariantTextField.text : vc.productVariantTextField.placeholder,
                "category": (vc.productCategoryTextField.text?.characters.count)! > 0 ? vc.productCategoryTextField.text : vc.productCategoryTextField.placeholder
            ]
            
            array = DataStore.getProductsWithAddedProduct(productProperties as! [String : String])
            tableView.reloadData()
//            let me = vc.productNameTextField.text
//                    productProperties["name"] = productNameTextField.text
//                    productProperties["brand"] = vc.productBrandTextField.text
//                    productProperties["sku"] = vc.productSKUTextField.text
//                    productProperties["quantity"] = vc.productQuantityTextField.text
//                    productProperties["price"] = vc.productPriceTextField.text
//                    productProperties["variant"] = vc.productVariantTextField.text
//                    productProperties["category"] = vc.productCategoryTextField.text
            
            
//            if let receivedValue = vc.textField.text {
//                
//                guard receivedValue.characters.count > 0 else {
//                    return
//                }
//                
//                guard !array.contains(receivedValue) else {
//                    return
//                }
//                
//                array.append(receivedValue)
//                array.sort()
//                tableView.reloadData()
//                
//            }
        }
    }
    
}

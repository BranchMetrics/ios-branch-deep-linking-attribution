//
//  ProductTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/13/17.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class ProductTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - Controls

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var productNameTextField: UITextField!
    @IBOutlet weak var productBrandTextField: UITextField!
    @IBOutlet weak var productSKUTextField: UITextField!
    @IBOutlet weak var productQuantityTextField: UITextField!
    @IBOutlet weak var productPriceTextField: UITextField!
    @IBOutlet weak var productVariantTextField: UITextField!
    @IBOutlet weak var productCategoryTextField: UITextField!
    

    var defaults = CommerceEventData.productDefaults()
    let picker = UIPickerView()
    let productCategories = CommerceEventData.productCategories()
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productNameTextField.delegate = self
        productBrandTextField.delegate = self
        productSKUTextField.delegate = self
        productQuantityTextField.delegate = self
        productPriceTextField.delegate = self
        productVariantTextField.delegate = self
        productCategoryTextField.delegate = self
        
        productNameTextField.placeholder = defaults["name"]
        productBrandTextField.placeholder = defaults["brand"]
        productSKUTextField.placeholder = defaults["sku"]
        productQuantityTextField.placeholder = defaults["quantity"]
        productPriceTextField.placeholder = defaults["price"]
        productVariantTextField.placeholder = defaults["variant"]
        productCategoryTextField.placeholder = defaults["category"]
        
        productCategoryTextField.inputView = picker
        productCategoryTextField.inputAccessoryView = createToolbar(true)
        
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true
        
        productNameTextField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - PickerView
    
    func createToolbar(_ withCancelButton: Bool) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0,y: 0,width: self.view.frame.size.width,height: 44))
        toolbar.tintColor = UIColor.gray
        let donePickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.donePicking))
        let emptySpace = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        if (withCancelButton) {
            let cancelPickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(self.cancelPicking))
            toolbar.setItems([cancelPickingButton, emptySpace, donePickingButton], animated: true)
        } else {
            toolbar.setItems([emptySpace, donePickingButton], animated: true)
        }
        return toolbar
    }
    
    @objc func cancelPicking() {
        productCategoryTextField.resignFirstResponder()
    }
    
    @objc func donePicking() {
        self.productCategoryTextField.text = productCategories[picker.selectedRow(inComponent: 0)]
        self.productCategoryTextField.resignFirstResponder()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return productCategories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return productCategories[row]
    }
    
}

//
//  CommerceEventDetailsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/11/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//
import UIKit

class CommerceEventDetailsTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - Controls
    
    @IBOutlet weak var resetAllValuesButton: UIButton!
    @IBOutlet weak var transactionIDTextField: UITextField!
    @IBOutlet weak var affiliationTextField: UITextField!
    @IBOutlet weak var couponTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var shippingTextField: UITextField!
    @IBOutlet weak var taxTextField: UITextField!
    @IBOutlet weak var revenueTextField: UITextField!
    
    var defaults = DataStore.getCommerceEventDefaults()
    let picker = UIPickerView()
    let  currencies = DataStore.getCurrencies()
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transactionIDTextField.delegate = self
        affiliationTextField.delegate = self
        couponTextField.delegate = self
        currencyTextField.delegate = self
        shippingTextField.delegate = self
        taxTextField.delegate = self
        revenueTextField.delegate = self
        
//        transactionIDTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        affiliationTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        couponTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        currencyTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        shippingTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        taxTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
//        revenueTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        transactionIDTextField.placeholder = defaults["transactionID"]
        affiliationTextField.placeholder = defaults["affiliation"]
        couponTextField.placeholder = defaults["coupon"]
        currencyTextField.placeholder = defaults["currency"]
        shippingTextField.placeholder = defaults["shipping"]
        taxTextField.placeholder = defaults["tax"]
        revenueTextField.placeholder = defaults["revenue"]
        
        currencyTextField.inputView = picker
        currencyTextField.inputAccessoryView = createToolbar(true)
        
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true
        
        transactionIDTextField.becomeFirstResponder()
        refreshControls()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Controls
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
//    func textFieldDidChange(_ textField: UITextField) {
//        refreshDataStore()
//        refreshControls()
//    }
    
    @IBAction func resetAllValuesButtonTouchUpInside(_ sender: AnyObject) {
        clearControls()
        refreshDataStore()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (1,7) :
            self.performSegue(withIdentifier: "ShowProducts", sender: "Products")
        default : break
        }
        
    }
    
    @IBAction func unwindProductArrayTableViewController(_ segue:UIStoryboardSegue) {}
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        refreshDataStore()
        refreshControls()
    }
    
    func clearControls() {
        transactionIDTextField.text = ""
        affiliationTextField.text = ""
        couponTextField.text = ""
        currencyTextField.text = ""
        shippingTextField.text = ""
        taxTextField.text = ""
        revenueTextField.text = ""
        
        resetAllValuesButton.isEnabled = false
    }
    
    func refreshControls() {
        guard var commerceEvent = DataStore.getCommerceEvent() else {
            return
        }

        guard commerceEvent["default"] as? String == "false" else {
            clearControls()
            return
        }
        
        var resetAllValuesEnabled = false
        if (commerceEvent["transactionID"] as? String != "") {
            transactionIDTextField.text = commerceEvent["transactionID"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["affiliation"] as? String != "") {
            affiliationTextField.text = commerceEvent["affiliation"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["coupon"] as? String != "") {
            couponTextField.text = commerceEvent["coupon"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["currency"] as? String != "") {
            currencyTextField.text = commerceEvent["currency"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["shipping"] as? String != "") {
            shippingTextField.text = commerceEvent["shipping"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["tax"] as? String != "") {
            taxTextField.text = commerceEvent["tax"] as? String
            resetAllValuesEnabled = true
        }
        if (commerceEvent["revenue"] as? String != "") {
            revenueTextField.text = commerceEvent["revenue"] as? String
            resetAllValuesEnabled = true
        }
        resetAllValuesButton.isEnabled = resetAllValuesEnabled
    }
    
    func refreshDataStore() {
        DataStore.setCommerceEvent([
            "transactionID": transactionIDTextField.text!,
            "affiliation": affiliationTextField.text!,
            "coupon": couponTextField.text!,
            "currency": currencyTextField.text!,
            "shipping": shippingTextField.text!,
            "tax": taxTextField.text!,
            "revenue": revenueTextField.text!,
            "default": "false"
            ])
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
    
    func cancelPicking() {
        currencyTextField.resignFirstResponder()
    }
    
    func donePicking() {
        self.currencyTextField.text = String(currencies[picker.selectedRow(inComponent: 0)].characters.prefix(3))
        self.currencyTextField.resignFirstResponder()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return  currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return  currencies[row]
    }
    
}

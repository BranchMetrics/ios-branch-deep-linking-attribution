//
//  SimulateReferralsViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 5/26/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

import UIKit

class SimulateReferralsViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var promoCodeTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var selectRewardTypeTextField: UITextField!
    @IBOutlet weak var selectRewardRecipientTextField: UITextField!
    @IBOutlet weak var promoCodePrefixTextField: UITextField!
    @IBOutlet weak var selectExpirationDateTextField: UITextField!
    
    let datePicker = UIDatePicker()
    var expirationDate: NSDate?
    let pickers = ["rewardTypes": ["Unlimited use", "Single use"], "rewardRecipients": ["Referred user", "Referring user", "Both users"], "datePicker": []]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        self.tableView.addGestureRecognizer(gestureRecognizer)
        
        self.selectRewardTypeTextField.inputView = createPicker()
        self.selectRewardTypeTextField.inputAccessoryView = createToolbar(false)
        
        self.selectRewardRecipientTextField.inputView = createPicker()
        self.selectRewardRecipientTextField.inputAccessoryView = createToolbar(false)
        
        datePicker.datePickerMode = .Date
        self.selectExpirationDateTextField.inputView = datePicker
        self.selectExpirationDateTextField.inputAccessoryView = createToolbar(true)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func getButtonTouchUpInside(sender: AnyObject) {
        let branch = Branch.getInstance()
        let prefix = self.promoCodePrefixTextField.text
        let amount = Int(self.amountTextField.text!)
        let rewardType = BranchPromoCodeUsageType.init(rawValue: UInt(pickers["rewardTypes"]!.indexOf(self.selectRewardTypeTextField.text!)!))
        let rewardRecipient = BranchPromoCodeRewardLocation.init(rawValue: UInt(pickers["rewardRecipients"]!.indexOf(self.selectRewardRecipientTextField.text!)!))
        branch.getPromoCodeWithPrefix(prefix, amount: amount!, expiration: self.expirationDate, bucket: "default", usageType: rewardType!, rewardLocation: rewardRecipient!) { (params, error) in
            if (error == nil) {
                let parameters = params as Dictionary
                let promoCode = parameters[BRANCH_RESPONSE_KEY_PROMO_CODE] as! String
                
                self.promoCodeTextField.text = promoCode
                print(String(format: "Branch TestBed: Get promo code results:\n%@", parameters.description))
                let logOutput = String(format:"Promo Code Generated: %@\n\n%@", promoCode, params.description)
                self.performSegueWithIdentifier("SimulateReferralsToLogOutput", sender: logOutput)
                // self.showAlert("Promo Code Generated", withDescription: parameters.description)
            } else {
                print(String(format: "Branch TestBed: Error retreiving promo code: \n%@", error.localizedDescription))
                self.showAlert("Promo Code Generation Failed", withDescription: error.localizedDescription)
            }
        }
    }
    
    
    @IBAction func validateButtonTouchUpInside(sender: AnyObject) {
        
        if (self.promoCodeTextField.text?.characters.count > 0) {
            let branch = Branch.getInstance()
            let promoCode = self.promoCodeTextField.text
            
            branch.validateReferralCode(promoCode, andCallback: { (params, error) in
                if (error == nil) {
                    let parameters = params as Dictionary
                    
                    if (parameters["error_message"] == nil) {
                        print(String(format: "Branch TestBed: Promo code %@ is valid.", promoCode!))
                        print(String(format: "Branch TestBed: Parameters returned from Branch:\n%@", parameters.description))
                        self.showAlert("Validation Succeeded", withDescription: parameters.description)
                    } else {
                        print(String(format: "Branch TestBed: Promo code %@ is invalid.", promoCode!))
                        print(String(format: "Branch TestBed: Parameters returned from Branch:\n%@", parameters.description))
                        self.showAlert("Validation Failed", withDescription: parameters.description)
                    }
                    
                } else {
                    print(String(format: "Branch TestBed: Error retreiving promo code: %@\n", promoCode!))
                    self.showAlert("Validation Failed", withDescription: String(format: "Unable to validate promo code\n%@", promoCode!))
                }
            })
            
        } else {
            print("Branch TestBed: No promo code to validate\n")
            self.showAlert("No promo code!", withDescription: "Please enter a promo code to validate")
        }
        
    }
    
    
    @IBAction func redeemButtonTouchUpInside(sender: AnyObject) {
        
        if (self.promoCodeTextField.text?.characters.count > 0) {
            let branch = Branch.getInstance()
            let promoCode = self.promoCodeTextField.text
            
            branch.applyReferralCode(promoCode, andCallback: { (params, error) in
                if (error == nil) {
                    let parameters = params as Dictionary
                    
                    if (parameters["error_message"] == nil) {
                        print(String(format: "Branch TestBed: Promo code %@ has been successfully applied", promoCode!))
                        print(String(format: "Branch TestBed: Parameters returned from Branch: %@", parameters.description))
                        self.showAlert("Promo Code Applied", withDescription: parameters.description)
                    } else {
                        print(String(format: "Promo code %@ is invalid.", promoCode!))
                        print(String(format: "Branch TestBed: Parameters returned from Branch: %@", parameters.description))
                        self.showAlert("Promo Code Invalid", withDescription: parameters.description)
                    }
                    
                } else {
                    print(String(format: "Branch TestBed: Error retreiving promo code: %@", promoCode!))
                    self.showAlert("Validation Failed", withDescription: String(format: "Unable to validate promo code\n%@", promoCode!))
                }

            })
            
        } else {
            print("Branch TestBed: No promo code to redeem\n")
            self.showAlert("No promo code!", withDescription: "Please enter a promo code to redeem")
        }
        
    }

    //MARK: Resign First Responder
    func hideKeyboard() {
        if (self.promoCodeTextField.isFirstResponder()) {
            self.promoCodeTextField.resignFirstResponder();
        } else if (self.amountTextField.isFirstResponder()) {
            self.amountTextField.resignFirstResponder();
        } else if (self.promoCodePrefixTextField.isFirstResponder()) {
            self.promoCodePrefixTextField.resignFirstResponder();
        }
    }
    
    
    //MARK: Data Sources
    func createToolbar(withCancelButton: Bool) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRectMake(0,0,self.view.frame.size.width,44))
        toolbar.tintColor = UIColor.grayColor()
        let donePickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: #selector(self.donePicking))
        let emptySpace = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        if (withCancelButton) {
            let cancelPickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(self.donePicking))
            toolbar.setItems([cancelPickingButton, emptySpace, donePickingButton], animated: true)
        } else {
            toolbar.setItems([emptySpace, donePickingButton], animated: true)
        }
        
        return toolbar
    }
    
    
    func createPicker() -> UIPickerView {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true
        
        return picker
    }
    
    
    func donePicking() {
        if (pickerType() == "rewardRecipients") {
            self.selectRewardRecipientTextField.resignFirstResponder()
        } else if (pickerType() == "rewardTypes"){
            self.selectRewardTypeTextField.resignFirstResponder()
        } else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd"
            self.expirationDate = datePicker.date
            self.selectExpirationDateTextField.text = String(format:"%@", dateFormatter.stringFromDate(self.expirationDate!))
            self.selectExpirationDateTextField.resignFirstResponder()
        }
    }
    
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickers[pickerType()]!.count
    }
    
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return  pickers[pickerType()]![row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerType() == "rewardRecipients") {
            selectRewardRecipientTextField.text = pickers[pickerType()]![row]
        } else if (pickerType() == "rewardTypes"){
            selectRewardTypeTextField.text = pickers[pickerType()]![row]
        }
    }
    
    
    func pickerType() -> String {
        if (self.selectRewardRecipientTextField.editing == true) {
            return "rewardRecipients"
        } else if (self.selectRewardTypeTextField.editing == true) {
            return "rewardTypes"
        } else {
            return "datePicker"
        }
        
    }
    
    
    func showAlert(alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.Alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil));
        presentViewController(alert, animated: true, completion: nil);
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = (segue.destinationViewController as! LogOutputViewController)
        vc.logOutput = sender as! String
    }

    
}

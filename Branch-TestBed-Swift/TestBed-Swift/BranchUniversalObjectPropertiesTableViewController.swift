//
//  BranchUniversalObjectPropertiesTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class BranchUniversalObjectPropertiesTableViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    // MARK: - Controls
    
    @IBOutlet weak var clearAllValuesButton: UIButton!
    @IBOutlet weak var publiclyIndexableSwitch: UISwitch!
    @IBOutlet weak var keywordsTextView: UITextView!
    @IBOutlet weak var canonicalIdentifierTextField: UITextField!
    @IBOutlet weak var expDateTextField: UITextField!
    @IBOutlet weak var contentTypeTextField: UITextField!
    @IBOutlet weak var ogTitleTextField: UITextField!
    @IBOutlet weak var ogDescriptionTextField: UITextField!
    @IBOutlet weak var ogImageURLTextField: UITextField!
    @IBOutlet weak var ogImageWidthTextField: UITextField!
    @IBOutlet weak var ogImageHeightTextField: UITextField!
    @IBOutlet weak var ogVideoTextField: UITextField!
    @IBOutlet weak var ogURLTextField: UITextField!
    @IBOutlet weak var ogTypeTextField: UITextField!
    @IBOutlet weak var ogRedirectTextField: UITextField!
    @IBOutlet weak var ogAppIDTextField: UITextField!
    @IBOutlet weak var twitterCardTextField: UITextField!
    @IBOutlet weak var twitterTitleTextField: UITextField!
    @IBOutlet weak var twitterDescriptionTextField: UITextField!
    @IBOutlet weak var twitterSiteTextField: UITextField!
    @IBOutlet weak var twitterAppCountryTextField: UITextField!
    @IBOutlet weak var twitterPlayerTextField: UITextField!
    @IBOutlet weak var twitterPlayerWidthTextField: UITextField!
    @IBOutlet weak var twitterPlayerHeightTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var customDataTextView: UITextView!
    
    let datePicker = UIDatePicker()
    var universalObjectProperties = [String: AnyObject]()
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canonicalIdentifierTextField.delegate = self
        expDateTextField.delegate = self
        contentTypeTextField.delegate = self
        ogTitleTextField.delegate = self
        ogDescriptionTextField.delegate = self
        ogImageURLTextField.delegate = self
        ogImageWidthTextField.delegate = self
        ogImageHeightTextField.delegate = self
        ogVideoTextField.delegate = self
        ogURLTextField.delegate = self
        ogTypeTextField.delegate = self
        ogRedirectTextField.delegate = self
        ogAppIDTextField.delegate = self
        twitterCardTextField.delegate = self
        twitterTitleTextField.delegate = self
        twitterDescriptionTextField.delegate = self
        twitterSiteTextField.delegate = self
        twitterAppCountryTextField.delegate = self
        twitterPlayerTextField.delegate = self
        twitterPlayerWidthTextField.delegate = self
        twitterPlayerHeightTextField.delegate = self
        priceTextField.delegate = self
        currencyTextField.delegate = self
        
        UITableViewCell.appearance().backgroundColor = UIColor.white
        
        datePicker.datePickerMode = .date
        self.expDateTextField.inputView = datePicker
        self.expDateTextField.inputAccessoryView = createToolbar(true)
        
        refreshControls()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Navigation
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func clearAllValuesButton(_ sender: AnyObject) {
        universalObjectProperties.removeAll()
        refreshControls()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section) {
        case 2 :
            self.performSegue(withIdentifier: "ShowKeywords", sender: "Keywords")
        case 26 :
            self.performSegue(withIdentifier: "ShowCustomData", sender: "CustomData")
        default : break
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        refreshUniversalObjectProperties()
        
        switch segue.identifier! {
        case "ShowKeywords":
            let vc = segue.destination as! ArrayTableViewController
            if let keywords = universalObjectProperties["$keywords"] as? [String] {
                vc.array = keywords
            }
            vc.viewTitle = "Keywords"
            vc.header = "Keyword"
            vc.placeholder = "keyword"
            vc.footer = "Enter a new keyword that describes the content."
            vc.keyboardType = UIKeyboardType.default
        case "ShowCustomData":
            let vc = segue.destination as! DictionaryTableViewController
            if let customData = universalObjectProperties["customData"] as? [String: AnyObject] {
                vc.dictionary = customData
            }
            vc.viewTitle = "Custom Data"
            vc.keyHeader = "Key"
            vc.keyPlaceholder = "key"
            vc.keyFooter = ""
            vc.valueHeader = "Value"
            vc.valueFooter = ""
            vc.keyKeyboardType = UIKeyboardType.default
            vc.valueKeyboardType = UIKeyboardType.default
        default: break
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindDictionaryTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? DictionaryTableViewController {
            let customData = vc.dictionary
            universalObjectProperties["customData"] = customData as AnyObject?
            if customData.count > 0 {
                customDataTextView.text = customData.description
            } else {
                customDataTextView.text = ""
            }
        }
    }
    
    @IBAction func unwindArrayTableViewController(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? ArrayTableViewController {
            let keywords = vc.array
            universalObjectProperties["$keywords"] = keywords as AnyObject?
            if keywords.count > 0 {
                keywordsTextView.text = keywords.description
            } else {
                keywordsTextView.text = ""
            }
        }
    }
    
    //MARK: - Date Picker
    
    func createToolbar(_ withCancelButton: Bool) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0,y: 0,width: self.view.frame.size.width,height: 44))
        toolbar.tintColor = UIColor.gray
        let donePickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.donePicking))
        let emptySpace = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        if (withCancelButton) {
            let cancelPickingButton = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(self.donePicking))
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let expirationDate = datePicker.date
        self.expDateTextField.text = String(format:"%@", dateFormatter.string(from: expirationDate))
        self.expDateTextField.resignFirstResponder()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 0
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil));
        present(alert, animated: true, completion: nil);
    }
    
    func refreshControls() {
        
        publiclyIndexableSwitch.isOn = false
        if let publiclyIndexable = universalObjectProperties["$publicly_indexable"] as? String {
            if publiclyIndexable == "1" {
                publiclyIndexableSwitch.isOn = true
            } else {
                publiclyIndexableSwitch.isOn = false
            }
        }
        
        if let contentKeywords = universalObjectProperties["$keywords"] as? [String] {
            if contentKeywords.count > 0 {
                keywordsTextView.text = contentKeywords.description
            } else {
                keywordsTextView.text = ""
            }
        } else {
            keywordsTextView.text = ""
        }
        
        canonicalIdentifierTextField.text = universalObjectProperties["$canonical_identifier"] as? String
        expDateTextField.text = universalObjectProperties["$exp_date"] as? String
        contentTypeTextField.text = universalObjectProperties["$content_type"] as? String
        ogTitleTextField.text = universalObjectProperties["$og_title"] as? String
        ogDescriptionTextField.text = universalObjectProperties["$og_description"] as? String
        ogImageURLTextField.text = universalObjectProperties["$og_image_url"] as? String
        ogImageWidthTextField.text = universalObjectProperties["$og_image_width"] as? String
        ogImageHeightTextField.text = universalObjectProperties["$og_image_height"] as? String
        ogVideoTextField.text = universalObjectProperties["$og_video"] as? String
        ogURLTextField.text = universalObjectProperties["$og_url"] as? String
        ogTypeTextField.text = universalObjectProperties["$og_type"] as? String
        ogRedirectTextField.text = universalObjectProperties["$og_redirect"] as? String
        ogAppIDTextField.text = universalObjectProperties["$og_app_id"] as? String
        twitterCardTextField.text = universalObjectProperties["$twitter_card"] as? String
        twitterTitleTextField.text = universalObjectProperties["$twitter_title"] as? String
        twitterDescriptionTextField.text = universalObjectProperties["$twitter_description"] as? String
        twitterSiteTextField.text = universalObjectProperties["$twitter_site"] as? String
        twitterAppCountryTextField.text = universalObjectProperties["$twitter_app_country"] as? String
        twitterPlayerTextField.text = universalObjectProperties["$twitter_player"] as? String
        twitterPlayerWidthTextField.text = universalObjectProperties["$twitter_player_width"] as? String
        twitterPlayerHeightTextField.text = universalObjectProperties["$twitter_player_height"] as? String
        priceTextField.text = universalObjectProperties["$price"] as? String
        currencyTextField.text = universalObjectProperties["$currency"] as? String
        
        if let customData = universalObjectProperties["customData"] as? [String: String] {
            if customData.count > 0 {
                customDataTextView.text = customData.description
            } else {
                customDataTextView.text = ""
            }
        } else {
            customDataTextView.text = ""
        }
    }
    
    func refreshUniversalObjectProperties() {
        
        if publiclyIndexableSwitch.isOn {
            universalObjectProperties["$publicly_indexable"] = "1" as AnyObject?
        } else {
            universalObjectProperties.removeValue(forKey: "$publicly_indexable")
        }
        
        addProperty("$canonical_identifier", value: canonicalIdentifierTextField.text!)
        addProperty("$exp_date", value: expDateTextField.text!)
        addProperty("$content_type", value: contentTypeTextField.text!)
        addProperty("$og_title", value: ogTitleTextField.text!)
        addProperty("$og_description", value: ogDescriptionTextField.text!)
        addProperty("$og_image_url", value: ogImageURLTextField.text!)
        addProperty("$og_image_width", value: ogImageWidthTextField.text!)
        addProperty("$og_image_height", value: ogImageHeightTextField.text!)
        addProperty("$og_video", value: ogVideoTextField.text!)
        addProperty("$og_url", value: ogURLTextField.text!)
        addProperty("$og_type", value: ogTypeTextField.text!)
        addProperty("$og_redirect", value: ogRedirectTextField.text!)
        addProperty("$og_app_id", value: ogAppIDTextField.text!)
        addProperty("$twitter_card", value: twitterCardTextField.text!)
        addProperty("$twitter_title", value: twitterTitleTextField.text!)
        addProperty("$twitter_description", value: twitterDescriptionTextField.text!)
        addProperty("$twitter_site", value: twitterSiteTextField.text!)
        addProperty("$twitter_app_country", value: twitterAppCountryTextField.text!)
        addProperty("$twitter_player", value: twitterPlayerTextField.text!)
        addProperty("$twitter_player_width", value: twitterPlayerWidthTextField.text!)
        addProperty("$twitter_player_height", value: twitterPlayerHeightTextField.text!)
        addProperty("$price", value: priceTextField.text!)
        addProperty("$currency", value: currencyTextField.text!)
        
    }
    
    func addProperty(_ key: String, value: String) {
        guard value.characters.count > 0 else {
            universalObjectProperties.removeValue(forKey: key)
            return
        }
        universalObjectProperties[key] = value as AnyObject?
    }
    
}

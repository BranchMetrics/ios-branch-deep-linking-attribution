//
//  KeyValuePairTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class KeyValuePairTableViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - Controls
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var valueTextView: UITextView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var incumbantKey = ""
    var incumbantValue = ""
    var viewTitle = "Default Title"
    var keyHeader = "Default Key Header"
    var keyPlaceholder = "Default Key Placeholder"
    var keyFooter = "Default Key Footer"
    var valueHeader = "Default Value Header"
    var valueFooter = "Default Value Footer"
    var keyKeyboardType = UIKeyboardType.default
    var valueKeyboardType = UIKeyboardType.default
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
        keyTextField.placeholder = keyPlaceholder
        keyTextField.text = incumbantKey
        keyTextField.keyboardType = keyKeyboardType
        keyTextField.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
        valueTextView.delegate = self
        valueTextView.text = incumbantValue
        valueTextView.keyboardType = valueKeyboardType
        valueTextView.textColor = UIColor.lightGray
        updateButtonStates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Control Functions
    
    @IBAction func clearButtonTouchUpInside(_ sender: AnyObject) {
        valueTextView.text = incumbantValue
        valueTextView.textColor = UIColor.lightGray
        valueTextView.becomeFirstResponder()
        valueTextView.selectedTextRange = valueTextView.textRange(from: valueTextView.beginningOfDocument, to: valueTextView.beginningOfDocument)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var header = ""
        
        switch section {
        case 0:
            header = keyHeader
        case 1:
            header = valueHeader
        default:
            break
        }
        return header
    }
    
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        var footer = ""
        
        switch section {
        case 0:
            footer = keyFooter
        case 1:
            footer = valueFooter
        default:
            break
        }
        return footer
    }
    
    @objc func textFieldDidChange() {
        saveButton.isEnabled = keyTextField.text == "" ? false : true
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard (text != "\n") else {
            performSegue(withIdentifier: "Save", sender: "save")
            return false
        }
        
        let t: NSString = textView.text as NSString
        let updatedText = t.replacingCharacters(in: range, with:text)
        
        guard (updatedText != "") else {
            clearButton.isHidden = true
            textView.text = incumbantValue
            textView.textColor = UIColor.lightGray
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            return false
        }
        
        if (textView.textColor == UIColor.lightGray) {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateButtonStates()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        clearButton.isHidden = textView.text == "" ? true : false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        clearButton.isHidden = true
    }
    
    func updateButtonStates() {
        clearButton.isHidden = valueTextView.textColor == UIColor.lightGray ? true : false
        saveButton.isEnabled = keyTextField.text == "" ? false : true
    }
    
}

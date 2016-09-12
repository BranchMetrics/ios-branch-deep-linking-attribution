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
    
    var incumbantKey = ""
    var incumbantValue = ""
    var viewTitle = "Default Title"
    var keyHeader = "Default Key Header"
    var keyPlaceholder = "Default Key Placeholder"
    var keyFooter = "Default Key Footer"
    var valueHeader = "Default Value Header"
    var valueFooter = "Default Value Footer"
    var keyKeyboardType = UIKeyboardType.Default
    var valueKeyboardType = UIKeyboardType.Default
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
        keyTextField.text = incumbantKey
        valueTextView.delegate = self
        valueTextView.text = incumbantValue
        setClearButtonVisibility()
        setFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Control Functions
    
    @IBAction func clearButtonTouchUpInside(sender: AnyObject) {
        valueTextView.text = incumbantValue
        valueTextView.textColor = UIColor.lightGrayColor()
        valueTextView.becomeFirstResponder()
        valueTextView.selectedTextRange = valueTextView.textRangeFromPosition(valueTextView.beginningOfDocument, toPosition: valueTextView.beginningOfDocument)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
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
    
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
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
    
    func textViewDidChangeSelection(textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGrayColor() {
                textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            }
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        guard (text != "\n") else {
            performSegueWithIdentifier("Save", sender: "save")
            return false
        }
        
        let t: NSString = textView.text
        let updatedText = t.stringByReplacingCharactersInRange(range, withString:text)
        
        guard (updatedText != "") else {
            clearButton.hidden = true
            textView.text = incumbantValue
            textView.textColor = UIColor.lightGrayColor()
            textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
            return false
        }
        
        if (textView.textColor == UIColor.lightGrayColor()) {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        setClearButtonVisibility()
    }
    
    func setFirstResponder() {
        if (incumbantKey == "") {
            keyTextField.becomeFirstResponder()
        } else {
            keyTextField.enabled = false
            valueTextView.becomeFirstResponder()
        }
    }
    
    func setClearButtonVisibility() {
        if valueTextView.text == "" {
            clearButton.hidden = true
        } else if valueTextView.textColor != UIColor.lightGrayColor() {
            clearButton.hidden = false
        }
    }
    
}

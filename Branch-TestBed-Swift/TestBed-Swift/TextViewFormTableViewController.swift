//
//  TextViewFormTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class TextViewFormTableViewController: UITableViewController, UITextViewDelegate {

    // MARK: - Controls

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var clearButton: UIButton!
    
    var sender = ""
    var incumbantValue = ""
    var viewTitle = "Default Title"
    var header = "Default Header"
    var footer = "Default Footer"
    var keyboardType = UIKeyboardType.Default
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
        textView.delegate = self
        textView.keyboardType = keyboardType
        textView.text = incumbantValue
        setClearButtonVisibility()
        textView.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Control Functions
    
    @IBAction func clearButtonTouchUpInside(sender: AnyObject) {
        textView.text = incumbantValue
        textView.textColor = UIColor.lightGrayColor()
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRangeFromPosition(textView.beginningOfDocument, toPosition: textView.beginningOfDocument)
        setClearButtonVisibility()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
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
            setClearButtonVisibility()
            return false
        }
        
        if (textView.textColor == UIColor.lightGrayColor()) {
            textView.text = nil
            textView.textColor = UIColor.blackColor()
        }
        
        setClearButtonVisibility()
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        setClearButtonVisibility()
    }
    
    func setClearButtonVisibility() {
        if textView.text == "" {
            clearButton.hidden = true
        } else if textView.textColor != UIColor.lightGrayColor() {
            clearButton.hidden = false
        }
    }
    
}

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
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var sender: Any?
    var senderName = ""
    var incumbantValue = ""
    var viewTitle = "Default Title"
    var header = "Default Header"
    var footer = "Default Footer"
    var keyboardType = UIKeyboardType.default
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
        textView.delegate = self
        textView.keyboardType = keyboardType
        textView.text = incumbantValue
        updateButtonStates()
        textView.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Control Functions
    
    @IBAction func clearButtonTouchUpInside(_ sender: AnyObject) {
        textView.text = incumbantValue
        textView.textColor = UIColor.lightGray
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        updateButtonStates()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footer
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
            updateButtonStates()
            return false
        }
        
        if (textView.textColor == UIColor.lightGray) {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        
        updateButtonStates()
        
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
        clearButton.isHidden = textView.textColor == UIColor.lightGray ? true : false
        saveButton.isEnabled = textView.text == incumbantValue ? false : true
    }
    
}

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
    var keyboardType = UIKeyboardType.default
    
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
    
    @IBAction func clearButtonTouchUpInside(_ sender: AnyObject) {
        textView.text = incumbantValue
        textView.textColor = UIColor.lightGray
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        setClearButtonVisibility()
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
            setClearButtonVisibility()
            return false
        }
        
        if (textView.textColor == UIColor.lightGray) {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        
        setClearButtonVisibility()
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        setClearButtonVisibility()
    }
    
    func setClearButtonVisibility() {
        if textView.text == "" {
            clearButton.isHidden = true
        } else if textView.textColor != UIColor.lightGray {
            clearButton.isHidden = false
        }
    }
    
}

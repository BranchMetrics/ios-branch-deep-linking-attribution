//
//  TextFieldFormTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 8/29/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
import UIKit

class TextFieldFormTableViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: Control
    
    @IBOutlet weak var textField: UITextField!
    
    var sender = ""
    var incumbantValue = ""
    var updatedValue = ""
    var viewTitle = "Default Title"
    var placeholder = "Default Placeholder"
    var header = "Default Header"
    var footer = "Default Footer"
    var keyboardType = UIKeyboardType.default
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewTitle
        textField.placeholder = placeholder
        textField.text = incumbantValue
        textField.keyboardType = keyboardType
        textField.text = incumbantValue
        textField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Control Functions
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return footer
    }
    
}

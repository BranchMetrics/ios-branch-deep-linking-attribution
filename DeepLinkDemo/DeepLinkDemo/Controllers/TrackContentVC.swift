//
//  TrackContentVC.swift
//  DeepLinkDemo
//
//  Created by Apple on 12/05/22.
//

import UIKit
import BranchSDK

class TrackContentVC: ParentViewController {
    
    @IBOutlet weak var txtFldOptions: UITextField!
    
    var pickerView = UIPickerView()
    
    var trackContenOptions = [String]()
    private var reachability:Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        trackContenOptions = ["ADD_TO_CART", "ADD_TO_WISHLIST", "VIEW_CART", "INITIATE_PURCHASE", "ADD_PAYMENT_INFO", "PURCHASE", "SPEND_CREDITS", "SUBSCRIBE", "START_TRIAL", "CLICK_AD", "VIEW_AD", "SEARCH", "VIEW_ITEM", "VIEW_ITEMS", "RATE", "SHARE", "START_TRIAL", "CLICK_AD", "COMPLETE_REGISTRATION", "COMPLETE_TUTORIAL", "ACHIEVE_LEVEL", "UNLOCK_ACHIEVEMENT", "INVITE", "LOGIN", "RESERVE", "OPT_IN", "OPT_OUT"]
        
        pickerView.dataSource = self
        pickerView.delegate = self
        
        txtFldOptions.inputView = pickerView
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width,height: 44.0))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: target, action: #selector(tapDone))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: target, action: #selector(tapCancel))
        toolBar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        txtFldOptions.inputAccessoryView = toolBar
        
        txtFldOptions.text = trackContenOptions.first
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("TrackContent")
    }
    
    
    @objc func tapDone() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        if trackContenOptions.indices.contains(selectedRow){
            txtFldOptions.text = trackContenOptions[selectedRow]
        }
        txtFldOptions.resignFirstResponder()
        self.view.endEditing(true)
    }
    @objc func tapCancel() {
        self.view.endEditing(true)
    }
    
    @IBAction func backBtnAction(){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func nextBtnAction(){
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        if let vc = storyBoard.instantiateViewController(withIdentifier: "CreateObjectReferenceObject") as? CreateObjectReferenceObject {
            vc.screenMode = 7
            vc.txtFldValue = String(txtFldOptions.text ?? "")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension TrackContentVC: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return trackContenOptions.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return trackContenOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        txtFldOptions.text = trackContenOptions[row]
    }
}

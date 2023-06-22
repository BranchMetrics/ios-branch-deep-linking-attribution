//
//  ReadVC.swift
//  DeepLinkDemo
//
//  Created by Rakesh kumar on 4/28/22.
//

import UIKit
import BranchSDK
class ReadVC: ParentViewController {
    
    @IBOutlet weak var btnback: UIButton!
    @IBOutlet weak var labelTxt: UILabel!
    @IBOutlet weak var btnShare: UIButton!
    var strTxt = ""
    private var reachability:Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        labelTxt.text = "Success\nUrl is generated.\nHere is the Short URL\(strTxt)"
        btnShare.layer.cornerRadius = 8.0
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.onClicLabel(sender:)))
        labelTxt.isUserInteractionEnabled = true
        labelTxt.addGestureRecognizer(tap)
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    // And that's the function :)
    @objc func onClicLabel(sender:UITapGestureRecognizer) {
        
        UserDefaults.standard.set(true, forKey: "isRead")
        let anURL = URL(string: strTxt)
        Branch.getInstance().handleDeepLink(anURL)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func btnrReadDeeplink(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "isRead")
        let anURL = URL(string: strTxt)
        Branch.getInstance().handleDeepLink(anURL)
    }
    
}

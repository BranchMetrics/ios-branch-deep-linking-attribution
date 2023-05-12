//
//  DispalyVC.swift
//  DeepLinkDemo
//
//  Created by Rakesh kumar on 4/26/22.
//

import UIKit
import BranchSDK

class DispalyVC: ParentViewController {
    
    @IBOutlet weak var pageTitle: UILabel!
    
    @IBOutlet weak var textViewDescription: UITextView!
    
    var textDescription = ""
    var linkURL = ""
    var appData : Dictionary<String, Any> = Dictionary<String, Any>()
    private var reachability:Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debugPrint("textDescription", textDescription)
        
        if appData["nav_to"] is String {
            self.pageTitle.text = "Navigate To Content"
            let content = String(format:"\nReferring link: %@ \n\nSession Details:\n %@", linkURL, appData.jsonStringRepresentation!)
            self.textViewDescription.text = content
        } else if appData["display_Cont"] is String {
            self.pageTitle.text = "Display Content"
            let content = String(format:"\nReferring link: %@ \n\nSession Details:\n %@", linkURL, appData.jsonStringRepresentation!)
            self.textViewDescription.text = content
        }
        else{
            self.pageTitle.text = "Read Deep Linking"
            self.textViewDescription.text = String(format:"%@", textDescription)
        }
        
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if appData["nav_to"] is String {
            Utils.shared.setLogFile("NavigateContentDetail")
        } else if appData["display_Cont"] is String {
            Utils.shared.setLogFile("DisplayContentDetail")
        } else {
            Utils.shared.setLogFile("ReadDeepLinkingDetail")
        }
    }
    
    
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}

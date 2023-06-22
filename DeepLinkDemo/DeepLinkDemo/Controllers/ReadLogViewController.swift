//
//  ReadLogViewController.swift
//  DeepLinkDemo
//
//  Created by Apple on 17/05/22.
//

import UIKit

class ReadLogViewController: ParentViewController {
    
    @IBOutlet weak var textViewDescription: UITextView!
    
    var selectedFileName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textViewDescription.text = loadTextWithFileName(selectedFileName)
        reachabilityCheck()
    }
    
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func loadTextWithFileName(_ fileName: String) -> String? {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
                return nil
            }
            return text
        }
        return nil
    }
    
}



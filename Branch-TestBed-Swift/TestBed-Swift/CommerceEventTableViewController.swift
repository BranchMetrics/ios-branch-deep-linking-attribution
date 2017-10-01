//
//  CommerceEventTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class CommerceEventTableViewController: UITableViewController {

    @IBOutlet weak var commerceEventDetailsLabel: UILabel!
    @IBOutlet weak var commerceEventCustomMetadataTextView: UITextView!
    @IBOutlet weak var sendCommerceEventButton: UIButton!
    
    var commerceEventCustomMetadata = [String: AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControlValues()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row) {
        case (0,0) :
            self.performSegue(withIdentifier: "CommerceEventDetails", sender: "CommerceEventDetails")
        case (0,1) :
            self.performSegue(withIdentifier: "Dictionary", sender: "CommerceEventCustomMetadata")
        default : break
        }
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let senderName = sender as? String {
            switch senderName {
            case "CommerceEventCustomMetadata":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! DictionaryTableViewController
                commerceEventCustomMetadata = CommerceEventData.commerceEventCustomMetadata()
                vc.dictionary = commerceEventCustomMetadata
                vc.viewTitle = "Commerce Metadata"
                vc.keyHeader = "Key"
                vc.keyPlaceholder = "key"
                vc.keyFooter = ""
                vc.valueHeader = "Value"
                vc.valueFooter = ""
                vc.keyKeyboardType = UIKeyboardType.default
                vc.valueKeyboardType = UIKeyboardType.default
                vc.sender = sender as! String
            default:
                break
            }
        }
    }
    
    @IBAction func unwindCommerceEventDetails(_ segue:UIStoryboardSegue) { }
    
    @IBAction func unwindDictionary(_ segue:UIStoryboardSegue) {
        if let vc = segue.source as? DictionaryTableViewController {
            commerceEventCustomMetadata = vc.dictionary
            CommerceEventData.setCommerceEventCustomMetadata(commerceEventCustomMetadata)
            if commerceEventCustomMetadata.count > 0 {
                commerceEventCustomMetadataTextView.text = commerceEventCustomMetadata.description
            } else {
                commerceEventCustomMetadataTextView.text = ""
            }
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    @IBAction func sendCommerceEventButtonTouchUpInside(_ sender: AnyObject) {
        
        let commerceEvent = CommerceEventData.bNCCommerceEvent()
        
        WaitingViewController.showWithMessage(
            message: "Getting parameters...",
            activityIndicator:true,
            disableTouches:true
        )
        
        Branch.getInstance()?.send(
            commerceEvent,
            metadata: commerceEventCustomMetadata,
            withCompletion: { (response, error) in
                let errorMessage: String = (error?.localizedDescription != nil) ?
                    error!.localizedDescription : "<nil>"
                let responseMessage  = (response?.description != nil) ?
                    response!.description : "<nil>"
                let message = String.init(
                    format:"Commerce event completion called.\nError: %@\nResponse:\n%@",
                    errorMessage,
                    responseMessage
                )
                NSLog("%@", message)
                WaitingViewController.hide()
                self.showAlert("Commerce Event", withDescription: message)
        }
        )
    }
    
    func refreshControlValues() {
        commerceEventCustomMetadata = CommerceEventData.commerceEventCustomMetadata()
        if (commerceEventCustomMetadata.count > 0) {
            commerceEventCustomMetadataTextView.text = commerceEventCustomMetadata.description
        } else {
            commerceEventCustomMetadataTextView.text = ""
        }
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

}

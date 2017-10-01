//
//  ReferralRewardsTableViewController.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/16/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class ReferralRewardsTableViewController: UITableViewController {
    
    @IBOutlet weak var rewardsBucketTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var rewardsBalanceOfBucketTextField: UITextField!
    @IBOutlet weak var reloadBalanceButton: UIButton!
    @IBOutlet weak var rewardPointsToRedeemTextField: UITextField!
    @IBOutlet weak var redeemPointsButton: UIButton!
    @IBOutlet weak var rewardHistoryLabel: UILabel!
    
    var creditHistory: Array<AnyObject>?
    
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
            self.performSegue(withIdentifier: "TextViewForm", sender: "RewardsBucket")
        case (0,3) :
            self.performSegue(withIdentifier: "TextViewForm", sender: "RewardPointsToRedeem")
        case (0,5) :
            let branch = Branch.getInstance()
            branch?.getCreditHistory { (creditHistory, error) in
                if (error == nil) {
                    self.creditHistory = creditHistory as Array?
                    self.performSegue(withIdentifier: "CreditHistory", sender: "CreditHistory")
                } else {
                    print(String(format: "Branch TestBed: Error retrieving credit history: %@", error!.localizedDescription))
                    self.showAlert("Error retrieving credit history", withDescription:error!.localizedDescription)
                }
            }
        default : break
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let senderName = sender as? String {
            switch senderName {
            case "CreditHistory":
                let vc = (segue.destination as! CreditHistoryViewController)
                vc.creditTransactions = creditHistory
            case "RewardsBucket":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.senderName = senderName
                vc.viewTitle = "Rewards Bucket"
                vc.header = "Rewards Bucket"
                vc.footer = "Rewards are granted via rules configured in the Rewards Rules section of the dashboard. Rewards are normally accumulated in a 'default' bucket, however any bucket name can be specified in rewards rules. Use this setting to specify the name of a non-default rewards bucket."
                vc.keyboardType = UIKeyboardType.alphabet
                vc.incumbantValue = rewardsBucketTextField.text!
            case "RewardPointsToRedeem":
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! TextViewFormTableViewController
                vc.senderName = senderName
                vc.viewTitle = "Reward Points"
                vc.header = "Number of Reward Points to Redeem"
                vc.footer = "This is the quantity of points to subtract from the selected bucket's balance."
                vc.keyboardType = UIKeyboardType.numberPad
                vc.incumbantValue = rewardPointsToRedeemTextField.text!
            default:
                break
            }
        }
    }
    
    @IBAction func unwindTextViewForm(_ segue:UIStoryboardSegue) {
        
        if let vc = segue.source as? TextViewFormTableViewController {
            switch vc.senderName {
            case "RewardsBucket":
                if let rewardsBucket = vc.textView.text {
                    
                    guard self.rewardsBucketTextField.text != rewardsBucket else {
                        return
                    }
                    ReferralRewardsData.setRewardsBucket(rewardsBucket)
                    self.rewardsBucketTextField.text = rewardsBucket
                    self.refreshRewardsBalanceOfBucket()
                    
                }
            case "RewardPointsToRedeem":
                if let rewardPointsToRedeem = vc.textView.text {
                    
                    guard self.rewardPointsToRedeemTextField.text != rewardPointsToRedeem else {
                        return
                    }
                    ReferralRewardsData.setRewardPointsToRedeem(rewardPointsToRedeem)
                    self.rewardPointsToRedeemTextField.text = rewardPointsToRedeem
                }
            default: break
            }
        }
    }
    
    @IBAction func unwindByCancelling(_ segue:UIStoryboardSegue) { }
    
    func refreshRewardsBalanceOfBucket() {
        rewardsBalanceOfBucketTextField.isHidden = true
        activityIndicator.startAnimating()
        let branch = Branch.getInstance()
        branch?.loadRewards { (changed, error) in
            if (error == nil) {
                if self.rewardsBucketTextField.text == "" {
                    self.rewardsBalanceOfBucketTextField.text = String(format: "%ld", (branch?.getCredits())!)
                } else {
                    self.rewardsBalanceOfBucketTextField.text = String(format: "%ld", (branch?.getCreditsForBucket(self.rewardsBucketTextField.text))!)
                }
            }
        }
        activityIndicator.stopAnimating()
        rewardsBalanceOfBucketTextField.isHidden = false
    }
    
    @IBAction func redeemPointsButtonTouchUpInside(_ sender: AnyObject) {
        let points = rewardPointsToRedeemTextField.text != "" ? Int(rewardPointsToRedeemTextField.text!) : 5
        let bucket = rewardsBucketTextField.text != "" ? rewardsBucketTextField.text : "default"
        
        let branch = Branch.getInstance()
        branch?.redeemRewards(points!, forBucket: bucket) { (changed, error) in
            
            defer {
                self.rewardsBalanceOfBucketTextField.isHidden = false
                self.activityIndicator.stopAnimating()
            }
            
            if (error != nil || !changed) {
                print(String(format: "Branch TestBed: Didn't redeem anything: %@", error! as CVarArg))
                self.showAlert("Redemption Unsuccessful", withDescription: error!.localizedDescription)
            } else {
                print("Branch TestBed: Five Points Redeemed!")
            }
            
            self.refreshRewardsBalanceOfBucket()
        }
        
    }
    
    @IBAction func reloadBalanceButtonTouchUpInside(_ sender: AnyObject) {
        refreshRewardsBalanceOfBucket()
    }
    
    func refreshControlValues() {
        rewardsBucketTextField.text = ReferralRewardsData.rewardsBucket()
        rewardsBalanceOfBucketTextField.text = ReferralRewardsData.rewardsBalanceOfBucket()
        
        // Then initiate a refresh of the rewards balance
        refreshRewardsBalanceOfBucket()
        
        // Now get about populating the other controls
        rewardPointsToRedeemTextField.text = ReferralRewardsData.rewardPointsToRedeem()
    }
    
    func showAlert(_ alertTitle: String, withDescription message: String) {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
            self.refreshRewardsBalanceOfBucket()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
}

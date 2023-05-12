//
//  AddMetaDataVC.swift
//  DeepLinkDemo
//
//  Created by Apple on 13/05/22.
//

import UIKit
import BranchSDK

class AddMetaDataVC: ParentViewController {
    
    @IBOutlet weak var metaDataTblVw: UITableView!
    private var reachability:Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.metaDataTblVw.keyboardDismissMode = .onDrag
        reachabilityCheck()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.shared.setLogFile("AddMetadata")
    }
    
    
    @IBAction func backBtnAction(){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func submitBtnAction(){
        if let cell = metaDataTblVw.cellForRow(at: IndexPath(row: 0, section: 0)) as? MetaDataTableViewCell{
           
//            let branchUniversalObject = CommonMethod.sharedInstance.branchUniversalObject
//            branchUniversalObject.canonicalIdentifier = branchUniversalObject.canonicalIdentifier
//            branchUniversalObject.canonicalUrl        = "https://branch.io/item/12345"
//            branchUniversalObject.title               = branchUniversalObject.title
            let contentMetadata = BranchContentMetadata()
            let contentSchemaSelected : BranchContentSchema = BranchContentSchema(rawValue: cell.contentSchema.text!)
            contentMetadata.contentSchema     = contentSchemaSelected
            let quantityEntered = Double(cell.quantity.text ?? "0")
            contentMetadata.quantity          = quantityEntered ?? 0
            let formattedPrice  = NSDecimalNumber(string: cell.price.text ?? "0.0")
            if cell.price.text != "" {
                contentMetadata.price             = formattedPrice
                let currencySelected: BNCCurrency = BNCCurrency(rawValue: cell.currencyName.text!)
                contentMetadata.currency          = currencySelected
            }
            contentMetadata.sku               = cell.sku.text
            contentMetadata.productName       = cell.productName.text
            contentMetadata.productBrand      = cell.productBrand.text
            let productCategorySelected: BNCProductCategory = BNCProductCategory(rawValue: cell.productCategory.text!)
            contentMetadata.productCategory   = productCategorySelected
            contentMetadata.productVariant    = cell.productVariant.text
            let conditionSelected: BranchCondition = BranchCondition(rawValue: cell.productCondition.text!)
            contentMetadata.condition         = conditionSelected
            contentMetadata.customMetadata = [
                "custom_key1": cell.customMetadata.text!,
            ]
            contentMetadata.addressStreet = cell.street.text
            contentMetadata.addressCity = cell.city.text
            contentMetadata.addressRegion = cell.region.text
            contentMetadata.addressCountry = cell.country.text
            contentMetadata.addressPostalCode = cell.postalCode.text
            
            contentMetadata.latitude = Double(cell.latitude.text ?? "0.0") ?? 0.0
            contentMetadata.longitude = Double(cell.longitude.text ?? "0.0") ?? 0.0

            contentMetadata.ratingAverage = Double(cell.averageRating.text ?? "0.0") ?? 0.0
            contentMetadata.ratingMax = Double(cell.maximumRating.text ?? "0.0") ?? 0.0
            contentMetadata.ratingCount = Int(cell.ratingCount.text ?? "0") ?? 0
            contentMetadata.rating = Double(cell.rating.text ?? "0.0") ?? 0.0

            contentMetadata.imageCaptions = [cell.imageCaption.text ?? ""]
            CommonMethod.sharedInstance.contentMetaData = contentMetadata
            print("ContentMetaData:", contentMetadata)
            
            let metadataDetail = String(format: "%@", contentMetadata)
            NSLog("Metadata", metadataDetail);
            Utils.shared.setLogFile("AddMetadata")
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension AddMetaDataVC: UITableViewDataSource, UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MetaDataTableViewCell", for: indexPath) as? MetaDataTableViewCell{
            cell.submitBtn.addTarget(self, action: #selector(submitBtnAction), for: UIControl.Event.touchUpInside)
            cell.pickerDelegate = self
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


extension AddMetaDataVC: PickerViewDelegate{
    func removePickerView() {
        self.view.endEditing(true)
    }
}

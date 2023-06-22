//
//  MetaDataTableViewCell.swift
//  DeepLinkDemo
//
//  Created by Apple on 13/05/22.
//

import UIKit
import BranchSDK

protocol PickerViewDelegate{
    func removePickerView()
}
class MetaDataTableViewCell: UITableViewCell {
    
    var pickerDelegate: PickerViewDelegate!
    
    private let contentSchemaNames  = ["COMMERCE_AUCTION", "COMMERCE_BUSINESS", "COMMERCE_OTHER",
                                       "COMMERCE_PRODUCT", "COMMERCE_RESTAURANT", "COMMERCE_SERVICE",
                                       "COMMERCE_TRAVEL_FLIGHT", "COMMERCE_TRAVEL_HOTEL", "COMMERCE_TRAVEL_OTHER",
                                       "GAME_STATE", "MEDIA_IMAGE", "MEDIA_MIXED", "MEDIA_MUSIC", "MEDIA_OTHER",
                                       "MEDIA_VIDEO", "OTHER", "TEXT_ARTICLE", "TEXT_BLOG", "TEXT_OTHER",
                                       "TEXT_RECIPE", "TEXT_REVIEW", "TEXT_SEARCH_RESULTS", "TEXT_STORY",
                                       "TEXT_TECHNICAL_DOC"]
    
    private let productCategories = ["Animals & Pet Supplies", "Apparel & Accessories", "Arts & Entertainment",
                                     "Baby & Toddler", "Business & Industrial", "Cameras & Optics",
                                     "Electronics", "Food, Beverages & Tobacco", "Furniture", "Hardware",
                                     "Health & Beauty", "Home & Garden", "Luggage & Bags", "Mature",
                                     "Media", "Media", "Office Supplies", "Religious & Ceremonial",
                                     "Software", "Sporting Goods", "Toys & Games", "Vehicles & Parts"]

    
    private let productConditions = ["EXCELLENT", "NEW", "GOOD", "FAIR", "POOR", "USED", "REFURBISHED", "OTHER"]
    
    
    private let currencyNames = ["USD", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BOV", "BRL", "BSD", "BTN", "BWP", "BYN", "BYR", "CAD", "CDF", "CHE", "CHF", "CHW", "CLF", "CLP", "CNY", "COP", "COU", "CRC", "CUC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "INR", "IQD", "IRR", "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRO", "MUR", "MVR", "MWK", "MXN", "MXV", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLL", "SOS", "SRD", "SSP", "STD", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USN", "UYI", "UYU", "UZS", "VEF", "VND", "VUV", "WST", "XAF", "XAG", "XAU", "XBA", "XBB", "XBC", "XBD", "XCD", "XDR", "XFU", "XOF", "XPD", "XPF", "XPT", "XSU", "XTS", "XUA", "XXX", "YER", "ZAR", "ZMW"]
    
    private var pickerView = UIPickerView()
    
    @IBOutlet weak var contentSchema: UITextField!
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productBrand: UITextField!
    @IBOutlet weak var productVariant: UITextField!
    @IBOutlet weak var productCategory: UITextField!
    @IBOutlet weak var productCondition: UITextField!
    @IBOutlet weak var street: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var region: UITextField!
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var postalCode: UITextField!
    @IBOutlet weak var latitude: UITextField!
    @IBOutlet weak var longitude: UITextField!
    @IBOutlet weak var sku: UITextField!
    @IBOutlet weak var rating: UITextField!
    @IBOutlet weak var averageRating: UITextField!
    @IBOutlet weak var maximumRating: UITextField!
    @IBOutlet weak var ratingCount: UITextField!
    @IBOutlet weak var imageCaption: UITextField!
    @IBOutlet weak var quantity: UITextField!
    @IBOutlet weak var price: UITextField!
    @IBOutlet weak var currencyName: UITextField!
    @IBOutlet weak var customMetadata: UITextField!
    
    @IBOutlet weak var submitBtn: UIButton!
    
    fileprivate func setAtrributePlaceHolder(targetField: UITextField, placeholderTxt: String){
        targetField.setLeftPaddingPoints(10)
        targetField.attributedPlaceholder = NSAttributedString(
            string: placeholderTxt,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        )
        
    }
    
    fileprivate func prepareUI(){
        self.setAtrributePlaceHolder(targetField: self.productName, placeholderTxt: "Product Name")
        self.setAtrributePlaceHolder(targetField: self.productBrand, placeholderTxt: "Product Brand")
        self.setAtrributePlaceHolder(targetField: self.productVariant, placeholderTxt: "Product Variant")
        self.setAtrributePlaceHolder(targetField: self.street, placeholderTxt: "Street")
        self.setAtrributePlaceHolder(targetField: self.city, placeholderTxt: "City")
        self.setAtrributePlaceHolder(targetField: self.region, placeholderTxt: "Region")
        self.setAtrributePlaceHolder(targetField: self.country, placeholderTxt: "Country")
        self.setAtrributePlaceHolder(targetField: self.postalCode, placeholderTxt: "Postal Code")
        self.setAtrributePlaceHolder(targetField: self.latitude, placeholderTxt: "Latitude")
        self.setAtrributePlaceHolder(targetField: self.longitude, placeholderTxt: "Longitude")
        self.setAtrributePlaceHolder(targetField: self.sku, placeholderTxt: "SKU")
        self.setAtrributePlaceHolder(targetField: self.rating, placeholderTxt: "Rating")
        self.setAtrributePlaceHolder(targetField: self.averageRating, placeholderTxt: "Average Rating")
        self.setAtrributePlaceHolder(targetField: self.maximumRating, placeholderTxt: "Maximum Rating")
        self.setAtrributePlaceHolder(targetField: self.ratingCount, placeholderTxt: "Rating Count")
        self.setAtrributePlaceHolder(targetField: self.imageCaption, placeholderTxt: "Image Caption")
        self.setAtrributePlaceHolder(targetField: self.quantity, placeholderTxt: "Quantity")
        self.setAtrributePlaceHolder(targetField: self.price, placeholderTxt: "Price")
        self.setAtrributePlaceHolder(targetField: self.customMetadata, placeholderTxt: "Custom Metadata")
        
    }
    
    fileprivate func setupPickerViewDataSource() {
        pickerView.dataSource = self
        pickerView.delegate = self
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width,height: 44.0))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(tapDone))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(tapCancel))
        toolBar.setItems([cancelButton, flexibleSpace, doneButton], animated: false)
        
        contentSchema.inputView = pickerView
        contentSchema.inputAccessoryView = toolBar
        contentSchema.text = contentSchemaNames.first
        
        currencyName.inputView = pickerView
        currencyName.inputAccessoryView = toolBar
        currencyName.text = currencyNames.first
        
        productCondition.inputView = pickerView
        productCondition.inputAccessoryView = toolBar
        productCondition.text = productConditions.first
        
        productCategory.inputView = pickerView
        productCategory.inputAccessoryView = toolBar
        productCategory.text = productCategories.first
        
        productCategory.setLeftPaddingPoints(10)
        productCondition.setLeftPaddingPoints(10)
        currencyName.setLeftPaddingPoints(10)
        contentSchema.setLeftPaddingPoints(10)
        
        
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prepareUI()
        
        setupPickerViewDataSource()
        
        self.selectionStyle = .none
    }
    
    @objc func tapDone() {
        if contentSchema.isFirstResponder{
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            if contentSchemaNames.indices.contains(selectedRow){
                contentSchema.text = contentSchemaNames[selectedRow]
            }
            contentSchema.resignFirstResponder()
        } else if currencyName.isFirstResponder{
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            if currencyNames.indices.contains(selectedRow){
                currencyName.text = currencyNames[selectedRow]
            }
            currencyName.resignFirstResponder()
        } else if productCondition.isFirstResponder{
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            if productConditions.indices.contains(selectedRow){
                productCondition.text = productConditions[selectedRow]
            }
            productCondition.resignFirstResponder()
        } else if productCategory.isFirstResponder{
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            if productCategories.indices.contains(selectedRow){
                productCategory.text = productCategories[selectedRow]
            }
            productCategory.resignFirstResponder()
        }
        self.endEditing(true)
    }
    
    @objc func tapCancel() {
        self.endEditing(true)
    }
    
    
}


extension MetaDataTableViewCell: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if contentSchema.isFirstResponder{
            return contentSchemaNames.count
        } else if currencyName.isFirstResponder{
            return currencyNames.count
        } else if productCondition.isFirstResponder{
            return productConditions.count
        } else if productCategory.isFirstResponder{
            return productCategories.count
        }
        return 0
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if contentSchema.isFirstResponder{
            return contentSchemaNames[row]
        } else if currencyName.isFirstResponder{
            return currencyNames[row]
        } else if productCondition.isFirstResponder{
            return productConditions[row]
        } else if productCategory.isFirstResponder{
            return productCategories[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if contentSchema.isFirstResponder{
            contentSchema.text = contentSchemaNames[row]
        } else if currencyName.isFirstResponder{
            currencyName.text = currencyNames[row]
        } else if productCondition.isFirstResponder{
            productCondition.text =  productConditions[row]
        } else if productCategory.isFirstResponder{
            productCategory.text =  productCategories[row]
        }
    }
}

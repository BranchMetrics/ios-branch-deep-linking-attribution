//
//  ProductArrayTableViewCell.swift
//  TestBed-Swift
//
//  Created by David Westgate on 7/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//
import UIKit

class ProductArrayTableViewCell: UITableViewCell {
    
    @IBOutlet weak var elementLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

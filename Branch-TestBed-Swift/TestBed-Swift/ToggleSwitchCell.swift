//
//  ToggleSwitchCell.swift
//  TestBed-Swift
//
//  Created by David Westgate on 9/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

import UIKit

class ToggleSwitchCell: UITableViewCell {

    @IBOutlet weak var toggleSwitchLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

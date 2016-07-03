//
//  SimulateReferralsViewController.h
//  Branch-TestBed
//
//  Created by David Westgate on 5/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BranchViewHandler.h"

@interface SimulateReferralsViewController : UITableViewController<UIPickerViewDataSource, UIPickerViewDelegate> {
    
    NSArray *rewardTypes;
    NSArray *rewardRecipients;
    UIDatePicker *datePicker;
    
}

@property (weak, nonatomic) IBOutlet UITextField *selectRewardTypeTextField;
@property (weak, nonatomic) IBOutlet UITextField *selectRewardRecipientTextField;
@property (weak, nonatomic) IBOutlet UITextField *expirationDateTextField;


@end

//
//  ReferralCodeViewController.h
//  Branch-TestBed
//
//  Created by Qinwei Gong on 11/27/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReferralCodeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *txtReferralCodeResult;
@property (weak, nonatomic) IBOutlet UITextField *txtReferralCodePrefix;
@property (weak, nonatomic) IBOutlet UILabel *lblReferralCodeValidation;
@property (weak, nonatomic) IBOutlet UILabel *lblReferralCodeApplication;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segReferralCodeFreq;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segReferralCodeLocation;

@end

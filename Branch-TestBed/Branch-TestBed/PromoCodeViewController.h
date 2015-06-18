//
//  PromoCodeViewController.h
//  Branch-TestBed
//
//  Created by Qinwei Gong on 11/27/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PromoCodeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *txtCodeResult;
@property (weak, nonatomic) IBOutlet UITextField *txtCodePrefix;
@property (weak, nonatomic) IBOutlet UILabel *lblCodeValidation;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segCodeFreq;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segCodeLocation;
@property (weak, nonatomic) IBOutlet UITextField *txtCodeExpiration;
@property (weak, nonatomic) IBOutlet UITextField *txtCodeAmount;

@end

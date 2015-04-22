//
//  ReferralCodeViewController.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 11/27/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "ReferralCodeViewController.h"
#import "Branch.h"

@interface ReferralCodeViewController ()

@property (nonatomic, strong) UIDatePicker *expirationPicker;

@end

@implementation ReferralCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.txtReferralCodeResult addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.txtReferralCodePrefix addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.txtReferralCodeResult.text = nil;
    self.lblReferralCodeValidation.text = nil;
    self.txtReferralCodeExpiration.text = nil;
    
    self.expirationPicker = [[UIDatePicker alloc] init];
    self.expirationPicker.datePickerMode = UIDatePickerModeDate;
    [self.expirationPicker addTarget:self action:@selector(updateDate) forControlEvents:UIControlEventValueChanged];
    self.txtReferralCodeExpiration.inputView = self.expirationPicker;
    
    NSDate *now = [NSDate date];
    int daysToAdd = 7;
    NSDate *date = [now dateByAddingTimeInterval:60 * 60 * 24 * daysToAdd];
    self.expirationPicker.date = date;
}

- (void)updateDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [formatter stringFromDate:self.expirationPicker.date];
    self.txtReferralCodeExpiration.text = stringFromDate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)cmdGetReferralCode:(UIButton *)sender {
    self.txtReferralCodeResult.text = nil;
    NSInteger amount = [self.txtReferralCodeAmount.text integerValue];
    if (amount == 0) {
        self.txtReferralCodeAmount.text = nil;
        self.txtReferralCodeAmount.placeholder = @"Invalid value";
        return;
    }
    NSDate *expiration = nil;
    if ([self.txtReferralCodeExpiration.text length] > 0) {
        expiration = self.expirationPicker.date;
    }
    Branch *branch = [Branch getInstance];
    [branch getReferralCodeWithPrefix:self.txtReferralCodePrefix.text
                               amount:amount
                           expiration:expiration
                               bucket:@"default"
                      calculationType:[self retrieveCalculationForSegment]
                             location:[self retrieveLocationForSegment]
                          andCallback:^(NSDictionary *params, NSError *error) {
                              if (!error) {
                                  self.txtReferralCodeResult.text = [params objectForKey:@"referral_code"];
                              } else {
                                  NSLog(@"Error in getting referral code: %@", error.localizedDescription);
                                  self.txtReferralCodeResult.text = @"Failed to get referral code";
                              }
                          }
     ];
}

- (BranchReferralCodeCalculation)retrieveCalculationForSegment {
    switch (self.segReferralCodeFreq.selectedSegmentIndex) {
        case 0:
            return BranchUnlimitedRewards;
        case 1:
            return BranchUniqueRewards;
        default:
            return BranchUnlimitedRewards;
    }
}

- (BranchReferralCodeLocation)retrieveLocationForSegment {
    switch (self.segReferralCodeLocation.selectedSegmentIndex) {
        case 0:
            return BranchReferreeUser;
        case 1:
            return BranchReferringUser;
        case 2:
            return BranchBothUsers;
        default:
            return BranchReferringUser;
    }
}

- (IBAction)cmdValidateReferralCode:(UIButton *)sender {
    self.lblReferralCodeValidation.text = nil;
    if (self.txtReferralCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch validateReferralCode:self.txtReferralCodeResult.text andCallback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                if ([self.txtReferralCodeResult.text isEqualToString:[params objectForKey:@"referral_code"]]) {
                    self.lblReferralCodeValidation.text = @"Valid";
                } else {
                    self.lblReferralCodeValidation.text = @"Invalid!";
                }
            } else {
                NSLog(@"Error in validating referral code: %@", error.localizedDescription);
                self.lblReferralCodeValidation.text = @"Invalid!";
            }
        }];
    }
}

- (IBAction)cmdApplyReferralCode:(UIButton *)sender {
    if (self.txtReferralCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch applyReferralCode:self.txtReferralCodeResult.text andCallback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                self.lblReferralCodeValidation.text = @"Applied";
            } else {
                NSLog(@"Error in apply referral code: %@", error.localizedDescription);
                self.lblReferralCodeValidation.text = @"Failed!";
            }
        }];
    }
}

- (void)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.txtReferralCodeResult isFirstResponder] && [touch view] != self.txtReferralCodeResult) {
        [self.txtReferralCodeResult resignFirstResponder];
    }
    if ([self.txtReferralCodePrefix isFirstResponder] && [touch view] != self.txtReferralCodePrefix) {
        [self.txtReferralCodePrefix resignFirstResponder];
    }
    if ([self.txtReferralCodeExpiration isFirstResponder] && [touch view] != self.txtReferralCodeExpiration) {
        [self.txtReferralCodeExpiration resignFirstResponder];
    }
    if ([self.txtReferralCodeAmount isFirstResponder] && [touch view] != self.txtReferralCodeAmount) {
        [self.txtReferralCodeAmount resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}



@end

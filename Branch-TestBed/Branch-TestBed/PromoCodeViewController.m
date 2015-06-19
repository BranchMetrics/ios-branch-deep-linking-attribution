//
//  PromoCodeViewController.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 11/27/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "PromoCodeViewController.h"
#import "Branch.h"

@interface PromoCodeViewController ()

@property (nonatomic, strong) UIDatePicker *expirationPicker;

@end

@implementation PromoCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.txtCodeResult addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [self.txtCodeResult addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.txtCodeResult.text = nil;
    self.lblCodeValidation.text = nil;
    self.txtCodeExpiration.text = nil;
    
    self.expirationPicker = [[UIDatePicker alloc] init];
    self.expirationPicker.datePickerMode = UIDatePickerModeDate;
    [self.expirationPicker addTarget:self action:@selector(updateDate) forControlEvents:UIControlEventValueChanged];
    self.txtCodeExpiration.inputView = self.expirationPicker;
    
    NSDate *now = [NSDate date];
    int daysToAdd = 7;
    NSDate *date = [now dateByAddingTimeInterval:60 * 60 * 24 * daysToAdd];
    self.expirationPicker.date = date;
}

- (void)updateDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [formatter stringFromDate:self.expirationPicker.date];
    self.txtCodeExpiration.text = stringFromDate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)cmdGetCode:(UIButton *)sender {
    self.txtCodeResult.text = nil;
    NSInteger amount = [self.txtCodeAmount.text integerValue];
    if (amount == 0) {
        self.txtCodeAmount.text = nil;
        self.txtCodeAmount.placeholder = @"Invalid value";
        return;
    }
    NSDate *expiration = nil;
    if ([self.txtCodeExpiration.text length] > 0) {
        expiration = self.expirationPicker.date;
    }
    Branch *branch = [Branch getInstance];
    [branch getPromoCodeWithPrefix:self.txtCodePrefix.text
                            amount:amount
                        expiration:expiration
                            bucket:@"default"
                         usageType:[self retrieveUsageTypeForSegment]
                    rewardLocation:[self retrieveRewardLocationForSegment]
                          callback:^(NSDictionary *params, NSError *error) {
                              if (!error) {
                                  self.txtCodeResult.text = [params objectForKey:@"promo_code"];
                              } else {
                                  NSLog(@"Error in getting promo code: %@", error.localizedDescription);
                                  self.txtCodeResult.text = @"Failed to get promo code";
                              }
                          }
     ];
}

- (BranchPromoCodeUsageType)retrieveUsageTypeForSegment {
    switch (self.segCodeFreq.selectedSegmentIndex) {
        case 1:
            return BranchPromoCodeUsageTypeOncePerUser;
        case 0:
        default:
            return BranchPromoCodeUsageTypeUnlimitedUses;
    }
}

- (BranchPromoCodeRewardLocation)retrieveRewardLocationForSegment {
    switch (self.segCodeLocation.selectedSegmentIndex) {
        case 0:
            return BranchPromoCodeRewardReferredUser;
        case 2:
            return BranchPromoCodeRewardBothUsers;
        case 1:
        default:
            return BranchPromoCodeRewardReferringUser;
    }
}

- (IBAction)cmdValidateCode:(UIButton *)sender {
    self.lblCodeValidation.text = nil;
    if (self.txtCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch validatePromoCode:self.txtCodeResult.text callback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                if ([self.txtCodeResult.text isEqualToString:[params objectForKey:@"promo_code"]]) {
                    self.lblCodeValidation.text = @"Valid";
                } else {
                    self.lblCodeValidation.text = @"Invalid!";
                }
            } else {
                NSLog(@"Error in validating promo code: %@", error.localizedDescription);
                self.lblCodeValidation.text = @"promo!";
            }
        }];
    }
}

- (IBAction)cmdApplyCode:(UIButton *)sender {
    if (self.txtCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch applyPromoCode:self.txtCodeResult.text callback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                self.lblCodeValidation.text = @"Applied";
            } else {
                NSLog(@"Error in apply promo code: %@", error.localizedDescription);
                self.lblCodeValidation.text = @"Failed!";
            }
        }];
    }
}

- (void)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.txtCodeResult isFirstResponder] && [touch view] != self.txtCodeResult) {
        [self.txtCodeResult resignFirstResponder];
    }
    if ([self.txtCodePrefix isFirstResponder] && [touch view] != self.txtCodePrefix) {
        [self.txtCodePrefix resignFirstResponder];
    }
    if ([self.txtCodeExpiration isFirstResponder] && [touch view] != self.txtCodeExpiration) {
        [self.txtCodeExpiration resignFirstResponder];
    }
    if ([self.txtCodeAmount isFirstResponder] && [touch view] != self.txtCodeAmount) {
        [self.txtCodeAmount resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}



@end

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

@end

@implementation ReferralCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.txtReferralCodeResult.text = nil;
    self.lblReferralCodeValidation.text = nil;
    self.lblReferralCodeApplication.text = nil;
}

- (IBAction)cmdGetReferralCode:(UIButton *)sender {
    self.txtReferralCodeResult.text = nil;
    Branch *branch = [Branch getInstance];
    [branch getReferralCodeWithPrefix:self.txtReferralCodePrefix.text
                      calculationType:self.segReferralCodeFreq.selectedSegmentIndex
                             location:self.segReferralCodeLocation.selectedSegmentIndex
                             metadata:[NSDictionary dictionaryWithObjects:@[@"default", [NSNumber numberWithInt:5]] forKeys:@[@"bucket", @"amount"]]
                          andCallback:^(NSDictionary *params, NSError *error) {
                              if (!error) {
                                  self.txtReferralCodeResult.text = [params objectForKey:@"referral_code"];
                              } else {
                                  NSLog(@"Error in getting credit history: %@", error.localizedDescription);
                                  self.txtReferralCodeResult.text = error.localizedDescription;
                              }
                          }
     ];
}

- (IBAction)cmdValidateReferralCode:(UIButton *)sender {
    self.lblReferralCodeValidation.text = nil;
    if (self.txtReferralCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch getReferralCode:self.txtReferralCodeResult.text andCallback:^(NSDictionary *params, NSError *error) {
            if (!error) {
                if ([self.txtReferralCodeResult.text isEqualToString:[params objectForKey:@"referral_code"]]) {
                    self.lblReferralCodeValidation.text = @"Referral code is valid";
                } else {
                    self.lblReferralCodeValidation.text = @"Referral code is not valid!";
                }
            } else {
                NSLog(@"Error in getting credit history: %@", error.localizedDescription);
                self.lblReferralCodeValidation.text = error.localizedDescription;
            }
        }];
    }
}

- (IBAction)cmdApplyReferralCode:(UIButton *)sender {
    if (self.txtReferralCodeResult.text.length > 0) {
        Branch *branch = [Branch getInstance];
        [branch applyReferralCode:self.txtReferralCodeResult.text];
    }
}

@end

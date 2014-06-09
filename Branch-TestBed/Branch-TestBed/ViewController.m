//
//  ViewController.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *editRefShortUrl;
@property (weak, nonatomic) IBOutlet UITextField *editRefUrl;
@property (weak, nonatomic) IBOutlet UILabel *txtInstallCount;
@property (weak, nonatomic) IBOutlet UILabel *txtInstallCredits;
@property (weak, nonatomic) IBOutlet UILabel *txtBuyCount;
@property (weak, nonatomic) IBOutlet UILabel *txtBuyCredits;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    Branch *branch = [Branch getInstance:@"key"];
    [branch initUserSessionWithCallback:^(NSDictionary *params) {
        NSLog(@"finished init with params = %@", [params description]);
    }];
}

- (IBAction)cmdRefresh:(id)sender {
    [self.editRefUrl setText:[[Branch getInstance] getLongURL]];
}

- (IBAction)cmdRefreshShort:(id)sender {
    [[Branch getInstance] getShortURLWithCallback:^(NSString *url) {
        [self.editRefShortUrl setText:url];
    }];
}

- (IBAction)cmdRefreshPoints:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadPointsWithCallback:^{
        NSLog(@"load points callback, balance install = %d, balance buy = %d", [branch getBalanceOfPointsForAction:@"install"], [branch getBalanceOfPointsForAction:@"buy"]);
        [self.txtInstallCount setText:[NSString stringWithFormat:@"%d",[branch getTotalPointsForAction:@"install"]]];
        [self.txtInstallCredits setText:[NSString stringWithFormat:@"%d",[branch getCreditsForAction:@"install"]]];
        [self.txtBuyCount setText:[NSString stringWithFormat:@"%d",[branch getTotalPointsForAction:@"buy"]]];
        [self.txtBuyCredits setText:[NSString stringWithFormat:@"%d",[branch getCreditsForAction:@"buy"]]];
    }];
}

- (IBAction)cmdCreditInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch creditUserForReferralAction:@"install" withCredits:1];
}
- (IBAction)cmdCreditBuy:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch creditUserForReferralAction:@"buy" withCredits:1];
}
- (IBAction)cmdExecuteBuy:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy"];
}

@end

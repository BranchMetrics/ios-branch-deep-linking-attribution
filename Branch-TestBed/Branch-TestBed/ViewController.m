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
    Branch *branch = [Branch getInstance:@"5680621892404085"];
    [branch initUserSessionWithCallback:^(NSDictionary *params) {
        NSLog(@"finished init with params = %@", [params description]);
    }];
}

- (IBAction)cmdRefresh:(id)sender {
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!"] forKeys:@[@"key1", @"key2"]];
    [self.editRefUrl setText:[[Branch getInstance] getLongURLWithParams:params andTag:@"test_tag"]];
}

- (IBAction)cmdRefreshShort:(id)sender {
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!"] forKeys:@[@"key1", @"key2"]];
    [[Branch getInstance] getShortURLWithParams:params andCallback:^(NSString *url) {
        [self.editRefShortUrl setText:url];
    }];
}

- (IBAction)cmdRefreshPoints:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadPointsWithCallback:^(BOOL changed){
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
- (IBAction)cmdIdentifyUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch identifyUser:@"my_really_special_user"];
}
- (IBAction)cmdClearUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch clearUser];
}
- (IBAction)cmdPrintInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getInstallReferringParams] description]);
}

@end

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
@property (weak, nonatomic) IBOutlet UILabel *txtRewardCredits;
@property (weak, nonatomic) IBOutlet UILabel *txtInstallTotal;
@property (weak, nonatomic) IBOutlet UILabel *txtInstallUniques;
@property (weak, nonatomic) IBOutlet UILabel *txtBuyCount;
@property (weak, nonatomic) IBOutlet UILabel *txtBuyUniques;


@end

@implementation ViewController


- (IBAction)cmdRefresh:(id)sender {
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!"] forKeys:@[@"key1", @"key2"]];
    [self.editRefUrl setText:[[Branch getInstance] getLongURLWithParams:params andTag:@"test_tag"]];
}

- (IBAction)cmdRefreshShort:(id)sender {
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!"] forKeys:@[@"key1", @"key2"]];
    [[Branch getInstance] getShortURLWithParams:params andTags:@[@"tag1", @"tag2"] andChannel:@"facebook" andFeature:@"invite" andStage:@"2" andCallback:^(NSString *url) {
        [self.editRefShortUrl setText:url];
    }];
}
- (IBAction)cmdRefreshPoints:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadActionCountsWithCallback:^(BOOL changed){
        NSLog(@"load points callback, balance install = %d, balance buy = %d", [branch getTotalCountsForAction:@"install"], [branch getTotalCountsForAction:@"buy"]);
        [self.txtInstallTotal setText:[NSString stringWithFormat:@"%d",[branch getTotalCountsForAction:@"install"]]];
        [self.txtInstallUniques setText:[NSString stringWithFormat:@"%d",[branch getUniqueCountsForAction:@"install"]]];
        [self.txtBuyCount setText:[NSString stringWithFormat:@"%d",[branch getTotalCountsForAction:@"buy"]]];
        [self.txtBuyUniques setText:[NSString stringWithFormat:@"%d",[branch getUniqueCountsForAction:@"buy"]]];
    }];
}

- (IBAction)cmdRefreshRewards:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed) {
        [self.txtRewardCredits setText:[NSString stringWithFormat:@"%d", [branch getCredits]]];
    }];
}
- (IBAction)cmdRedeemFive:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch redeemRewards:5];
}

- (IBAction)cmdExecuteBuy:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy"];
}
- (IBAction)cmdIdentifyUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch identifyUser:@"my_awesome_special_user"];
}
- (IBAction)cmdClearUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch clearUser];
}
- (IBAction)cmdPrintInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getInstallReferringParams] description]);
    [self.editRefUrl setText:[[branch getReferringParams] description]];
}
- (IBAction)cmdBuyWithState:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:[[NSDictionary alloc] initWithObjects:@[@"Alex", [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], [NSNumber numberWithFloat:0.01240123],@"hello"] forKeys:@[@"name",@"integer",@"boolean",@"float",@"test_key"]]];
}

@end

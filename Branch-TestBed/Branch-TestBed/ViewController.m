//
//  ViewController.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "ViewController.h"
#import "CreditHistoryViewController.h"

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
    [self.editRefUrl setText:[[Branch getInstance] getLongURLWithParams:params]];
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
        NSLog(@"load points callback, balance install = %ld, balance buy = %ld", (long)[branch getTotalCountsForAction:@"install"], (long)[branch getTotalCountsForAction:@"buy"]);
        [self.txtInstallTotal setText:[NSString stringWithFormat:@"%ld",(long)[branch getTotalCountsForAction:@"install"]]];
        [self.txtInstallUniques setText:[NSString stringWithFormat:@"%ld",(long)[branch getUniqueCountsForAction:@"install"]]];
        [self.txtBuyCount setText:[NSString stringWithFormat:@"%ld",(long)[branch getTotalCountsForAction:@"buy"]]];
        [self.txtBuyUniques setText:[NSString stringWithFormat:@"%ld",(long)[branch getUniqueCountsForAction:@"buy"]]];
    }];
}

- (IBAction)cmdRefreshRewards:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed) {
        [self.txtRewardCredits setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
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
    [branch identifyUser:@"test_user_1"];
}
- (IBAction)cmdClearUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch clearUser];
}
- (IBAction)cmdPrintInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getInstallReferringParams] description]);
}
- (IBAction)cmdBuyWithState:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:[[NSDictionary alloc] initWithObjects:@[@"Alex", [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], [NSNumber numberWithFloat:0.01240123],@"hello"] forKeys:@[@"name",@"integer",@"boolean",@"float",@"test_key"]]];
}
- (IBAction)cmdGetCreditHistory:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch getCreditHistoryWithCallback:^(NSArray *creditHistory) {
        [self performSegueWithIdentifier:@"ShowCreditHistory" sender:creditHistory];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCreditHistory"]) {
        ((CreditHistoryViewController *)segue.destinationViewController).creditTransactions = sender;
    }
}

- (void)viewDidLoad {
    self.navigationController.navigationBar.translucent = NO;
    [self.editRefShortUrl addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    
    NSLog(@"===== 1. in view controller's viewDidLoad");
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed) {
        [self.txtRewardCredits setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
    }];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    [super viewWillAppear:animated];
}

- (void)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.editRefShortUrl isFirstResponder] && [touch view] != self.editRefShortUrl) {
        [self.editRefShortUrl resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

@end

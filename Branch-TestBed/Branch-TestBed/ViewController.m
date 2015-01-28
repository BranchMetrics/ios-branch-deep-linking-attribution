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

- (IBAction)cmdRefreshShort:(id)sender {
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!", @"Kindred", @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png"] forKeys:@[@"key1", @"key2", @"$og_title", @"$og_image_url"]];
    [[Branch getInstance] getShortURLWithParams:params andTags:@[@"tag1", @"tag2"] andChannel:@"facebook" andFeature:@"invite" andStage:@"2" andCallback:^(NSString *url, NSError *err) {
        [self.editRefShortUrl setText:url];
    }];
}
- (IBAction)cmdRefreshPoints:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadActionCountsWithCallback:^(BOOL changed, NSError *err){
        if (!err) {
            NSLog(@"load points callback, balance install = %ld, balance buy = %ld", (long)[branch getTotalCountsForAction:@"install"], (long)[branch getTotalCountsForAction:@"buy"]);
            [self.txtInstallTotal setText:[NSString stringWithFormat:@"%ld",(long)[branch getTotalCountsForAction:@"install"]]];
            [self.txtInstallUniques setText:[NSString stringWithFormat:@"%ld",(long)[branch getUniqueCountsForAction:@"install"]]];
            [self.txtBuyCount setText:[NSString stringWithFormat:@"%ld",(long)[branch getTotalCountsForAction:@"buy"]]];
            [self.txtBuyUniques setText:[NSString stringWithFormat:@"%ld",(long)[branch getUniqueCountsForAction:@"buy"]]];
        }
    }];
}

- (IBAction)cmdRefreshRewards:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *err) {
        if (!err) {
            [self.txtRewardCredits setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
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
    [branch setIdentity:@"test_user_10"];
}
- (IBAction)cmdClearUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch logout];
    
    self.txtBuyCount.text = @"";
    self.txtBuyUniques.text = @"";
    self.txtInstallTotal.text = @"";
    self.txtInstallUniques.text = @"";
    self.txtRewardCredits.text = @"";
}
- (IBAction)cmdPrintInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getFirstReferringParams] description]);
}
- (IBAction)cmdBuyWithState:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:[[NSDictionary alloc] initWithObjects:@[@"Alex", [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], [NSNumber numberWithFloat:0.01240123],@"hello"] forKeys:@[@"name",@"integer",@"boolean",@"float",@"test_key"]]];
}
- (IBAction)cmdGetCreditHistory:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch getCreditHistoryWithCallback:^(NSArray *creditHistory, NSError *err) {
        if (!err) {
            [self performSegueWithIdentifier:@"ShowCreditHistory" sender:creditHistory];
        } else {
            NSLog(@"Error in getting credit history: %@", err.localizedDescription);
        }
    }];
}

// Share Sheet example

- (IBAction)cmdShareSheet:(id)sender {
    NSString *shareString = @"Super amazing thing I want to share!";
    
    NSDictionary*params = [[NSDictionary alloc] initWithObjects:@[@"test_object", @"here is another object!!", @"Kindred", @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png"] forKeys:@[@"key1", @"key2", @"$og_title", @"$og_image_url"]];
    
    UIActivityItemProvider *itemProvider = [Branch getBranchActivityItemWithURL:@"http://lmgtfy.com/?q=branch+metrics" andParams:params andTags:@[@"tag1", @"tag2"] andFeature:@"invite" andStage:@"2" andAlias:@"test-alias"];
    
    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareString, itemProvider] applicationActivities:nil];
    
    [self.navigationController presentViewController:shareViewController animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCreditHistory"]) {
        ((CreditHistoryViewController *)segue.destinationViewController).creditTransactions = sender;
    }
}

- (void)viewDidLoad {
    self.navigationController.navigationBar.translucent = NO;
    [self.editRefShortUrl addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
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

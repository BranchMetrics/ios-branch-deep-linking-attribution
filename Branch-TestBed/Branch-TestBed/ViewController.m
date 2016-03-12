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
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIButton *refreshUrlButton;
@property (weak, nonatomic) IBOutlet UITextField *editRefShortUrl;
@property (weak, nonatomic) IBOutlet UILabel *txtRewardCredits;

@property (strong, nonatomic) BranchUniversalObject *branchUniversalObject;

@end

@implementation ViewController

- (void)viewDidLoad {
    self.navigationController.navigationBar.translucent = NO;
    [self.editRefShortUrl addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
    
    self.branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"item/12345"];
    self.branchUniversalObject.title = @"My Content Title";
    self.branchUniversalObject.contentDescription = @"My Content Description";
    self.branchUniversalObject.imageUrl = @"https://s3-us-west-1.amazonaws.com/branchhost/mosaic_og.png";
    [self.branchUniversalObject addMetadataKey:@"custom_key1" value:@"some custom data"];
    [self.branchUniversalObject addMetadataKey:@"custom_key2" value:@"more custom data"];
}

- (IBAction)cmdRefreshShort:(id)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"sharing";
    linkProperties.channel = @"facebook";
    [linkProperties addControlParam:@"$desktop_url" withValue:@"http://example.com/home"];
    [linkProperties addControlParam:@"$ios_url" withValue:@"http://example.com/ios"];
    
    [self.branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *err) {
        [self.editRefShortUrl setText:url];
    }];
}

- (IBAction)cmdShareLink:(id)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = @"sharing";
    [linkProperties addControlParam:@"$desktop_url" withValue:@"http://example.com/home"];
    [linkProperties addControlParam:@"$ios_url" withValue:@"http://example.com/ios"];

    
    [self.branchUniversalObject
     showShareSheetWithShareText:@"Super amazing thing I want to share"
     completion:^(NSString *activityType, BOOL completed) {
         if (completed) {
             NSLog(@"%@", [NSString stringWithFormat:@"Completed sharing to %@", activityType]);
         }
    }];
}
- (IBAction)cmdRegisterView:(id)sender {
    [self.branchUniversalObject registerView];
}

- (IBAction)cmdIndexSpotlight:(id)sender {
    [self.branchUniversalObject listOnSpotlightWithCallback:^(NSString *url, NSError *error) {
        if (!error) {
            NSLog(@"shortURL: %@", url);
        } else {
            NSLog(@"error: %@", error);
        }
    }];
}

//example using callbackWithURLandSpotlightIdentifier
- (IBAction)cmdIndexSpotlightWithIdentifier:(id)sender {
    [self.branchUniversalObject listOnSpotlightWithIdentifierCallback:^(NSString *url, NSString *spotlightIdentifier,  NSError *error) {
        if (!error) {
            NSLog(@"shortURL: %@   spotlight ID: %@", url, spotlightIdentifier);
        } else {
            NSLog(@"error: %@", error);
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
    [branch redeemRewards:5 callback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            NSLog(@"didn't redeem anything: %@", error);
        }
        else {
            NSLog(@"redeemed 5 credits!");

            [self.txtRewardCredits setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
    }];
}

- (IBAction)cmdExecuteBuy:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:nil withDelegate:self];
}
- (IBAction)cmdIdentifyUserClick:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch setIdentity:@"test_user_10"];
}
- (IBAction)logoutWithCallback {
  Branch *branch = [Branch getInstance];
  [branch logoutWithCallback:^(BOOL changed, NSError *error) {
    if (error || !changed) {
      NSLog(@"logout failed: %@", error);
    } else {
      NSLog(@"logout");
    }
  }];

  self.txtRewardCredits.text = @"";
}

- (IBAction)cmdPrintInstall:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getFirstReferringParams] description]);
}

- (IBAction)cmdSessionParams:(id)sender {
    Branch *branch = [Branch getInstance];
    NSLog(@"found params = %@", [[branch getLatestReferringParams] description]);
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCreditHistory"]) {
        ((CreditHistoryViewController *)segue.destinationViewController).creditTransactions = sender;
    }
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

- (void)branchViewVisible: (NSString *)actionName {
     NSLog(@"branchViewVisible for action : %@", actionName);
}
- (void)branchViewAccepted: (NSString *)actionName {
     NSLog(@"branchViewAccepted for action : %@", actionName);
}
- (void)branchViewCancelled: (NSString *)actionName {
     NSLog(@"branchViewCancelled for action : %@", actionName);
}



@end

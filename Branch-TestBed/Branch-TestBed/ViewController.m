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
#import "LogOutputViewController.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

NSString *cononicalIdentifier = @"item/12345";
NSString *canonicalUrl = @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/";
NSString *contentTitle = @"Content Title";
NSString *contentDescription = @"My Content Description";
NSString *imageUrl = @"https://pbs.twimg.com/profile_images/658759610220703744/IO1HUADP.png";
NSString *feature = @"Sharing Feature";
NSString *channel = @"Distribution Channel";
NSString *desktop_url = @"http://branch.io";
NSString *ios_url = @"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/";
NSString *shareText = @"Super amazing thing I want to share";
NSString *user_id1 = @"abe@emailaddress.io";
NSString *user_id2 = @"ben@emailaddress.io";
NSString *live_key = @"live_key";
NSString *test_key = @"test_key";
NSString *type = @"some type";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *branchLinkTextField;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) BranchUniversalObject *branchUniversalObject;

@end


@implementation ViewController


- (void)viewDidLoad {
    [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
    [self.branchLinkTextField addTarget:self action:@selector(textFieldFinished:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    _branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier: cononicalIdentifier];
    _branchUniversalObject.canonicalUrl = canonicalUrl;
    _branchUniversalObject.title = contentTitle;
    _branchUniversalObject.contentDescription = contentDescription;
    _branchUniversalObject.imageUrl = imageUrl;
    _branchUniversalObject.price = 1000;
    _branchUniversalObject.currency = @"$";
    _branchUniversalObject.type = type;
    [_branchUniversalObject addMetadataKey:@"deeplink_text" value:[NSString stringWithFormat:
                                                                   @"This text was embedded as data in a Branch link with the following characteristics:\n\n  canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n", canonicalUrl, contentTitle, contentDescription, imageUrl]];
    [self refreshRewardPoints];
}


- (IBAction)createBranchLinkButtonTouchUpInside:(id)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.campaign = @"some campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    
    [self.branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
        [self.branchLinkTextField setText:url];
    }];
}


- (IBAction)redeemFivePointsButtonTouchUpInside:(id)sender {
    _pointsLabel.hidden = YES;
    [_activityIndicator startAnimating];
    
    Branch *branch = [Branch getInstance];
    [branch redeemRewards:5 callback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            NSLog(@"Branch TestBed: Didn't redeem anything: %@", error);
            [self showAlert:@"Redemption Unsuccessful" withDescription:error.localizedDescription];
        } else {
            NSLog(@"Branch TestBed: Five Points Redeemed!");
            [_pointsLabel setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
        _pointsLabel.hidden = NO;
        [_activityIndicator stopAnimating];
    }];
}


- (IBAction)setUserIDButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch setIdentity: user_id2 withCallback:^(NSDictionary *params, NSError *error) {
        if (!error) {
            NSLog(@"Branch TestBed: Identity Successfully Set%@", params);
            [self performSegueWithIdentifier:@"ShowLogOutput" sender:[NSString stringWithFormat:@"Identity set to: %@\n\n%@", user_id2, params.description]];
        } else {
            NSLog(@"Branch TestBed: Error setting identity: %@", error);
            [self showAlert:@"Unable to Set Identity" withDescription:error.localizedDescription];
        }
    }];
}


- (IBAction)refreshRewardsButtonTouchUpInside:(id)sender {
    [self refreshRewardPoints];
}


- (IBAction)logoutWithCallback {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            NSLog(@"Branch TestBed: Logout failed: %@", error);
            [self showAlert:@"Error simulating logout" withDescription:error.localizedDescription];
        } else {
            NSLog(@"Branch TestBed: Logout");
            [self showAlert:@"Logout succeeded" withDescription:@""];
            [self refreshRewardPoints];
        }
    }];
    
}


- (IBAction)sendBuyEventButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:nil withDelegate:self];
    [self refreshRewardPoints];
    [self showAlert:@"'buy' event dispatched" withDescription:@""];
}


- (IBAction)sendComplexEventButtonTouchUpInside:(id)sender {
    NSDictionary *eventDetails = [[NSDictionary alloc] initWithObjects:@[user_id1, [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], [NSNumber numberWithFloat:3.14159265359], test_key] forKeys:@[@"name",@"integer",@"boolean",@"float",@"test_key"]];
    
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"buy" withState:eventDetails];
    [self performSegueWithIdentifier:@"ShowLogOutput" sender:[NSString stringWithFormat:@"Custom Event Details:\n\n%@", eventDetails.description]];
    [self refreshRewardPoints];
}


- (IBAction)getCreditHistoryButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch getCreditHistoryWithCallback:^(NSArray *creditHistory, NSError *error) {
        if (!error) {
            [self performSegueWithIdentifier:@"ShowCreditHistory" sender:creditHistory];
        } else {
            NSLog(@"Branch TestBed: Error retrieving credit history: %@", error.localizedDescription);
            [self showAlert:@"Error retrieving credit history" withDescription:error.localizedDescription];
        }
    }];
}

- (IBAction)viewFirstReferringParamsButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [self performSegueWithIdentifier:@"ShowLogOutput" sender:[[branch getFirstReferringParams] description]];
    NSLog(@"Branch TestBed: FirstReferringParams:\n%@", [[branch getFirstReferringParams] description]);
}


- (IBAction)viewLatestReferringParamsButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [self performSegueWithIdentifier:@"ShowLogOutput" sender:[[branch getLatestReferringParams] description]];
    NSLog(@"Branch TestBed: LatestReferringParams:\n%@", [[branch getLatestReferringParams] description]);
}


- (IBAction)simulateContentAccessButtonTouchUpInsideButtonTouchUpInside:(id)sender {
    [self.branchUniversalObject registerView];
    [self showAlert:@"Content Access Registered" withDescription:@""];
}


- (IBAction)shareLinkButtonTouchUpInside:(id)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    
    [self.branchUniversalObject showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:self.parentViewController completion:^(NSString *activityType, BOOL completed) {
        if (completed) {
            NSLog(@"%@", [NSString stringWithFormat:@"Branch TestBed: Completed sharing to %@", activityType]);
        } else {
            NSLog(@"%@", [NSString stringWithFormat:@"Branch TestBed: Sharing failed"]);
        }
    }];
}


//example using callbackWithURLandSpotlightIdentifier
- (IBAction)registerWithSpotlightButtonTouchUpInside:(id)sender {
    [self.branchUniversalObject addMetadataKey:@"deeplink_text" value:@"This link was generated for Spotlight registration"];
    self.branchUniversalObject.automaticallyListOnSpotlight = YES;
    [self.branchUniversalObject userCompletedAction:BNCRegisterViewEvent];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowCreditHistory"]) {
        ((CreditHistoryViewController *)segue.destinationViewController).creditTransactions = sender;
    } else if ([segue.identifier isEqualToString:@"ShowLogOutput"]) {
        ((LogOutputViewController *)segue.destinationViewController).logOutput = sender;
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshRewardPoints];
}


- (void)textFieldFinished:(id)sender {
    [sender resignFirstResponder];
}


- (void)hideKeyboard {
    if ([self.branchLinkTextField isFirstResponder]) {
        [self.branchLinkTextField resignFirstResponder];
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.branchLinkTextField isFirstResponder] && [touch view] != self.branchLinkTextField) {
        [self.branchLinkTextField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}


- (void)branchViewVisible: (NSString *)actionName withID:(NSString *)branchViewID {
    NSLog(@"Branch TestBed: branchViewVisible for action : %@ %@", actionName, branchViewID);
}


- (void)branchViewAccepted: (NSString *)actionName withID:(NSString *)branchViewID {
    NSLog(@"Branch TestBed: branchViewAccepted for action : %@ %@", actionName, branchViewID);
}


- (void)branchViewCancelled: (NSString *)actionName withID:(NSString *)branchViewID {
    NSLog(@"Branch TestBed: branchViewCancelled for action : %@ %@", actionName, branchViewID);
}

- (void)refreshRewardPoints {
    _pointsLabel.hidden = YES;
    [_activityIndicator startAnimating];
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        if (!error) {
            [_pointsLabel setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
        [_activityIndicator stopAnimating];
        _pointsLabel.hidden = NO;
    }];
}


- (void)showAlert: (NSString *)title withDescription:(NSString *) message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

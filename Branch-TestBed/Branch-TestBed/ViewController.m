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

@interface ViewController () <BranchShareLinkDelegate> {
    NSDateFormatter *_dateFormatter;
}

@property (weak, nonatomic) IBOutlet UITextField *branchLinkTextField;
@property (weak, nonatomic) IBOutlet UILabel *pointsLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) BranchUniversalObject *branchUniversalObject;

@end


@implementation ViewController


- (void)viewDidLoad {
    [[UITableViewCell appearance] setBackgroundColor:[UIColor clearColor]];
    [self.branchLinkTextField
        addTarget:self
        action:@selector(textFieldFinished:)
        forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    _branchUniversalObject =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier: cononicalIdentifier];
    _branchUniversalObject.canonicalUrl = canonicalUrl;
    _branchUniversalObject.title = contentTitle;
    _branchUniversalObject.contentDescription = contentDescription;
    _branchUniversalObject.imageUrl = imageUrl;
    _branchUniversalObject.price = 1000;
    _branchUniversalObject.currency = @"$";
    _branchUniversalObject.type = type;
    [_branchUniversalObject
        addMetadataKey:@"deeplink_text"
        value:[NSString stringWithFormat:
            @"This text was embedded as data in a Branch link with the following characteristics:\n\n"
             "canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n",
                canonicalUrl, contentTitle, contentDescription, imageUrl]];

    self.versionLabel.text =
        [NSString stringWithFormat:@"v %@ / %@ / %@",
            [UIDevice currentDevice].systemVersion,
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            BNC_SDK_VERSION];
    [self.versionLabel sizeToFit];

   // [self refreshRewardPoints];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSLog(@"Branch TestBed: Identity Successfully Set%@", params);
                [self performSegueWithIdentifier:@"ShowLogOutput"
                    sender:[NSString stringWithFormat:@"Identity set to: %@\n\n%@",
                        user_id2, params.description]];
            } else {
                NSLog(@"Branch TestBed: Error setting identity: %@", error);
                [self showAlert:@"Unable to Set Identity" withDescription:error.localizedDescription];
            }
        });
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


- (IBAction)sendButtonEventButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"button_press"
        withState:@{ @"name": @"button1", @"action": @"alert" }
        withDelegate:self];
    [self refreshRewardPoints];
    [self showAlert:@"'button_press' event dispatched" withDescription:@""];
}


- (IBAction)sendComplexEventButtonTouchUpInside:(id)sender {
    NSDictionary *eventDetails = [[NSDictionary alloc] initWithObjects:@[user_id1, [NSNumber numberWithInt:1], [NSNumber numberWithBool:YES], [NSNumber numberWithFloat:3.14159265359], test_key] forKeys:@[@"name",@"integer",@"boolean",@"float",@"test_key"]];
    
    Branch *branch = [Branch getInstance];
    [branch userCompletedAction:@"complex_event" withState:eventDetails];
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

- (NSDateFormatter*) dateFormatter {
    if (_dateFormatter) return _dateFormatter;

    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssX";
    _dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return _dateFormatter;
}

#pragma mark - Share a Branch Link

- (IBAction)oldShareLinkButtonTouchUpInside:(id)sender {
    // This method uses the old way of sharing Branch links.

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"

    [self.branchUniversalObject showShareSheetWithLinkProperties:linkProperties
        andShareText:shareText
        fromViewController:self.parentViewController
        completion:^(NSString *activityType, BOOL completed) {
            if (completed) {
                NSLog(@"Branch TestBed: Completed sharing to %@", activityType);
            } else {
                NSLog(@"Branch TestBed: Sharing failed");
            }
        }
    ];

    #pragma clang diagnostic pop
}

- (IBAction)shareLinkButtonTouchUpInside:(id)sender {
    // The new hotness.

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];

    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.branchUniversalObject
            linkProperties:linkProperties];

    shareLink.title = @"Share your test link!";
    shareLink.delegate = self;
    shareLink.shareText = [NSString stringWithFormat:
        @"Shared from Branch's Branch-TestBed at %@.",
        [self.dateFormatter stringFromDate:[NSDate date]]];

    [shareLink presentActivityViewControllerFromViewController:self anchor:nil];
}

- (IBAction)shareLinkAsActivityItem:(id)sender {
    // Share as an activity item. Doesn't receive all share started / completed events.

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];

    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.branchUniversalObject
            linkProperties:linkProperties];

    shareLink.title = @"Share your test link!";
    shareLink.delegate = self;
    shareLink.shareText = [NSString stringWithFormat:
        @"Shared from Branch's Branch-TestBed at %@.",
        [self.dateFormatter stringFromDate:[NSDate date]]];

    UIActivityViewController *activityController =
        [[UIActivityViewController alloc]
            initWithActivityItems:shareLink.activityItems
            applicationActivities:nil];

    if (activityController) {
        [self presentViewController:activityController animated:YES completion:nil];
    }
}

- (void) branchShareLinkWillShare:(BranchShareLink*)shareLink {
    // This delegate example shows changing the share text.
    //
    // Link properties, such as alias or channel can be overridden here based on the users'
    // choice stored in shareSheet.activityType.

    shareLink.shareText = [NSString stringWithFormat:
        @"Shared through '%@'\nfrom Branch's Branch-TestBed\nat %@.",
        shareLink.linkProperties.channel,
        [self.dateFormatter stringFromDate:[NSDate date]]];
}

- (void) branchShareLink:(BranchShareLink*)shareLink
             didComplete:(BOOL)completed
               withError:(NSError*)error {

    if (error != nil) {
        NSLog(@"Branch: Error while sharing! Error: %@.", error);
    } else if (completed) {
        NSLog(@"Branch: User completed sharing to channel '%@'.", shareLink.linkProperties.channel);
    } else {
        NSLog(@"Branch: User cancelled sharing.");
    }
}

#pragma mark - Commerce Events

- (IBAction) openBranchLinkInApp:(id)sender {
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    // TODO: Remove
    // NSURL *URL = [NSURL URLWithString:@"https://bnc.lt/ZPOc/Y6aKU0rzcy"]; // <= Your URL goes here.
    NSURL *URL = [NSURL URLWithString:@"https://bnctestbed.app.link/izPBY2xCqF"];
    activity.webpageURL = URL;
    Branch *branch = [Branch getInstance];
    [branch resetUserSession];
    [branch continueUserActivity:activity];
}

- (IBAction) sendCommerceEvent:(id)sender {
    BNCProduct *product = [BNCProduct new];
    product.price = [NSDecimalNumber decimalNumberWithString:@"1000.99"];
    product.sku = @"acme007";
    product.name = @"Acme brand 1 ton weight";
    product.quantity = @(1.0);
    product.brand = @"Acme";
    product.category = BNCProductCategoryMedia;
    product.variant = @"Lite Weight";

    BNCCommerceEvent *commerceEvent = [BNCCommerceEvent new];
    commerceEvent.revenue = [NSDecimalNumber decimalNumberWithString:@"1101.99"];
    commerceEvent.currency = @"USD";
    commerceEvent.transactionID = @"tr00x8";
    commerceEvent.shipping = [NSDecimalNumber decimalNumberWithString:@"100.00"];
    commerceEvent.tax = [NSDecimalNumber decimalNumberWithString:@"1.00"];
    commerceEvent.coupon = @"Acme weights coupon";
    commerceEvent.affiliation = @"ACME by Amazon";
    commerceEvent.products = @[ product ];

    [[Branch getInstance]
        sendCommerceEvent:commerceEvent
        metadata:@{ @"Meta": @"Never meta dog I didn't like." }
        withCompletion:
        ^ (NSDictionary *response, NSError *error) {
			NSString *message =
				[NSString stringWithFormat:@"Commerce completion called.\nError: %@\n%@", error, response];
			NSLog(@"%@", message);
			[[[UIAlertView alloc]
				initWithTitle:@"Commerce Event"
				message:message
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil]
					show];
        }];
}

#pragma mark - Spotlight

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

static inline void BNCPerformBlockOnMainThread(void (^ block)(void)) {
    if ([NSThread currentThread] == [NSThread mainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)showAlert: (NSString *)title withDescription:(NSString *) message {

    BNCPerformBlockOnMainThread(^ {

        if ([UIDevice currentDevice].systemVersion.floatValue < 8.0) {

            UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:title
                message:message
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
            [alert show];

        } else {

            UIAlertController* alert = [UIAlertController
                alertControllerWithTitle:title
                message:message
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                style:UIAlertActionStyleCancel
                handler:nil]];
            [self presentViewController:alert
                animated:YES
                completion:nil];
                
        }
    });
}

@end

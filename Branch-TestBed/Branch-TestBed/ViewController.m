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
#import "ArrayPickerView.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"

static NSString *cononicalIdentifier = @"item/12346";
static NSString *canonicalUrl = @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/";
static NSString *contentTitle = @"Branch 0.19 TestBed Content Title";
static NSString *contentDescription = @"My Content Description";
static NSString *imageUrl = @"https://pbs.twimg.com/profile_images/658759610220703744/IO1HUADP.png";
static NSString *feature = @"Sharing Feature";
static NSString *channel = @"Distribution Channel";
static NSString *desktop_url = @"http://branch.io";
static NSString *ios_url = @"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/";
static NSString *shareText = @"Super amazing thing I want to share";
static NSString *user_id1 = @"abe@emailaddress.io";
static NSString *user_id2 = @"ben@emailaddress.io";
static NSString *live_key = @"live_key";
static NSString *test_key = @"test_key";
static NSString *type = @"some type";

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
    _branchUniversalObject.contentMetadata.price = [NSDecimalNumber decimalNumberWithString:@"1000.00"];
    _branchUniversalObject.contentMetadata.currency = BNCCurrencyUSD;
    _branchUniversalObject.contentMetadata.contentSchema = BranchContentSchemaCommerceProduct;
    _branchUniversalObject.contentMetadata.customMetadata[@"deeplink_text"] =
        [NSString stringWithFormat:
            @"This text was embedded as data in a Branch link with the following characteristics:\n\n"
             "canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n",
                canonicalUrl, contentTitle, contentDescription, imageUrl];

    self.versionLabel.text =
        [NSString stringWithFormat:@"v %@ / %@ / %@",
            [UIDevice currentDevice].systemVersion,
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            BNC_SDK_VERSION];
    [self.versionLabel sizeToFit];
    [self.activityIndicator stopAnimating];
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
    self.pointsLabel.hidden = YES;
    [self.activityIndicator startAnimating];
    
    Branch *branch = [Branch getInstance];
    [branch redeemRewards:5 callback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            NSLog(@"Branch TestBed: Didn't redeem anything: %@", error);
            [self showAlert:@"Redemption Unsuccessful" withDescription:error.localizedDescription];
        } else {
            NSLog(@"Branch TestBed: Five Points Redeemed!");
            [self.pointsLabel setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
        self.pointsLabel.hidden = NO;
        [self.activityIndicator stopAnimating];
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
    [linkProperties addControlParam:@"$android_deeplink_path" withValue:@"custom/path/*"];

    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.branchUniversalObject
            linkProperties:linkProperties];

    shareLink.title = @"Share your test link!";
    shareLink.delegate = self;
    shareLink.shareText = [NSString stringWithFormat:
        @"Shared from Branch's Branch-TestBed at %@.",
        [self.dateFormatter stringFromDate:[NSDate date]]];

    [shareLink presentActivityViewControllerFromViewController:self anchor:sender];
}

- (IBAction)shareLinkAsActivityItem:(id)sender {
    // Share as an activity item. Doesn't receive all share started / completed events.

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    [linkProperties addControlParam:@"$android_deeplink_path" withValue:@"custom/path/*"];

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

- (IBAction) openBranchLinkInApp:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"https://bnctestbed.app.link/izPBY2xCqF"];
    [[Branch getInstance] handleDeepLinkWithNewSession:URL];
}

#pragma mark - Commerce Events

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
            [self showAlert:@"Commerce Event" withDescription:message];
        }];
}

- (IBAction) sendV2EventAction:(id)sender {
    NSArray<NSString*> *eventNames = @[

         BranchStandardEventAddToCart
        ,BranchStandardEventAddToWishlist
        ,BranchStandardEventViewCart
        ,BranchStandardEventInitiatePurchase
        ,BranchStandardEventAddPaymentInfo
        ,BranchStandardEventPurchase
        ,BranchStandardEventSpendCredits

        ,BranchStandardEventSearch
        ,BranchStandardEventViewItem
        ,BranchStandardEventViewItems
        ,BranchStandardEventRate
        ,BranchStandardEventShare

        ,BranchStandardEventCompleteRegistration
        ,BranchStandardEventCompleteTutorial
        ,BranchStandardEventAchieveLevel
        ,BranchStandardEventUnlockAchievement
        ,@"iOS-CustomEvent"

    ];

    __weak __typeof(self) weakSelf = self;
    ArrayPickerView *picker = [[ArrayPickerView alloc] initWithArray:eventNames];
    picker.doneButtonTitle = @"Send";
    [picker presentFromViewController:self withCompletion:^ (NSString*pickedString) {
        if (pickedString) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf sendV2EventWithName:pickedString];
        }
    }];
}

- (void) sendV2EventWithName:(NSString*)eventName {
    BranchUniversalObject *buo = [BranchUniversalObject new];

    buo.contentMetadata.contentSchema    = BranchContentSchemaCommerceProduct;
    buo.contentMetadata.quantity         = 2;
    buo.contentMetadata.price            = [NSDecimalNumber decimalNumberWithString:@"23.20"];
    buo.contentMetadata.currency         = BNCCurrencyUSD;
    buo.contentMetadata.sku              = @"1994320302";
    buo.contentMetadata.productName      = @"my_product_name1";
    buo.contentMetadata.productBrand     = @"my_prod_Brand1";
    buo.contentMetadata.productCategory  = BNCProductCategoryBabyToddler;
    buo.contentMetadata.productVariant   = @"3T";
    buo.contentMetadata.condition        = BranchConditionFair;

    buo.contentMetadata.ratingAverage    = 5;
    buo.contentMetadata.ratingCount      = 5;
    buo.contentMetadata.ratingMax        = 7;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (id) @{@"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1"};
    buo.title                       = @"My Content Title";
    buo.canonicalIdentifier         = @"item/12345";
    buo.canonicalUrl                = @"https://branch.io/deepviews";
    buo.keywords                    = @[@"My_Keyword1", @"My_Keyword2"];
    buo.contentDescription          = @"my_product_description1";
    buo.imageUrl                    = @"https://test_img_url";
    buo.expirationDate              = [NSDate dateWithTimeIntervalSince1970:(double)212123232544.0/1000.0];
    buo.publiclyIndex               = NO;
    buo.locallyIndex                = YES;
    buo.creationDate                = [NSDate dateWithTimeIntervalSince1970:(double)1501869445321.0/1000.0];

    BranchEvent *event    = [BranchEvent customEventWithName:eventName];
    event.transactionID   = @"12344555";
    event.currency        = BNCCurrencyUSD;
    event.revenue         = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    event.shipping        = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    event.tax             = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    event.coupon          = @"test_coupon";
    event.affiliation     = @"test_affiliation";
    event.eventDescription= @"Event _description";
    event.customData      = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };
    event.contentItems = (id) @[ buo ];
    [event logEvent];
}

#pragma mark - Spotlight

- (IBAction)registerWithSpotlightButtonTouchUpInside:(id)sender {
    //
    // Example using callbackWithURLandSpotlightIdentifier
    //
    self.branchUniversalObject.contentMetadata.customMetadata[@"deeplink_text"] =
        @"This link was generated for Spotlight registration";
    self.branchUniversalObject.locallyIndex = YES;
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
    self.pointsLabel.hidden = YES;
    [self.activityIndicator startAnimating];
    __weak __typeof(self) weakSelf = self;
    Branch *branch = [Branch getInstance];
    [branch loadRewardsWithCallback:^(BOOL changed, NSError *error) {
        __strong __typeof(self) strongSelf = weakSelf;
        if (!error) {
            [strongSelf.pointsLabel setText:[NSString stringWithFormat:@"%ld", (long)[branch getCredits]]];
        }
        [strongSelf.activityIndicator stopAnimating];
        strongSelf.pointsLabel.hidden = NO;
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

        if ([UIDevice currentDevice].systemVersion.doubleValue < 8.0) {

            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:title
                message:message
                delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
            [alert show];
            #pragma clang diagnostic pop

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

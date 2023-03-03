//
//  ViewController.m
//  Branch-TestBed
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "Branch.h"
#import "BranchEvent.h"
#import "BranchQRCode.h"
#import "BranchConstants.h"
#import "BNCConfig.h"
#import "ViewController.h"
#import "LogOutputViewController.h"
#import "ArrayPickerView.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"
#import "LogOutputViewController.h"
#import "AppDelegate.h"
#import <LinkPresentation/LinkPresentation.h>

extern AppDelegate* appDelegate;

static NSString *cononicalIdentifier = @"item/12346";
static NSString *canonicalUrl = @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/";
static NSString *contentTitle = @"Branch 0.19 TestBed Content Title";
static NSString *contentDescription = @"My Content Description";
static NSString *imageUrl = @"http://www.theweddingplayers.com/wp-content/new_folder/Mr_Wompy_web2.jpg";
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

@interface BranchEvent()
+ (NSArray<BranchStandardEvent>*) standardEvents;
@end

@interface ViewController () <BranchShareLinkDelegate> {
    NSDateFormatter *_dateFormatter;
}

@property (weak, nonatomic) IBOutlet UITextField *branchLinkTextField;
@property (strong, nonatomic) BranchUniversalObject *branchUniversalObject;
@property (copy) void (^completionBlock)(BOOL success, NSError * _Nullable error);
@property (weak, nonatomic) IBOutlet UIButton *disableTrackingButton;
@property (weak, nonatomic) IBOutlet UIButton *setParnerParamsButton;

@end


@implementation ViewController
UIActivityIndicatorView *activityIndicator;
bool hasSetPartnerParams = false;

- (void)viewDidLoad {
    [self.branchLinkTextField
     addTarget:self
     action:@selector(textFieldFinished:)
     forControlEvents:UIControlEventEditingDidEndOnExit];
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    if (@available(iOS 13.0, *)) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    } else {
        activityIndicator = [[UIActivityIndicatorView alloc] init];
    }
    
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
    
    NSMutableArray *barButtonItems = [[NSMutableArray alloc] init];
    
    NSString *version = [NSString stringWithFormat: @"v%@", BNC_SDK_VERSION];
    UIBarButtonItem *versionButton = [[UIBarButtonItem alloc]
                                      initWithTitle:version
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(showVersionAlert:)];
    
    UIBarButtonItem *spinnerButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    [barButtonItems addObject:versionButton];
    [barButtonItems addObject:spinnerButton];
    
    self.navigationItem.rightBarButtonItems = barButtonItems;
    
    __block __weak ViewController *_self = self;
    self.completionBlock = ^(BOOL success, NSError * _Nullable error) {
        UINavigationController *navigationController =
        (UINavigationController *)_self.view.window.rootViewController;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LogOutputViewController *logOutputViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
        [navigationController pushViewController:logOutputViewController animated:YES];
        if (success) {
            logOutputViewController.logOutput = [NSString stringWithFormat:@"\nRESULT: SUCCESS"];
        } else {
            logOutputViewController.logOutput = [NSString stringWithFormat:@"\nRESULT: FAILED\n ERROR: %@", [error description]];
        }
        [appDelegate setLogFile:nil];
    };
    
    if ([Branch trackingDisabled]) {
        [self.disableTrackingButton setTitle:@"Enable Tracking" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.disableTrackingButton setImage:[UIImage systemImageNamed:@"eye.fill"] forState:UIControlStateNormal];
        }
    } else {
        [self.disableTrackingButton setTitle:@"Disable Tracking" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.disableTrackingButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        }
    }
    
    if (hasSetPartnerParams) {
        [self.setParnerParamsButton setTitle:@"Clear Partner Params" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.setParnerParamsButton setImage:[UIImage systemImageNamed:@"folder.badge.minus"] forState:UIControlStateNormal];
        }
    } else {
        [self.setParnerParamsButton setTitle:@"Set Partner Params" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.setParnerParamsButton setImage:[UIImage systemImageNamed:@"folder.badge.plus"] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)goToPasteControlPressed:(id)sender {
    [self performSegueWithIdentifier:@"GoToPasteControlView"
                              sender:self];
}

-(IBAction)showVersionAlert:(id)sender {
    NSString *versionString = [NSString stringWithFormat:@"Branch SDK v%@\nBundle Version %@\niOS %@",
                               BNC_SDK_VERSION,
                               [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                               [UIDevice currentDevice].systemVersion];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Versions" message:versionString preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okayAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okayAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)createBranchLinkButtonTouchUpInside:(id)sender {
    [activityIndicator startAnimating];
    
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.campaign = @"some campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    
    [self.branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
        [self.branchLinkTextField setText:url];
        [activityIndicator stopAnimating];
        
    }];
}

- (IBAction)setUserIDButtonTouchUpInside:(id)sender {
    Branch *branch = [Branch getInstance];
    [appDelegate setLogFile:@"SetUserID"];
    [branch setIdentity: user_id2 withCallback:^(NSDictionary *params, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate setLogFile:nil];
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


- (IBAction)logoutWithCallback {
    Branch *branch = [Branch getInstance];
    [branch logoutWithCallback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            NSLog(@"Branch TestBed: Logout failed: %@", error);
            [self showAlert:@"Error simulating logout" withDescription:error.localizedDescription];
        } else {
            NSLog(@"Branch TestBed: Logout");
            [self showAlert:@"Logout succeeded" withDescription:@""];
        }
    }];
    
}

- (IBAction)sendContentEvent:(id)sender {
    
    __block BranchEvent *event = [BranchEvent alloc];
    
    event.alias = @"my custom alias";
    event.eventDescription = @"Product Search";
    event.searchQuery = @"user search query terms for product xyz";
    event.customData = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose A Content Event" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"View Item" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventViewItem];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged content event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending content event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"View Items" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventViewItems];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged content event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending content event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Search" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventSearch];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged content event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending content event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Rate" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventRate];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged content event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending content event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventShare];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged content event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending content event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"Content Event action sheet dismissed.");
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
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

- (IBAction)shareLinkButtonTouchUpInside:(id)sender {
    // The new hotness.
    [activityIndicator startAnimating];
    
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
    buo.contentMetadata.rating           = 6;
    buo.contentMetadata.addressStreet    = @"Street_name1";
    buo.contentMetadata.addressCity      = @"city1";
    buo.contentMetadata.addressRegion    = @"Region1";
    buo.contentMetadata.addressCountry   = @"Country1";
    buo.contentMetadata.addressPostalCode= @"postal_code";
    buo.contentMetadata.latitude         = 12.07;
    buo.contentMetadata.longitude        = -97.5;
    buo.contentMetadata.imageCaptions    = (id) @[@"my_img_caption1", @"my_img_caption_2"];
    buo.contentMetadata.customMetadata   = (id) @{
        @"Custom_Content_metadata_key1": @"Custom_Content_metadata_val1",
        @"Custom_Content_metadata_key2": @"Custom_Content_metadata_val2",
        @"~campaign": @"Parul's campaign"
    };
    buo.title                       = @"Parul Title";
    buo.canonicalIdentifier         = @"item/12345";
    buo.canonicalUrl                = @"https://branch.io/deepviews";
    buo.keywords                    = @[@"My_Keyword1", @"My_Keyword2"];
    buo.contentDescription          = @"my_product_description1";
    buo.imageUrl                    = @"https://test_img_url";
    buo.expirationDate              = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
    buo.publiclyIndex               = NO;
    buo.locallyIndex                = YES;
    buo.creationDate                = [NSDate date];
    
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.campaign = @"sharing campaign";
    [linkProperties addControlParam:BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT withValue:@"Email Subject"];
    
    BranchShareLink *shareLink =
    [[BranchShareLink alloc]
     initWithUniversalObject:buo
     linkProperties:linkProperties];
    
    shareLink.title = @"Share your test link!";
    shareLink.delegate = self;
    shareLink.shareText = [NSString stringWithFormat:
                           @"Shared from Branch-TestBed at %@.",
                           [self.dateFormatter stringFromDate:[NSDate date]]];
    
    if (@available(iOS 13.0, *)) {
        LPLinkMetadata *tempLinkMetatData = [[LPLinkMetadata alloc] init];
        tempLinkMetatData.title = @"Branch URL";
        UIImage *img = [UIImage imageNamed:@"Brand Assets"];
        tempLinkMetatData.iconProvider = [[NSItemProvider alloc] initWithObject:img];
        tempLinkMetatData.imageProvider = [[NSItemProvider alloc] initWithObject:img];
        shareLink.lpMetaData = tempLinkMetatData;
    }
    
    [shareLink presentActivityViewControllerFromViewController:self anchor:sender];
    [activityIndicator stopAnimating];
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
    [[Branch getInstance] handleDeepLink:URL];
}

#pragma mark - Commerce Events

- (IBAction) sendCommerceEvent:(id)sender {
    _branchUniversalObject.canonicalIdentifier = @"item/12345";
    _branchUniversalObject.canonicalUrl        = @"https://branch.io/item/12345";
    _branchUniversalObject.title               = @"My Item Title";
    
    _branchUniversalObject.contentMetadata.contentSchema     = BranchContentSchemaCommerceProduct;
    _branchUniversalObject.contentMetadata.quantity          = 1;
    _branchUniversalObject.contentMetadata.price             = [[NSDecimalNumber alloc] initWithDouble:23.20];
    _branchUniversalObject.contentMetadata.currency         = BNCCurrencyUSD;
    _branchUniversalObject.contentMetadata.sku               = @"1994320302";
    _branchUniversalObject.contentMetadata.productName       = @"my_product_name1";
    _branchUniversalObject.contentMetadata.productBrand      = @"my_prod_Brand1";
    _branchUniversalObject.contentMetadata.productCategory   = BNCProductCategoryApparel;
    _branchUniversalObject.contentMetadata.productVariant    = @"XL";
    _branchUniversalObject.contentMetadata.condition         = @"NEW";
    _branchUniversalObject.contentMetadata.customMetadata =  (NSMutableDictionary*) @{
        @"content_custom_key1": @"content_custom_value1",
        @"content_custom_key2": @"content_custom_value2"
    };
    
    __block BranchEvent *event = [BranchEvent alloc];
    
    event.contentItems     = (id) @[ _branchUniversalObject ];
    
    // Add relevant event data:
    event.alias            = @"my custom alias";
    event.transactionID    = @"12344555";
    event.currency         = BNCCurrencyUSD;
    event.revenue          = [NSDecimalNumber decimalNumberWithString:@"1.5"];
    event.shipping         = [NSDecimalNumber decimalNumberWithString:@"10.2"];
    event.tax              = [NSDecimalNumber decimalNumberWithString:@"12.3"];
    event.coupon           = @"test_coupon";
    event.affiliation      = @"test_affiliation";
    event.eventDescription = @"Event_description";
    event.searchQuery      = @"item 123";
    event.customData       = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2"
    };
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose a commerce event" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Add To Cart" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventAddToCart];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Add To Wishlist" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BNCAddToWishlistEvent];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"View Cart" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventViewCart];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Initiate Purchase" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventInitiatePurchase];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Add Payment Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventInitiatePurchase];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Purchase" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventInitiatePurchase];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Spend Credits" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventInitiatePurchase];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged commerce event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending commerce event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"Commerce Event action sheet dismissed.");
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
    
    
}

- (IBAction)sendLifecycleEvent:(id)sender {
    __block BranchEvent *event = [BranchEvent alloc];
    
    event.alias = @"my custom alias";
    event.transactionID = @"tx1234";
    event.eventDescription = @"User completed registration.";
    event.customData = (NSMutableDictionary*) @{
        @"Custom_Event_Property_Key1": @"Custom_Event_Property_val1",
        @"Custom_Event_Property_Key2": @"Custom_Event_Property_val2",
        @"registrationID": @"12345"
    };
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Choose A Lifecycle Event" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Complete Registration" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventCompleteRegistration];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged lifecycle event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending lifecycle event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Complete Tutorial" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventCompleteTutorial];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged lifecycle event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending lifecycle event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Achieve Level" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventAchieveLevel];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged lifecycle event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending lifecycle event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Unlock Achievement" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        event = [BranchEvent standardEvent:BranchStandardEventUnlockAchievement];
        [event logEventWithCompletion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                [self showAlert:@"Succesfully logged lifecycle event" withDescription:@""];
            } else {
                [self showAlert:@"Error sending lifecycle event:" withDescription:error.description];
            }
        }];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"Lifecycle Event action sheet dismissed.");
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Spotlight

- (IBAction)registerWithSpotlightButtonTouchUpInside:(id)sender {
    //
    // Example using callbackWithURLandSpotlightIdentifier
    //
    self.branchUniversalObject.contentMetadata.customMetadata[@"deeplink_text"] =
    @"This link was generated for Spotlight registration";
    self.branchUniversalObject.locallyIndex = YES;
    [self.branchUniversalObject registerViewWithCallback:^(NSDictionary * _Nullable params, NSError * _Nullable error) {
        NSLog(@"Link was registered and is locally indexed.");
        if (error == nil) {
            [self showAlert:@"Registered Link With Spotlight" withDescription:@""];
        } else {
            [self performSegueWithIdentifier:@"ShowLogOutput"
                                      sender:[NSString stringWithFormat:@"Error registering link with Spotlight:\n\n%@",
                                              error]];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowLogOutput"]) {
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

- (IBAction)togglePartnerParams:(id)sender {
    if (hasSetPartnerParams) {
        NSLog(@"Cleared Partner Params");
        [[Branch getInstance] clearPartnerParameters];
        [self showAlert:@"Cleared Partner Parameters" withDescription:@""];
        hasSetPartnerParams = false;
        [self.setParnerParamsButton setTitle:@"Set Partner Params" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.setParnerParamsButton setImage:[UIImage systemImageNamed:@"folder.badge.plus"] forState:UIControlStateNormal];
        }
    } else {
        NSLog(@"Set Partner Params");
        [[Branch getInstance] addFacebookPartnerParameterWithName:@"ph" value:@"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b"];
        [[Branch getInstance] addFacebookPartnerParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];
        [self showAlert:@"Set Partner Parameters" withDescription:@""];
        hasSetPartnerParams = true;
        [self.setParnerParamsButton setTitle:@"Clear Partner Params" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.setParnerParamsButton setImage:[UIImage systemImageNamed:@"folder.badge.minus"] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)loadLogs:(id)sender {
    UINavigationController *navigationController =
    (UINavigationController *)self.view.window.rootViewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LogOutputViewController *logOutputViewController =
    [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
    [navigationController pushViewController:logOutputViewController animated:YES];
    
    NSString *logFileContents = [NSString stringWithContentsOfFile:appDelegate.PrevCommandLogFileName encoding:NSUTF8StringEncoding error:nil];
    
    logOutputViewController.logOutput = [NSString stringWithFormat:@"%@", logFileContents];
    
}

- (IBAction)disableTracking:(id)sender {
    
    NSString *title = [self.disableTrackingButton titleForState:UIControlStateNormal];
    
    if ([title isEqualToString:@"Disable Tracking"]) {
        [Branch setTrackingDisabled:YES];
        [self.disableTrackingButton setTitle:@"Enable Tracking" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.disableTrackingButton setImage:[UIImage systemImageNamed:@"eye.fill"] forState:UIControlStateNormal];
        }
    } else {
        [Branch setTrackingDisabled:NO];
        [self.disableTrackingButton setTitle:@"Disable Tracking" forState:UIControlStateNormal];
        if (@available(iOS 13.0, *)) {
            [self.disableTrackingButton setImage:[UIImage systemImageNamed:@"eye.slash.fill"] forState:UIControlStateNormal];
        }
    }
    
}

- (IBAction)createQRCode:(id)sender {
    [activityIndicator startAnimating];
    
    BranchQRCode *qrCode = [BranchQRCode new];
    qrCode.centerLogo = @"https://cdn.branch.io/branch-assets/1598575682753-og_image.png";
    qrCode.codeColor = [[UIColor new] initWithRed:0.1 green:0.8392 blue:0.8667 alpha:1.0];
    qrCode.width = @700;
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    [qrCode getQRCodeAsImage:buo linkProperties:lp completion:^(UIImage * _Nonnull qrCode, NSError * _Nonnull error) {
        NSLog(@"Received QR Code Image: %@", qrCode);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 282)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [imageView setImage:qrCode];
            UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle:@"Your QR Code"
                                                                 message:@""
                                                                delegate:self
                                                       cancelButtonTitle:@"Dismiss"
                                                       otherButtonTitles:nil];
            
            [alertView setValue:imageView forKey:@"accessoryView"];
            [alertView show];
            
            [activityIndicator stopAnimating];
        });
    }];
}

- (IBAction)shareLinkWithMetadata:(id)sender {
    
    NSURL *iconURL = [NSURL URLWithString:@"https://cdn.branch.io/branch-assets/1598575682753-og_image.png"];
    NSData *iconData = [NSData dataWithContentsOfURL:iconURL];
    UIImage *iconImg = [UIImage imageWithData:iconData];
    
    BranchUniversalObject *buo = [BranchUniversalObject new];
    BranchLinkProperties *lp = [BranchLinkProperties new];
    
    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    
    [bsl addLPLinkMetadata:@"LPLinkMetadata Link" icon:iconImg];
    
    [bsl presentActivityViewControllerFromViewController:self anchor:nil];
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

@end

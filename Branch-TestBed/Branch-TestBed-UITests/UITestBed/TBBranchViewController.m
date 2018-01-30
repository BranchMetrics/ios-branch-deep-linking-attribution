//
//  TBBranchViewController.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBBranchViewController.h"
#import "TBAppDelegate.h"
#import "TBTableData.h"
#import "TBDetailViewController.h"
#import "TBWaitingView.h"
@import Branch;
#import "BNCDeviceInfo.h"
#import "BNCSystemObserver.h"
#import "BNCApplication.h"
#import "BNCKeyChain.h"

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
NSString *type = @"some type";

static NSString* TBString(id<NSObject> object) {
    if (object == nil)
        return @"<nil>";
    else
    if ([object isKindOfClass:[NSString class]])
        return (NSString*) object;
    else {
        NSString *s = object.description;
        if (s.length > 0) return s;
        return NSStringFromClass(object.class);
    }
}

@interface TBBranchViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)   TBTableData *tableData;
@property (nonatomic, strong)   BranchUniversalObject *universalObject;
@property (nonatomic, strong)   BranchLinkProperties  *linkProperties;
@property (nonatomic, weak)     IBOutlet UITableView *tableView;
@property (nonatomic, strong)   IBOutlet UINavigationItem *navigationItem;
@end

@implementation TBBranchViewController

- (void)initializeTableData {

    self.tableData = [TBTableData new];

    #define section(title) \
        [self.tableData addSectionWithTitle:title];

    #define row(title, selector_) \
        [self.tableData addRowWithTitle:title selector:@selector(selector_)];

    section(@"Session");
    row(@"First Referring Parameters", showFirstReferringParams:);
    row(@"Latest Referring Parameters", showLatestReferringParams:);
    row(@"Set User Identity", setUserIdentity:);
    row(@"Log User Identity Out", logOutUserIdentity:);

    section(@"Branch Links");
    row(@"Create a Branch Link", createBranchLink:);
    row(@"Open a Branch link in a new session", openBranchLinkInApp:);

    section(@"Events");
    row(@"Send Commerce Event", sendCommerceEvent:);
    row(@"Send Standard Event", sendStandardEvent:);
    row(@"Send Custom Event", sendCustomEvent:);

    section(@"Sharing");
    row(@"ShareLink from table row", sharelinkTableRow:);
    row(@"ShareLink no anchor (one day link)", sharelinkTableRowNilAnchor:);
    row(@"BUO Share from table row", buoShareTableRow:);

    section(@"App Update State");
    row(@"Erase All App Data", clearAllAppDataAction:)
    row(@"Show Dates & Update State", showDatesAction:)

    section(@"Miscellaneous");
    row(@"Show Local IP Addess", showLocalIPAddress:);
    row(@"Show Current View Controller", showCurrentViewController:)
    row(@"Toggle Facebook App Tracking", toggleFacebookAppTrackingAction:)

    #undef section
    #undef row
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeTableData];

    _universalObject =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier: cononicalIdentifier];
    _universalObject.canonicalUrl = canonicalUrl;
    _universalObject.title = contentTitle;
    _universalObject.contentDescription = contentDescription;
    _universalObject.imageUrl = imageUrl;
    _universalObject.contentMetadata.price = [NSDecimalNumber decimalNumberWithString:@"1000"];
    _universalObject.contentMetadata.currency = @"$";
    _universalObject.contentMetadata.contentSchema = type;
    _universalObject.contentMetadata.customMetadata[@"deeplink_text"] =
        [NSString stringWithFormat:
            @"This text was embedded as data in a Branch link with the following characteristics:\n\n"
             "canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n",
                canonicalUrl, contentTitle, contentDescription, imageUrl];

    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.text =
        [NSString stringWithFormat:@"iOS %@\nTestBed %@ SDK %@",
            [UIDevice currentDevice].systemVersion,
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            BNC_SDK_VERSION];
    versionLabel.numberOfLines = 0;
    versionLabel.backgroundColor = self.tableView.backgroundColor;
    versionLabel.textColor = [UIColor darkGrayColor];
    versionLabel.font = [UIFont systemFontOfSize:12.0];
    [versionLabel sizeToFit];
    CGRect r = versionLabel.bounds;
    r.size.height *= 1.75f;
    versionLabel.frame = r;
    self.tableView.tableHeaderView = versionLabel;

    // Add a share button item:
    UIBarButtonItem *barButtonItem =
        [[UIBarButtonItem alloc]
           initWithBarButtonSystemItem:UIBarButtonSystemItemAction
           target:self
           action:@selector(buoShareBarButton:)];
   self.navigationItem.rightBarButtonItem = barButtonItem;
}

#pragma mark - Table View Delegate & Data Source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableData.numberOfSections;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableData numberOfRowsInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.tableData sectionItemForSection:section].title;
}

- (UITableViewCell*) tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    TBTableRow *row = [self.tableData rowForIndexPath:indexPath];
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.value;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void) tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TBTableRow *row = [self.tableData rowForIndexPath:indexPath];
    if (row.selector) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:row.selector withObject:row];
        #pragma clang diagnostic pop
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Utility Methods

- (void) showDataViewControllerWithTitle:(NSString*)title
                                 message:(NSString*)message
                                  object:(id<NSObject>)dictionaryOrArray {

    TBDetailViewController *dataViewController = [[TBDetailViewController alloc] initWithData:dictionaryOrArray];
    dataViewController.title = title;
    dataViewController.message = message;

    // Manage the display mode button
    dataViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    dataViewController.navigationItem.leftItemsSupplementBackButton = YES;

    [self.splitViewController showDetailViewController:dataViewController sender:self];
}

- (void) showAlertWithTitle:(NSString*)title message:(NSString*)message {
    UIAlertController* alert = [UIAlertController
        alertControllerWithTitle:title
        message:message
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
        style:UIAlertActionStyleCancel
        handler:nil]];
    UIViewController *rootViewController =
        [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController presentViewController:alert
        animated:YES
        completion:nil];
}

#pragma mark - Actions

- (IBAction)createBranchLink:(TBTableRow*)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.campaign = @"some campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    
    [self.universalObject
        getShortUrlWithLinkProperties:linkProperties
        andCallback:^(NSString *url, NSError *error) {
            sender.value = url;
            [self.tableView reloadData];
    }];
}

- (IBAction) openBranchLinkInApp:(id)sender {
    NSURL *URL = [NSURL URLWithString:@"https://branch-uitestbed.app.link/TmAw9WrvPI"]; // <= Your URL goes here.
    [[Branch getInstance] handleDeepLinkWithNewSession:URL];
}

- (IBAction)showFirstReferringParams:(TBTableRow*)sender {
    [self showDataViewControllerWithTitle:@"Params"
        message:@"First Referring Parameters"
        object:[[Branch getInstance] getFirstReferringParams]];
}

- (IBAction)showLatestReferringParams:(TBTableRow*)sender {
    [self showDataViewControllerWithTitle:@"Params"
        message:@"Latest Referring Parameters"
        object:[[Branch getInstance] getLatestReferringParamsSynchronous]];
}

- (IBAction)setUserIdentity:(TBTableRow*)sender {
    [TBWaitingView showWithMessage:@"Setting User Identity"
        activityIndicator:YES
        disableTouches:YES];

    [[Branch getInstance] setIdentity:@"my-identity-for-this-user@testbed-objc.io"
        withCallback:^(NSDictionary *params, NSError *error) {
            BNCLogAssert([NSThread isMainThread]);
            [TBWaitingView hide];
            if (error) {
                NSLog(@"Set identity error: %@.", error);
                [self showAlertWithTitle:@"Can't set identity." message:error.localizedDescription];
            } else {
                [self showDataViewControllerWithTitle:@"Identity"
                    message:@"Set Identity" object:params];
            }
        }];
}

- (IBAction)logOutUserIdentity:(TBTableRow*)sender {
    [TBWaitingView showWithMessage:@"Logging out..." activityIndicator:YES disableTouches:YES];
    [[Branch getInstance] logoutWithCallback:^(BOOL changed, NSError *error) {
        [TBWaitingView hide];
        if (error || !changed) {
            [self showAlertWithTitle:@"Logout Error" message:error.localizedDescription];
        } else {
            [self showDataViewControllerWithTitle:@"Log Out"
                message:@"Logged User Identity Out"
                object:@{@"changed": @(YES)}];
        }
    }];
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

    [TBWaitingView showWithMessage:@"Sending Commerce Event"
        activityIndicator:YES
        disableTouches:YES];
    [[Branch getInstance]
        sendCommerceEvent:commerceEvent
        metadata:@{ @"Meta": @"Never meta dog I didn't like." }
        withCompletion:
        ^ (NSDictionary *response, NSError *error) {
            [TBWaitingView hide];
            if (error) {
                [self showAlertWithTitle:@"Commere Event Error" message:error.localizedDescription];
            } else {
                [self showDataViewControllerWithTitle:@"Commerce Event"
                    message:@"Commerce Fields"
                    object:response];
            }
        }];
}

- (IBAction) sendStandardEvent:(id)sender {
    [[BranchEvent standardEvent:BranchStandardEventCompleteTutorial] logEvent];
    [self showDataViewControllerWithTitle:@"Standard Event"
        message:[NSString stringWithFormat:@"%@ Sent", BranchStandardEventCompleteTutorial]
        object:@{}];
}

- (IBAction) sendCustomEvent:(id)sender {
    [[BranchEvent customEventWithName:@"Custom_Event"] logEvent];
    [self showDataViewControllerWithTitle:@"Custom Event"
        message:@"Custom_Event Sent"
        object:@{}];
}

- (IBAction)showLocalIPAddress:(id)sender {
    BNCLogDebugSDK(@"All IP Addresses:\n%@\n.", [BNCDeviceInfo getInstance].allIPAddresses);
    NSString *lip = [BNCDeviceInfo getInstance].localIPAddress;
    if (!lip) lip = @"<nil>";
    if (lip.length == 0) lip = @"<empty string>";
    [self showDataViewControllerWithTitle:@"Local IP Address"
        message:nil
        object:@{
            @"Local IP Address": lip,
        }
    ];
}

- (IBAction) showCurrentViewController:(id)send {
    UIViewController *vc = [UIViewController bnc_currentViewController];
    [self showDataViewControllerWithTitle:@"View Controller"
        message:nil
        object:@{
            @"View Controller": [NSString stringWithFormat:@"%@", vc],
        }
    ];
}

- (IBAction) toggleFacebookAppTrackingAction:(id)sender {
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper preferenceHelper];
    BOOL nextState = !prefs.limitFacebookTracking;
    prefs.limitFacebookTracking = nextState;
    [self showDataViewControllerWithTitle:@"Limit Facebook App Tracking"
        message:nil
        object:@{
            @"Limit Facebook App Tracking": (nextState) ? @"On" : @"Off"
        }
    ];
}

#pragma mark - App Dates / Update State

- (IBAction) clearAllAppDataAction:(id)sender {
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Clear App Data?"
            message:@"Clear all app data?"
            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel
        handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction*action) { [self clearAllAppData]; }]];
    UIViewController *rootViewController =
        [UIApplication sharedApplication].delegate.window.rootViewController;
    [rootViewController presentViewController:alert
        animated:YES
        completion:nil];

}

- (void) clearAllAppData {
    NSError *error = nil;
    NSURL *url = BNCURLForBranchDirectory();
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
    if (error) NSLog(@"Error removing defaults: %@.", error);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    for (NSString *key in dictionary.keyEnumerator)
        [defaults removeObjectForKey:key];
    [defaults synchronize];
    [BNCKeyChain removeValuesForService:nil key:nil];
    exit(0);
}

- (IBAction) showDatesAction:(id)sender {
    BNCApplication *application = [BNCApplication currentApplication];

    NSDate *first_install_time      = application.firstInstallDate;
    NSDate *latest_install_time     = application.currentInstallDate;
    NSDate *latest_update_time      = application.currentBuildDate;
    NSDate *previous_update_time    = global_previous_update_time;

    NSString *update_state = nil;
    if (first_install_time.timeIntervalSince1970 <= 0 ||
        latest_install_time.timeIntervalSince1970 <= 0 ||
        latest_update_time.timeIntervalSince1970 <= 0)
        update_state = @"update_state_error";
    else
    if (latest_update_time.timeIntervalSince1970 <= first_install_time.timeIntervalSince1970 &&
        previous_update_time == 0)
        update_state = @"update_state_install";
    else
    if (first_install_time.timeIntervalSince1970 < first_install_time.timeIntervalSince1970 &&
        previous_update_time == 0)
        update_state = @"update_state_reinstall";
    else
    if (latest_update_time.timeIntervalSince1970 > first_install_time.timeIntervalSince1970 &&
        previous_update_time.timeIntervalSince1970 < latest_update_time.timeIntervalSince1970)
        update_state = @"update_state_update";
    else
        update_state = @"update_state_no_update";

    [self showDataViewControllerWithTitle:@"Dates"
        message:@"Current Application Dates"
        object:@{
            @"first_install_time":      TBString(first_install_time),
            @"latest_install_time":     TBString(latest_install_time),
            @"latest_update_time":      TBString(latest_update_time),
            @"previous_update_time":    TBString(previous_update_time),
            @"update_state":            TBString(update_state)
    }];
}

#pragma mark - Sharing

- (IBAction) sharelinkTableRow:(id)sender {
    NSIndexPath *indexPath = [self.tableData indexPathForRow:sender];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.universalObject
            linkProperties:self.linkProperties];
    [shareLink presentActivityViewControllerFromViewController:self anchor:cell];
}

- (IBAction) sharelinkTableRowNilAnchor:(id)sender {
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
    buo.expirationDate              = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
        //[NSDate dateWithTimeIntervalSince1970:(double)212123232544.0/1000.0];
    buo.publiclyIndex               = NO;
    buo.locallyIndex                = YES;
    buo.creationDate                = [NSDate dateWithTimeIntervalSince1970:(double)1501869445321.0/1000.0];

    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:buo
            linkProperties:self.linkProperties];
    [shareLink presentActivityViewControllerFromViewController:self anchor:nil];
}

- (IBAction) buoShareTableRow:(id)sender {
    NSIndexPath *indexPath = [self.tableData indexPathForRow:sender];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.universalObject showShareSheetWithLinkProperties:self.linkProperties
        andShareText:@"Ha ha"
        fromViewController:self
        anchor:(id)cell
        completionWithError: ^ (NSString * _Nullable activityType, BOOL completed, NSError * _Nullable activityError) {
            BNCLogDebug(@"Done.");
    }];
}

- (IBAction) buoShareBarButton:(id)sender {
    [self.universalObject showShareSheetWithLinkProperties:self.linkProperties
        andShareText:@"Ha ha"
        fromViewController:self
        anchor:sender
        completionWithError: ^ (NSString * _Nullable activityType, BOOL completed, NSError * _Nullable activityError) {
            BNCLogDebug(@"Done.");
    }];
}

@end

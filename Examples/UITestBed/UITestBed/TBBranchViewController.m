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
#import "TBTextViewController.h"
#import "TBWaitingView.h"
@import Branch;
#import "BNCDeviceInfo.h"
#import "BNCSystemObserver.h"
#import "BNCApplication.h"
#import "BNCKeyChain.h"
#import "TBSettings.h"

NSString *canonicalIdentifier = @"item/12345";
NSString *canonicalUrl = @"https://dev.branch.io/getting-started/deep-link-routing/guide/ios/";
NSString *contentTitle = @"Content Title";
NSString *contentDescription = @"My Content Description";
NSString *imageUrl =
    @"http://a57.foxnews.com/images.foxnews.com/content/fox-news/science/2018/03/20/"
     "first-day-spring-arrives-5-things-to-know-about-vernal-equinox/_jcr_content/"
     "par/featured_image/media-0.img.jpg/1862/1048/1521552912093.jpg?ve=1&tl=1";
NSString *feature = @"Sharing Feature";
NSString *channel = @"Distribution Channel";
NSString *desktop_url = @"http://branch.io";
NSString *ios_url = @"https://dev.branch.io/getting-started/sdk-integration-guide/guide/ios/";
NSString *shareText = @"Super amazing thing I want to share";
NSString *type = @"some type";

static NSString* TBStringFromObject(id<NSObject> object) {
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

#pragma mark - TBBranchViewController

@interface TBBranchViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)   TBTableData *tableData;
@property (nonatomic, strong)   BranchUniversalObject *universalObject;
@property (nonatomic, strong)   BranchLinkProperties  *linkProperties;
@property (nonatomic, weak)     IBOutlet UITableView *tableView;
@property (nonatomic, strong)   IBOutlet UINavigationItem *navigationItem;
@property (nonatomic, strong)   NSIndexPath *trackingDisabledPath;
@property (nonatomic, strong)   NSIndexPath *facebookIndexPath;
@property (nonatomic, strong)   TBTableRow *rewardsRow;
@end

#pragma mark - TBBranchViewController

@implementation TBBranchViewController

- (void)initializeTableData {

    TBTableRow *tableRow = nil;
    self.tableData = [TBTableData new];

    #define section(title) \
        [self.tableData addSectionWithTitle:title];

    #define row(title, rowStyle, selector_) \
        [self.tableData addRowWithTitle:title selector:@selector(selector_) style:rowStyle];

    section(@"Session");
//    tableRow = row(@"Pretty Display", TBRowStyleSwitch, togglePrettyDisplay:);
//    tableRow.integerValue = [TBSettings shared].usePrettyDisplay;
//    tableRow.userInfo = 1; // green tint

    tableRow = row(@"Tracking Disabled", TBRowStyleSwitch, trackingDisabled:);
    tableRow.integerValue = Branch.trackingDisabled;
    self.trackingDisabledPath = [self.tableData indexPathForRow:tableRow];

    tableRow = row(@"Limit Facebook Tracking", TBRowStyleSwitch, toggleFacebookAppTrackingAction:)
    tableRow.integerValue = [BNCPreferenceHelper preferenceHelper].limitFacebookTracking;
    self.facebookIndexPath = [self.tableData indexPathForRow:tableRow];

    row(@"First Referring Parameters",  TBRowStyleDisclosure, showFirstReferringParams:);
    row(@"Latest Referring Parameters", TBRowStyleDisclosure, showLatestReferringParams:);
    row(@"Set User Identity",           TBRowStyleDisclosure, setUserIdentity:);
    row(@"Log User Identity Out",       TBRowStyleDisclosure, logOutUserIdentity:);

    section(@"Branch Links");
    row(@"Create a Branch Link",        TBRowStyleDisclosure, createBranchLink:);
    row(@"Open a Branch link in a New Session", TBRowStylePlain, openBranchLinkInApp:);

    section(@"Events");
    row(@"Send Commerce Event",         TBRowStyleDisclosure, sendCommerceEvent:);
    row(@"Send Standard Event",         TBRowStyleDisclosure, sendStandardEvent:);
    row(@"Send Custom Event",           TBRowStyleDisclosure, sendCustomEvent:);

    section(@"Sharing");
    row(@"ShareLink from Table Row",    TBRowStylePlain,        sharelinkTableRow:);
    row(@"ShareLink (No Anchor, One Day Link)", TBRowStylePlain, sharelinkTableRowNilAnchor:);
    row(@"BUO Share from Table Row",    TBRowStylePlain,        buoShareTableRow:);

    section(@"Spotlight");
    row(@"Register BUO on Spotlight",   TBRowStylePlain,        registerBUOOnSpotlight:);

    section(@"Rewards");
    self.rewardsRow = row(@"Refresh Rewards", TBRowStylePlain,  refreshRewards:);
    row(@"Redeem 5 Points",             TBRowStylePlain, redeemRewards:);
    row(@"Show Rewards History",        TBRowStyleDisclosure,   showRewardsHistory:);

    section(@"App Update State");
    row(@"Erase All App Data",          TBRowStylePlain,        clearAllAppDataAction:)
    row(@"Show Dates & Update State",   TBRowStyleDisclosure,   showDatesAction:)

    section(@"Miscellaneous");
    row(@"Show Local IP Addess",        TBRowStyleDisclosure,   showLocalIPAddress:);
    row(@"Show Current View Controller", TBRowStyleDisclosure,  showCurrentViewController:)
    row(@"Stress Test Open",            TBRowStylePlain,        stressTestOpen:)
    row(@"Test fb auth. Open fb123://", TBRowStylePlain,        openFacebookAuth:)
    #undef section
    #undef row
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeTableData];

    _universalObject =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier:canonicalIdentifier];
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
    _linkProperties = [[BranchLinkProperties alloc] init];
    _linkProperties.feature = feature;
    _linkProperties.channel = channel;
    _linkProperties.campaign = @"some campaign";
    [_linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [_linkProperties addControlParam:@"$ios_url" withValue: ios_url];

    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.text =
        [NSString stringWithFormat:@"iOS %@\nTestBed %@ SDK %@\n%@",
            [UIDevice currentDevice].systemVersion,
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            BNC_SDK_VERSION,
            BNC_API_BASE_URL];
    versionLabel.numberOfLines = 0;
    versionLabel.backgroundColor = self.tableView.backgroundColor;
    versionLabel.textColor = [UIColor darkGrayColor];
    versionLabel.font = [UIFont systemFontOfSize:12.0];
    [versionLabel sizeToFit];
    CGRect r = versionLabel.bounds;
    r.size.height += 10.0;
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
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    if (row.rowStyle == TBRowStyleDisclosure) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = row.value;
    } else
    if (row.rowStyle == TBRowStylePlain) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = row.value;
    } else
    if (row.rowStyle == TBRowStyleSwitch) {
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = row.integerValue;
        if (row.userInfo & 1)
            sw.onTintColor = [UIColor greenColor];
        else
            sw.onTintColor = [UIColor redColor];
        [sw addTarget:self action:row.selector forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TBTableRow *row = [self.tableData rowForIndexPath:indexPath];
    BNCLogDebug(@"Selected index %ld:%ld: %@.", (long)indexPath.section, (long)indexPath.row, row.title);
    if (row.rowStyle != TBRowStyleSwitch && row.selector) {
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

    TBDetailViewController *dataViewController =
        [[TBDetailViewController alloc] initWithData:dictionaryOrArray];
    dataViewController.title = title;
    dataViewController.message = message;

    // Manage the display mode button
    dataViewController.navigationItem.leftBarButtonItem =
        self.splitViewController.displayModeButtonItem;
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

- (BranchUniversalObject*) createUniversalObject {
    BranchUniversalObject *buo =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier:canonicalIdentifier];
    buo.canonicalUrl = canonicalUrl;
    buo.title = contentTitle;
    buo.contentDescription = contentDescription;
    buo.imageUrl = imageUrl;
    buo.contentMetadata.price = [NSDecimalNumber decimalNumberWithString:@"1000.00"];
    buo.contentMetadata.currency = @"$";
    buo.contentMetadata.contentSchema = type;
    buo.contentMetadata.customMetadata[@"deeplink_text"] =
        [NSString stringWithFormat:
            @"This text was embedded as data in a Branch link with the following characteristics:\n\n"
             "canonicalUrl: %@\n  title: %@\n  contentDescription: %@\n  imageUrl: %@\n",
                canonicalUrl, contentTitle, contentDescription, imageUrl];
    return buo;
}

- (BranchLinkProperties*) createLinkProperties {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.tags = @[ @"tag1", @"tag2" ];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.stage = @"stage four";
    linkProperties.campaign = @"some campaign";
    linkProperties.matchDuration = 12.2;
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    return linkProperties;
}

#pragma mark - Actions

static NSString* global_createdBranchURLString = nil;

- (IBAction)createBranchLink:(TBTableRow*)sender {
    BranchLinkProperties *linkProperties = [self createLinkProperties];
    BranchUniversalObject *buo = [self createUniversalObject];
    buo.creationDate = [NSDate date];
    [buo getShortUrlWithLinkProperties:linkProperties
        andCallback:^(NSString *url, NSError *error) {
            sender.value = (url.length) ? url : error.description;
            global_createdBranchURLString = url;
            [self.tableView reloadData];
            TBTextViewController *tvc = [TBTextViewController new];
            tvc.text = url;
            tvc.message = @"Branch Link";
            tvc.navigationItem.title = @"Branch Link";
            [self.navigationController pushViewController:tvc animated:YES];
    }];
}

- (IBAction) openBranchLinkInApp:(id)sender {
    if (global_createdBranchURLString.length) {
        NSURL *URL = [NSURL URLWithString:global_createdBranchURLString];
        [[Branch getInstance] handleDeepLinkWithNewSession:URL];
    } else {
        [self showAlertWithTitle:@"Can't Open URL" message:@"No URL to open!\nCreate a link first."];
    }
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

#pragma mark - Miscellaneous

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
    TBTextViewController *tvc =
        [[TBTextViewController alloc] initWithText:[NSString stringWithFormat:@"%@", vc]];
    tvc.navigationItem.title = @"View Controller";
    tvc.message = @"Current View Controller";
    [self.navigationController pushViewController:tvc animated:YES];
}

- (IBAction) stressTestOpen:(id)sender {
    int const kIterations = 10;
    NSURL*const kBranchOpenURL = [NSURL URLWithString:@"https://branch-uitestbed.app.link/ty3IO3bBgL"];

    // First toggle tracking enabled:
    [Branch setTrackingDisabled:NO];
    TBTableRow *trackingRow = [self.tableData rowForIndexPath:self.trackingDisabledPath];
    trackingRow.integerValue = Branch.trackingDisabled;

    // Send opens:
    for (long i = 0; i < kIterations; ++i) {
        BNCLogDebug(@"-------------------------------- Iteration %ld.", i);
        [[Branch getInstance] handleDeepLinkWithNewSession:kBranchOpenURL];
    }

    // Toggle tracking disabled:
    [Branch setTrackingDisabled:YES];
    trackingRow.integerValue = Branch.trackingDisabled;

    // Send opens:
    for (long i = 0; i < kIterations; ++i) {
        BNCLogDebug(@"-------------------------------- Iteration %ld.", i);
        [[Branch getInstance] handleDeepLinkWithNewSession:kBranchOpenURL];
    }
}

- (IBAction) registerBUOOnSpotlight:(id)sender {
    BranchUniversalObject*buo = [self createUniversalObject];
    buo.contentMetadata.customMetadata[@"deeplink_text"] =
        [NSString stringWithFormat:@"This link was generated for Spotlight registration at %@",
            [NSDate date]];
    buo.locallyIndex = YES;
    [buo userCompletedAction:BNCRegisterViewEvent];
}

#pragma mark - Toggle State

- (IBAction) togglePrettyDisplay:(UISwitch*)sender {
    TBTableRow *row = [self.tableData rowForTableView:self.tableView subView:sender]; 
    row.integerValue = !row.integerValue;
    [TBSettings shared].usePrettyDisplay = row.integerValue;
    [self.tableData updateTableView:self.tableView row:row];
}

- (IBAction) toggleFacebookAppTrackingAction:(id)sender {
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper preferenceHelper];
    prefs.limitFacebookTracking = !prefs.limitFacebookTracking;
    TBTableRow *row = [self.tableData rowForIndexPath:self.facebookIndexPath];
    row.integerValue = prefs.limitFacebookTracking;
}

- (void) trackingDisabled:(id)sender {
    [Branch setTrackingDisabled:!Branch.trackingDisabled];
    NSString *message = @"User tracking enabled.";
    if (Branch.trackingDisabled) message = @"User tracking disabled.";
    [self showAlertWithTitle:nil message:message];
    TBTableRow *row = [self.tableData rowForIndexPath:self.trackingDisabledPath];
    row.integerValue = Branch.trackingDisabled;
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
    BNCApplication *application         = [BNCApplication currentApplication];
    NSTimeInterval first_install_time   = application.firstInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_install_time  = application.currentInstallDate.timeIntervalSince1970;
    NSTimeInterval latest_update_time   = application.currentBuildDate.timeIntervalSince1970;
    NSTimeInterval previous_update_time = global_previous_update_time.timeIntervalSince1970;
    NSTimeInterval const kOneDay        = 1.0 * 24.0 * 60.0 * 60.0;

    NSString *update_state = nil;
    if (first_install_time <= 0 ||
        latest_install_time <= 0 ||
        latest_update_time <= 0 ||
        previous_update_time > latest_update_time)
        update_state = @"update_state_error";
    else
    if (first_install_time < latest_install_time && previous_update_time <= 0)
        update_state = @"update_state_reinstall";
    else
    if ((latest_update_time - kOneDay) <= first_install_time && previous_update_time <= 0)
        update_state = @"update_state_install";
    else
    if (latest_update_time > first_install_time && previous_update_time < latest_update_time)
        update_state = @"update_state_update";
    else
        update_state = @"update_state_no_update";

    [self showDataViewControllerWithTitle:@"Dates"
        message:@"Current Application Dates"
        object:@{
            @"first_install_time":      TBStringFromObject(application.firstInstallDate),
            @"latest_install_time":     TBStringFromObject(application.currentInstallDate),
            @"latest_update_time":      TBStringFromObject(application.currentBuildDate),
            @"previous_update_time":    TBStringFromObject(global_previous_update_time),
            @"update_state":            TBStringFromObject(update_state)
    }];
}

#pragma mark - Sharing

- (IBAction) sharelinkTableRow:(TBTableRow*)sender {
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    lp.feature = @"Sharing Feature";
    lp.channel = @"Distribution Channel";
    lp.campaign = @"some campaign";
    lp.tags = @[ @"tag1", @"tag2" ];
    [lp addControlParam:@"$desktop_url" withValue:@"http://branch.io"];
    [lp addControlParam:@"$email_subject" withValue:@"Email Subject"];
    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.universalObject
            linkProperties:lp/*self.linkProperties*/];
    shareLink.shareText = @"ShareLink from table row:\n";
    UITableViewCell *cell = [self.tableData cellForTableView:self.tableView tableRow:sender];
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
    buo.publiclyIndex               = NO;
    buo.locallyIndex                = YES;
    buo.creationDate                = [NSDate dateWithTimeIntervalSince1970:(double)1501869445321.0/1000.0];

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.campaign = @"some campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];

    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:buo
            linkProperties:self.linkProperties];
    shareLink.emailSubject = @"Email Subject";
    shareLink.shareText = @"Share link with no anchor:\n";
    [shareLink presentActivityViewControllerFromViewController:self anchor:nil];
}

- (IBAction) buoShareTableRow:(TBTableRow*)sender {
    BranchUniversalObject *buo =
        [[BranchUniversalObject alloc] initWithCanonicalIdentifier:canonicalIdentifier];
    buo.canonicalUrl = @"https://branch.io/deepviews";
    buo.imageUrl = imageUrl;
    buo.title = @"Share Title";
    buo.contentMetadata.customMetadata = (id) @{@"Key": @"Value"};

    BranchLinkProperties *link = [BranchLinkProperties new];
    [link addControlParam:@"$desktop_url" withValue:@"https://google.com/"];
    [link addControlParam:@"$email_subject" withValue:@"Email-Subject"];
    [link addControlParam:@"timestamp" withValue:[NSDate date].description];

    UITableViewCell *cell = [self.tableData cellForTableView:self.tableView tableRow:sender];
    [buo showShareSheetWithLinkProperties:link
        andShareText:@"Share Table Row Universal Object:\n"
        fromViewController:self
        anchor:(id)cell
        completionWithError:
        ^ (NSString * _Nullable activityType, BOOL completed, NSError * _Nullable activityError) {
            BNCLogDebug(@"Done.");
    }];
}

- (IBAction)openFacebookAuth:(TBTableRow*)row {
    NSURL*URL = [NSURL URLWithString:@"fb123://open?myself"];
    [Branch.getInstance handleDeepLinkWithNewSession:URL];
}

- (IBAction) buoShareBarButton:(id)sender {
    [self.universalObject showShareSheetWithLinkProperties:self.linkProperties
        andShareText:@"Show BUO share sheet from nav bar.\n"
        fromViewController:self
        anchor:sender
        completionWithError:
        ^ (NSString * _Nullable activityType, BOOL completed, NSError * _Nullable activityError) {
            BNCLogDebug(@"Done.");
    }];
}

#pragma mark - Rewards

- (IBAction) refreshRewards:(TBTableRow*)sender {
    [TBWaitingView showWithMessage:@"Refreshing" activityIndicator:YES disableTouches:YES];
    [[Branch getInstance] loadRewardsWithCallback: ^ (BOOL changed, NSError *error) {
        if (error) {
            [TBWaitingView hide];
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
        } else {
            long credits = [[Branch getInstance] getCredits];
            sender.value = [NSString stringWithFormat:@"%ld", credits];
            NSIndexPath *indexPath = [self.tableData indexPathForRow:sender];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            NSString *message = [NSString stringWithFormat:@"Credits: %ld", credits];
            [TBWaitingView hideWithMessage:message];
        }
    }];
}

- (void) refreshRewardsQuietly {
    [[Branch getInstance] loadRewardsWithCallback: ^ (BOOL changed, NSError *error) {
        if (!error) {
            long credits = [[Branch getInstance] getCredits];
            self.rewardsRow.value = [NSString stringWithFormat:@"%ld", credits];
            NSIndexPath *indexPath = [self.tableData indexPathForRow:self.rewardsRow];
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }];
}

- (IBAction) showRewardsHistory:(TBTableRow*)sender {
    [TBWaitingView showWithMessage:@"Getting Rewards" activityIndicator:YES disableTouches:YES];
    [[Branch getInstance] getCreditHistoryWithCallback:^(NSArray *creditHistory, NSError *error) {
        [TBWaitingView hide];
        if (error) {
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
        } else {
            [self showDataViewControllerWithTitle:@"Rewards" message:@"Rewards History" object:creditHistory];
        }
    }];
}

- (IBAction) redeemRewards:(TBTableRow*)sender {
    [TBWaitingView showWithMessage:@"Redeeming" activityIndicator:YES disableTouches:YES];
    [[Branch getInstance] redeemRewards:5 callback:^(BOOL changed, NSError *error) {
        if (error || !changed) {
            [TBWaitingView hide];
            [self showAlertWithTitle:@"Redemption Unsuccessful" message:error.localizedDescription];
        } else {
            [TBWaitingView hideWithMessage:@"Five points redeemed!"];
            [self refreshRewardsQuietly];
        }
    }];
}

@end

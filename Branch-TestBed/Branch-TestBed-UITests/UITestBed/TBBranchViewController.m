//
//  TBBranchViewController.m
//  Testbed-ObjC
//
//  Created by Edward Smith on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBBranchViewController.h"
#import "TBTableData.h"
#import "TBDetailViewController.h"
#import "TBWaitingView.h"
@import Branch;
#import "BNCDeviceInfo.h"
#import "UIViewController+Branch.h"

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

    section(@"Sharing");
    row(@"ShareLink from table row", sharelinkTableRow:);
    row(@"ShareLink no anchor", sharelinkTableRowNilAnchor:);
    row(@"BUO Share from table row", buoShareTableRow:);

    section(@"Miscellaneous");
    row(@"Show Local IP Addess", showLocalIPAddress:);
    row(@"Show Current View Controller", showCurrentViewController:)

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

- (void) showDataViewControllerWithObject:(id<NSObject>)dictionaryOrArray
                                    title:(NSString*)title
                                  message:(NSString*)message {
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
    NSURL *URL = [NSURL URLWithString:@"https://bnc.lt/ZPOc/Y6aKU0rzcy"]; // <= Your URL goes here.
    [[Branch getInstance] handleDeepLinkWithNewSession:URL];
}

- (IBAction)showFirstReferringParams:(TBTableRow*)sender {
    [self showDataViewControllerWithObject:[[Branch getInstance] getFirstReferringParams]
               title:@"First Referring Parameters"
                 message:nil];
}

- (IBAction)showLatestReferringParams:(TBTableRow*)sender {
    [self showDataViewControllerWithObject:[[Branch getInstance] getLatestReferringParamsSynchronous]
               title:@"Latest Referring Parameters"
                 message:nil];
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
                [self showDataViewControllerWithObject:params title:@"Set Identity" message:@"User Identity Set"];
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
            [self showDataViewControllerWithObject:@{@"changed": @(YES)}
                title:@"Log Out User" message:@"Logged User Identity Out"];
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
                [self showDataViewControllerWithObject:response
                    title:@"Commerce Event"
                    message:nil];
            }
        }];
}

- (IBAction)showLocalIPAddress:(id)sender {
    BNCLogDebugSDK(@"All IP Addresses:\n%@\n.", [BNCDeviceInfo getInstance].allIPAddresses);
    NSString *lip = [BNCDeviceInfo getInstance].localIPAddress;
    if (!lip) lip = @"<nil>";
    if (lip.length == 0) lip = @"<empty string>";
    [self showDataViewControllerWithObject:@{
            @"Local IP Address": lip,
        }
        title:@"Local IP Address"
        message:nil
    ];
}

- (IBAction) showCurrentViewController:(id)send {
    UIViewController *vc = [UIViewController bnc_currentViewController];
    [self showDataViewControllerWithObject:@{
            @"View Controller": [NSString stringWithFormat:@"%@", vc],
        }
        title:@"View Controller"
        message:nil
    ];
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
    BranchShareLink *shareLink =
        [[BranchShareLink alloc]
            initWithUniversalObject:self.universalObject
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

//
//  TBViewController.m
//  Testbed-ObjC
//
//  Created by edward on 6/12/17.
//  Copyright © 2017 Branch. All rights reserved.
//

#import "TBViewController.h"
#import "TBTableData.h"
#import "Branch.h"

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

@interface TBViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak)     IBOutlet UITableView *tableView;
@property (nonatomic, strong)   TBTableData *tableData;
@property (nonatomic, strong)   BranchUniversalObject *branchUniversalObject;
@end

@implementation TBViewController

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

}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeTableData];

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

    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.text =
        [NSString stringWithFormat:@"iOS %@ / TestBed %@ / SDK %@",
            [UIDevice currentDevice].systemVersion,
            [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
            BNC_SDK_VERSION];
    [versionLabel sizeToFit];
    self.tableView.tableHeaderView = versionLabel;
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

- (void) showDictionary:(NSDictionary*)dictionary withTitle:(NSString*)title {
}

#pragma mark - Actions

- (IBAction)createBranchLink:(TBTableRow*)sender {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.feature = feature;
    linkProperties.channel = channel;
    linkProperties.campaign = @"some campaign";
    [linkProperties addControlParam:@"$desktop_url" withValue: desktop_url];
    [linkProperties addControlParam:@"$ios_url" withValue: ios_url];
    
    [self.branchUniversalObject
        getShortUrlWithLinkProperties:linkProperties
        andCallback:^(NSString *url, NSError *error) {
            sender.value = url;
            [self.tableView reloadData];
    }];
}

- (IBAction)showFirstReferringParams:(TBTableRow*)sender {
    [self showDictionary:[[Branch getInstance] getFirstReferringParams]
        withTitle:@"First Referring Parameters"];
}

- (IBAction)showLatestReferringParams:(TBTableRow*)sender {
}
- (IBAction)setUserIdentity:(TBTableRow*)sender {
}
- (IBAction)logOutUserIdentity:(TBTableRow*)sender {
}

@end

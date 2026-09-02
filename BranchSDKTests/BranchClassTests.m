//
//  BranchClassTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 9/25/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPasteboard.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"

@interface BNCPreferenceHelper(Test)
// Expose internal private method to clear EEA data
- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value;
@end

@interface Branch(Test)
// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
+ (void)resetInitializationGuardForTesting;
// Expose the private preprocessing helpers shared by the legacy handlers and the
// requestDeepLinkData* convenience methods.
- (BOOL)processDeepLinkURL:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier;
- (BOOL)processUserActivity:(NSUserActivity *)userActivity sceneIdentifier:(NSString *)sceneIdentifier;
- (BOOL)processDeepLinkURL:(NSURL *)url sceneIdentifier:(NSString *)sceneIdentifier filtered:(BOOL *)filtered;
- (BOOL)processUserActivity:(NSUserActivity *)userActivity sceneIdentifier:(NSString *)sceneIdentifier filtered:(BOOL *)filtered;
@end

@interface BranchClassTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@end

@implementation BranchClassTests

- (void)setUp {
    [super setUp];
    // +sharedInstance requires the SDK to be initialized first. Reset the guard so each test can
    // (re)initialize the singleton, then configure it via the canonical entry point.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];
}

- (void)tearDown {
    self.branch = nil;
    [super tearDown];
}

- (void)testIsUserIdentified {
    [self.branch setUserAlias: @"userId" completion:nil];
    XCTAssertTrue([self.branch isUserIdentified], @"User should be identified");
}

- (void)testDisableAdNetworkCallouts {
    [self.branch disableAdNetworkCallouts:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].disableAdNetworkCallouts, @"AdNetwork callouts should be disabled");
}

- (void)testSetNetworkTimeout {
    [self.branch setNetworkTimeout:5.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].timeout, 5.0, @"Network timeout should be set to 5.0");
}

//- (void)testSetMaxRetries {
//    [self.branch setMaxRetries:3];
//    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryCount, 3, @"Max retries should be set to 3");
//}

- (void)testSetRetryInterval {
    [self.branch setRetryInterval:2.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryInterval, 2.0, @"Retry interval should be set to 2.0");
}

- (void)testSetRequestMetadataKeyAndValue {
    [self.branch setRequestMetadataKey:@"key" value:@"value"];
    NSDictionary *metadata = [BNCPreferenceHelper sharedInstance].requestMetadataDictionary;
    XCTAssertEqualObjects(metadata[@"key"], @"value");
}

- (void)testCheckPasteboardOnInstall {
    [self.branch checkPasteboardOnInstall];
    BOOL checkOnInstall = [BNCPasteboard sharedInstance].checkOnInstall;
    XCTAssertTrue(checkOnInstall);
}

- (void)testWillShowPasteboardToast_ShouldReturnYes {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = nil;
    [BNCPasteboard sharedInstance].checkOnInstall = YES;
    UIPasteboard.generalPasteboard.URL = [NSURL URLWithString:@"https://example.com"];

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertTrue(result);
}

- (void)testWillShowPasteboardToast_ShouldReturnNo {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = @"some_token";
    [BNCPasteboard sharedInstance].checkOnInstall = NO;

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertFalse(result);
}

- (void)testSetAppClipAppGroup {
    NSString *testAppGroup = @"testAppGroup";
    [self.branch setAppClipAppGroup:testAppGroup];
    NSString *actualAppGroup = [BNCAppGroupsData shared].appGroup;

    XCTAssertEqualObjects(testAppGroup, actualAppGroup);
}

- (void)testClearPartnerParameters {
    [self.branch addFacebookPartnerParameterWithName:@"ph" value:@"123456789"];
    [[BNCPartnerParameters shared] clearAllParameters];

    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson];
    XCTAssertEqual([result count], 0, @"Parameters should be empty after calling clearAllParameters");
}

- (void)testAddFacebookParameterWithName_Value {
    [self.branch addFacebookPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];

    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"fb"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Facebook");
}

- (void)testAddSnapParameterWithName_Value {
    [self.branch addSnapPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];

    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"snap"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Snap");
}

- (void)testGetFirstReferringBranchUniversalObject_ClickedBranchLink {
    NSString *installParamsString = @"{\"$canonical_identifier\":\"content/12345\",\"$creation_timestamp\":1694557342247,\"$desktop_url\":\"https://example.com/home\",\"$og_description\":\"My Content Description\",\"$og_title\":\"My Content Title\",\"+click_timestamp\":1695749249,\"+clicked_branch_link\":1,\"+is_first_session\":1,\"+match_guaranteed\":1,\"custom\":\"data\",\"key1\":\"value1\",\"~campaign\":\"content 123 launch\",\"~channel\":\"facebook\",\"~creation_source\":3,\"~feature\":\"sharing\",\"~id\":1230269548213984984,\"~referring_link\":\"https://bnctestbed.app.link/uSPHktjO2Cb\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];

    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];\
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Content Title");
    XCTAssertEqualObjects(result.canonicalIdentifier, @"content/12345");
}

- (void)testGetFirstReferringBranchUniversalObject_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];

    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringBranchLinkProperties_ClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":1,\"~campaign\":\"content 123 launch\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"content 123 launch");
}

- (void)testGetFirstReferringBranchLinkProperties_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringParams {
    NSString *installParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    NSDictionary *result = [self.branch getFirstReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

- (void)testGetLatestReferringParams {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    NSDictionary *result = [self.branch getLatestReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

//- (void)testGetLatestReferringParamsSynchronous {
//    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
//    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];
//
//    NSDictionary *result = [self.branch getLatestReferringParamsSynchronous];
//    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
//}

- (void)testGetLatestReferringBranchUniversalObject_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":false,\"$og_title\":\"My Latest Content\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchUniversalObject *result = [self.branch getLatestReferringBranchUniversalObject];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Latest Content");
}

- (void)testGetLatestReferringBranchLinkProperties_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,\"~campaign\":\"latest campaign\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchLinkProperties *result = [self.branch getLatestReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"latest campaign");
}

// testGetShortURL was removed in EMT-4069. Its only assertion, hasPrefix:@"https://", was also
// satisfied by BranchShortUrlSyncRequest's non-200 long-URL fallback, so it could not distinguish a
// created short link from a failed request -- and whether the fallback returned a string or nil
// depended on preferenceHelper.userUrl, shared persisted state that other test classes overwrite.
// Replaced by -[BranchLinkBuilderTests testFetchShortURLLiveSmokeTest], which asserts the Branch
// link domain and rejects the fallback, plus the stubbed fetchShortURL cases in that class.

// testGetLongURLWithParamsAndChannelAndTagsAndFeatureAndStageAndAlias was removed in EMT-4069 along
// with -[Branch getLongURLWithParams:andChannel:andTags:andFeature:andStage:andAlias:]. Its exact
// expected string lives on in -[BranchLinkBuilderTests testLongURLDefaultDomainExactString], with
// the one difference the migration introduces: channel=channel1& between alias= and feature=. The
// deleted method took a channel and dropped it before assembling the URL, which was a bug.

- (void)testDMAParamsWriteThroughToPreferences {
    // DMA parameters are config-only (no runtime setter). This asserts the preference-write mechanism that
    // +[Branch initialize:] uses when applying a BranchConfiguration.dmaParameters value.
    XCTAssertFalse([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);

    [BNCPreferenceHelper sharedInstance].eeaRegion = FALSE;
    [BNCPreferenceHelper sharedInstance].adPersonalizationConsent = TRUE;
    [BNCPreferenceHelper sharedInstance].adUserDataUsageConsent = TRUE;
    XCTAssertTrue([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].eeaRegion);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adPersonalizationConsent);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adUserDataUsageConsent);

    // Manually clear values after testing
    // By design, this API is meant to be set once and always set. However, in a test scenario it needs to be cleared.
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_eea" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_personalization" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_user_data" value:nil];
}

- (void)testSetConsumerProtectionAttributionLevel {
    // Set to Reduced and check
    Branch *branch = [Branch sharedInstance];
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelReduced);

    // Set to Minimal and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelMinimal];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelMinimal);

    // Set to None and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelNone];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelNone);

    // Set to Full and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelFull);

}

#pragma mark - Deep Link Preprocessing

// The requestDeepLinkData* convenience methods must run the same preprocessing as the legacy
// handleDeepLink: / continueUserActivity: handlers. These tests assert that the shared helpers
// populate the preferenceHelper the same way, so none of the previous checks are skipped.

- (void)clearDeepLinkPreferences {
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    prefs.externalIntentURI = nil;
    prefs.universalLinkUrl = nil;
    prefs.linkClickIdentifier = nil;
    prefs.initialReferrer = nil;
    prefs.spotlightIdentifier = nil;
    prefs.referringURL = nil;
    prefs.dropURLOpen = NO;
}

- (void)testProcessDeepLinkURL_customScheme_setsExternalIntentURIAndLinkClickId {
    [self clearDeepLinkPreferences];
    NSURL *url = [NSURL URLWithString:@"myapp://open?link_click_id=abc123"];

    [self.branch processDeepLinkURL:url sceneIdentifier:nil];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualObjects(prefs.externalIntentURI, url.absoluteString);
    XCTAssertEqualObjects(prefs.referringURL, url.absoluteString);
    XCTAssertEqualObjects(prefs.linkClickIdentifier, @"abc123");
}

- (void)testProcessDeepLinkURL_universalLink_setsUniversalLinkUrl {
    [self clearDeepLinkPreferences];
    NSURL *url = [NSURL URLWithString:@"https://example.app.link/abc"];

    [self.branch processDeepLinkURL:url sceneIdentifier:nil];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualObjects(prefs.universalLinkUrl, url.absoluteString);
    XCTAssertEqualObjects(prefs.referringURL, url.absoluteString);
}

- (void)testRequestDeepLinkDataWithURL_runsPreprocessing {
    [self clearDeepLinkPreferences];
    NSURL *url = [NSURL URLWithString:@"myapp://open?link_click_id=fromConvenience"];

    [self.branch requestDeepLinkDataWithURL:url];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualObjects(prefs.externalIntentURI, url.absoluteString);
    XCTAssertEqualObjects(prefs.linkClickIdentifier, @"fromConvenience");
}

- (void)testProcessUserActivity_browsingWeb_setsInitialReferrerAndUniversalLink {
    [self clearDeepLinkPreferences];
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://example.app.link/xyz"];
    activity.referrerURL = [NSURL URLWithString:@"https://referrer.example.com"];

    [self.branch processUserActivity:activity sceneIdentifier:nil];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualObjects(prefs.initialReferrer, @"https://referrer.example.com");
    XCTAssertEqualObjects(prefs.universalLinkUrl, activity.webpageURL.absoluteString);
}

- (void)testRequestDeepLinkDataWithUserActivity_runsPreprocessing {
    [self clearDeepLinkPreferences];
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://example.app.link/xyz"];
    activity.referrerURL = [NSURL URLWithString:@"https://referrer.example.com"];

    [self.branch requestDeepLinkDataWithUserActivity:activity];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualObjects(prefs.initialReferrer, @"https://referrer.example.com");
    XCTAssertEqualObjects(prefs.universalLinkUrl, activity.webpageURL.absoluteString);
}

#pragma mark - Skiplist gating
//
// The `filtered` out-param is what the callers gate the /v3/deeplink enqueue on. It must be YES only
// for a skiplisted URL — the BOOL return value means "was recognized as a Branch link", which is a
// different question, and gating on it would drop real links and still send skiplisted ones.
// The pattern list is pinned via setUrlPatternsToIgnore: because BNCURLFilter's default list can be
// replaced by the server-pushed list at runtime.

// Restores a user pattern list that cannot match anything. setUrlPatternsToIgnore: falls back to the
// default list when passed an empty array, so a never-matching pattern is used instead.
- (void)clearUserURLPatterns {
    [self.branch setUrlPatternsToIgnore:@[@"^zzz-never-matches-branch-test:"]];
}

- (void)testProcessDeepLinkURL_skiplistedURL_isFilteredAndNotRecognized {
    [self clearDeepLinkPreferences];
    [self.branch setUrlPatternsToIgnore:@[@"^myapp:\\/\\/oauth"]];
    NSURL *url = [NSURL URLWithString:@"myapp://oauth?link_click_id=shouldNotBeSent"];

    BOOL filtered = NO;
    BOOL handled = [self.branch processDeepLinkURL:url sceneIdentifier:nil filtered:&filtered];

    XCTAssertTrue(filtered, @"A skiplisted URL must be reported as filtered so callers do not send it");
    XCTAssertFalse(handled);
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertTrue(prefs.dropURLOpen);
    XCTAssertNil(prefs.linkClickIdentifier, @"A skiplisted URL must not have its link_click_id extracted");

    [self clearUserURLPatterns];
    [self clearDeepLinkPreferences];
}

- (void)testProcessDeepLinkURL_branchLink_isNotFiltered {
    [self clearDeepLinkPreferences];
    [self clearUserURLPatterns];
    NSURL *url = [NSURL URLWithString:@"myapp://open?link_click_id=abc123"];

    BOOL filtered = NO;
    BOOL handled = [self.branch processDeepLinkURL:url sceneIdentifier:nil filtered:&filtered];

    XCTAssertFalse(filtered, @"A Branch link must not be reported as filtered");
    XCTAssertTrue(handled);
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].dropURLOpen);
}

- (void)testProcessDeepLinkURL_nonBranchURL_isNotFiltered {
    [self clearDeepLinkPreferences];
    [self clearUserURLPatterns];
    NSURL *url = [NSURL URLWithString:@"myapp://open"];

    BOOL filtered = NO;
    BOOL handled = [self.branch processDeepLinkURL:url sceneIdentifier:nil filtered:&filtered];

    // Not a Branch link, but not skiplisted either — the caller still runs a deferred data lookup.
    XCTAssertFalse(filtered);
    XCTAssertFalse(handled);
}

- (void)testProcessUserActivity_skiplistedUniversalLink_isFiltered {
    [self clearDeepLinkPreferences];
    [self.branch setUrlPatternsToIgnore:@[@"^https:\\/\\/example\\.com\\/oauth"]];
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://example.com/oauth/callback"];

    BOOL filtered = NO;
    [self.branch processUserActivity:activity sceneIdentifier:nil filtered:&filtered];

    XCTAssertTrue(filtered);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].dropURLOpen);

    [self clearUserURLPatterns];
    [self clearDeepLinkPreferences];
}

- (void)testProcessUserActivity_browsingWebBranchLink_isNotFiltered {
    [self clearDeepLinkPreferences];
    [self clearUserURLPatterns];
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://example.app.link/xyz"];

    BOOL filtered = NO;
    BOOL handled = [self.branch processUserActivity:activity sceneIdentifier:nil filtered:&filtered];

    XCTAssertFalse(filtered);
    XCTAssertTrue(handled);
}


@end

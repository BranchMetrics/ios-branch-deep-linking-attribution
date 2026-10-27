//
//  BNCPasteboardTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 7/19/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPasteboard.h"
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BNCPreferenceHelper.h"
#import "BNCRequestFactory.h"
#import "BranchConstants.h"
#import "BNCServerResponse.h"
#import "BranchRequestOpen.h"

@interface Branch (BNCPasteboardTest)
// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
+ (void)resetInitializationGuardForTesting;
@end

@interface BNCPasteboardTests : XCTestCase

@property (nonatomic, assign, readwrite) NSString *testString;
@property (nonatomic, strong, readwrite) NSURL *testBranchURL;

@end

@implementation BNCPasteboardTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testString = @"Pasteboard String";
    self.testBranchURL = [NSURL URLWithString:@"https://123.app.link"];
    // +sharedInstance requires the SDK to be initialized first.
    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)addStringToPasteboard {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setString:self.testString];
#endif
}

- (void)addBranchURLToPasteboard {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setURL:self.testBranchURL];
#endif
}

- (void)addNonBranchURLToPasteboard {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setURL:[NSURL URLWithString:@"https://www.apple.com"]];
#endif
}

- (void)clearPasteboard {
#if !TARGET_OS_TV
    // cannot delete items from the pasteboard, but we can put something else on there
    [[UIPasteboard generalPasteboard] setString:@""];
#endif
}

- (NSString *)getStringFromClipboard {
    NSString *string = nil;
#if !TARGET_OS_TV
    string = [UIPasteboard.generalPasteboard string];
#endif
    return string;
}

- (NSURL *)getURLFromPasteboard {
    NSURL *url = nil;
#if !TARGET_OS_TV
    url = [UIPasteboard.generalPasteboard URL];
#endif
    return url;
}

- (void)testStringUtilityMethods {

    // set and retrieve a string
    [self addStringToPasteboard];
    NSString *tmp = [self getStringFromClipboard];
    XCTAssert([self.testString isEqualToString:tmp]);

    // overwrite the pasteboard
    [self clearPasteboard];
    tmp = [self getStringFromClipboard];
    XCTAssert([@"" isEqualToString:tmp]);
}

- (void)testURLUtilityMethods {

    // set and retrieve a url
    [self addBranchURLToPasteboard];
    NSURL *tmp = [self getURLFromPasteboard];
    XCTAssert([self.testBranchURL.absoluteString isEqualToString:tmp.absoluteString]);

    // overwrite the pasteboard
    [self clearPasteboard];
    tmp = [self getURLFromPasteboard];
    XCTAssertNil(tmp);
}

- (void)testDefaultState {
    // host app sets this to true, should consider a no-op test host
    XCTAssertFalse([BNCPasteboard sharedInstance].checkOnInstall);
}

- (void)testIsUrlOnPasteboard {
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    [self addBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    [self clearPasteboard];
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);
}

- (void)testCheckForBranchLink {
    [self addBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssert([self.testBranchURL.absoluteString isEqualToString:tmp.absoluteString]);

    [self clearPasteboard];
}

- (void)testCheckForBranchLink_nonBranchLink {
    [self addNonBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssertNil(tmp);

    [self clearPasteboard];
}

- (void)testCheckForBranchLink_noLink {
    [self addStringToPasteboard];
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssertNil(tmp);

    [self clearPasteboard];
}

- (NSDictionary *)payloadWithCheckOnInstall:(BOOL)checkOnInstall firstLaunch:(BOOL)firstLaunch deepLink:(BOOL)deepLink {
    return [self payloadWithCheckOnInstall:checkOnInstall firstLaunch:firstLaunch deepLink:deepLink urlString:nil];
}

- (NSDictionary *)payloadWithCheckOnInstall:(BOOL)checkOnInstall firstLaunch:(BOOL)firstLaunch deepLink:(BOOL)deepLink urlString:(NSString *)urlString {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    BOOL savedCheckOnInstall = [BNCPasteboard sharedInstance].checkOnInstall;
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.localUrl = nil;
    preferenceHelper.pasteboardChecked = NO;
    preferenceHelper.randomizedBundleToken = firstLaunch ? nil : @"existing_bundle_token";
    [BNCPasteboard sharedInstance].checkOnInstall = checkOnInstall;

    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:[NSUUID UUID].UUIDString TimeStamp:@0];
    NSDictionary *json = deepLink ? [factory dataForDeepLinkWithURLString:urlString] : [factory dataForRequestOpenWithURLString:urlString];

    [BNCPasteboard sharedInstance].checkOnInstall = savedCheckOnInstall;
    preferenceHelper.randomizedBundleToken = savedBundleToken;
    return json;
}

- (void)testDeepLinkFirstLaunchSendsPasteboardLinkWhenCheckOnInstall {
#if !TARGET_OS_TV
    [self addBranchURLToPasteboard];

    NSDictionary *json = [self payloadWithCheckOnInstall:YES firstLaunch:YES deepLink:YES];
    XCTAssertEqualObjects(json[BRANCH_REQUEST_KEY_LOCAL_URL], self.testBranchURL.absoluteString);

    [self clearPasteboard];
#endif
}

- (void)testDeepLinkSkipsPasteboardAfterFirstLaunch {
#if !TARGET_OS_TV
    [self addBranchURLToPasteboard];

    NSDictionary *json = [self payloadWithCheckOnInstall:YES firstLaunch:NO deepLink:YES];
    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);

    [self clearPasteboard];
#endif
}

- (void)testDeepLinkFirstLaunchFromLinkSkipsPasteboard {
#if !TARGET_OS_TV
    [self addBranchURLToPasteboard];

    NSDictionary *json = [self payloadWithCheckOnInstall:YES firstLaunch:YES deepLink:YES urlString:@"https://bnctestbed.app.link/launch"];
    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);
    XCTAssertEqualObjects([self getURLFromPasteboard].absoluteString, self.testBranchURL.absoluteString);

    [self clearPasteboard];
#endif
}

- (void)testDeepLinkFirstLaunchSkipsPasteboardWhenCheckOnInstallOff {
#if !TARGET_OS_TV
    [self addBranchURLToPasteboard];

    NSDictionary *json = [self payloadWithCheckOnInstall:NO firstLaunch:YES deepLink:YES];
    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);

    [self clearPasteboard];
#endif
}

- (void)testDeepLinkFirstLaunchReadsPasteboardOnce {
#if !TARGET_OS_TV
    [self addNonBranchURLToPasteboard];
    NSDictionary *json = [self payloadWithCheckOnInstall:YES firstLaunch:YES deepLink:YES];
    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].pasteboardChecked);

    // A second no-URL deep link before the install open lands must not read the pasteboard again.
    [self addBranchURLToPasteboard];
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.randomizedBundleToken = nil;
    [BNCPasteboard sharedInstance].checkOnInstall = YES;

    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:[NSUUID UUID].UUIDString TimeStamp:@0];
    json = [factory dataForDeepLinkWithURLString:nil];

    [BNCPasteboard sharedInstance].checkOnInstall = NO;
    preferenceHelper.randomizedBundleToken = savedBundleToken;
    preferenceHelper.pasteboardChecked = NO;

    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);
    XCTAssertEqualObjects([self getURLFromPasteboard].absoluteString, self.testBranchURL.absoluteString);

    [self clearPasteboard];
#endif
}

- (void)testDeepLinkFirstLaunchWithEmptyPasteboardMarksChecked {
#if !TARGET_OS_TV
    [self clearPasteboard];
    [self payloadWithCheckOnInstall:YES firstLaunch:YES deepLink:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].pasteboardChecked);
    [BNCPreferenceHelper sharedInstance].pasteboardChecked = NO;
#endif
}

- (void)testDeepLinkSkipsPasteboardCheckWhenCheckOnInstallOff {
#if !TARGET_OS_TV
    [self payloadWithCheckOnInstall:NO firstLaunch:YES deepLink:YES];
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].pasteboardChecked);
#endif
}

- (void)processOpenResponseWithBundleToken:(NSString *)bundleToken isInstall:(BOOL)isInstall {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.pasteboardChecked = YES;

    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @200;
    response.data = bundleToken ? @{ BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: bundleToken } : @{};
    BranchRequestOpen *request = [[BranchRequestOpen alloc] initWithCallback:nil isInstall:isInstall];
    [request processResponse:response error:nil];

    preferenceHelper.randomizedBundleToken = savedBundleToken;
}

- (void)testInstallOpenSavingBundleTokenClearsPasteboardChecked {
    [self processOpenResponseWithBundleToken:@"new_bundle_token" isInstall:YES];
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].pasteboardChecked);
}

- (void)testInstallOpenWithoutBundleTokenKeepsPasteboardChecked {
    [self processOpenResponseWithBundleToken:nil isInstall:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].pasteboardChecked);
    [BNCPreferenceHelper sharedInstance].pasteboardChecked = NO;
}

- (void)testRequestOpenFirstLaunchSkipsPasteboard {
#if !TARGET_OS_TV
    [self addBranchURLToPasteboard];

    NSDictionary *json = [self payloadWithCheckOnInstall:YES firstLaunch:YES deepLink:NO];
    XCTAssertNil(json[BRANCH_REQUEST_KEY_LOCAL_URL]);

    [self clearPasteboard];
#endif
}

#if 0
// This test fails intermittently when executed with other tests - depending upon the order in which its executed
- (void) testPassPasteControl {
#if !TARGET_OS_TV
    if (@available(iOS 16.0, macCatalyst 16.0, *)) {

        long long timeStamp = ([[NSDate date] timeIntervalSince1970] - 5*60)*1000; // 5 minute earlier timestamp
        NSString *urlString = [NSString stringWithFormat:@"https://bnctestbed-alternate.app.link/9R7MbTmnRtb?__branch_flow_type=viewapp&__branch_flow_id=1105940563590163783&__branch_mobile_deepview_type=1&nl_opt_in=1&_cpts=%lld", timeStamp];
        NSURL *testURL = [[NSURL alloc] initWithString:urlString];

        NSArray<NSItemProvider *> *itemProviders = @[[[NSItemProvider alloc] initWithItem:testURL typeIdentifier:UTTypeURL.identifier]];
        XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];

        [[Branch sharedInstance] requestDeepLinkDataWithLaunchOptions:@{} callback:^(NSDictionary *params, NSError *error) {
            [openExpectation fulfill];
            XCTAssertNil(error);
        }];

        [[Branch sharedInstance] passPasteItemProviders:itemProviders];
        [self waitForExpectationsWithTimeout:5.0 handler:NULL];

    }
#endif
}
#endif

@end

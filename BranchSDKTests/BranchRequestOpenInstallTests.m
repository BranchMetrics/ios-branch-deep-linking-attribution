//
//  BranchRequestOpenInstallTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  EMT-4027: BranchRequestOpen is only ever constructed through -initWithCallback:, which
//  hardcodes isInstall:NO, so every install-gated behaviour is unreachable in production.
//  These tests drive the production construction path (Branch -sendOpen) rather than
//  instantiating the request directly, because the defect is in the construction.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BNCServerResponse.h"
#import "BNCSKAdNetwork.h"
#import "BranchRequestOpen.h"

@interface BNCServerRequestQueue (InstallIntrospectionTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end

// Records the SKAdNetwork calls the open response triggers instead of making them. The spy
// adds no ivars, so it can be swapped onto the existing singleton with object_setClass and
// swapped back in -tearDown. Recording is file-static for the same reason.
static NSMutableArray<NSNumber *> *sPostbackFineValues = nil;
static NSInteger sRegisterAppCallCount = 0;

@interface BNCSKAdNetworkSpy : BNCSKAdNetwork
@end

@implementation BNCSKAdNetworkSpy

- (void)registerAppForAdNetworkAttribution {
    sRegisterAppCallCount++;
}

- (void)updateConversionValue:(NSInteger)conversionValue {
    [sPostbackFineValues addObject:@(conversionValue)];
}

- (void)updatePostbackConversionValue:(NSInteger)conversionValue
                    completionHandler:(void (^)(NSError *error))completion {
    [sPostbackFineValues addObject:@(conversionValue)];
}

- (void)updatePostbackConversionValue:(NSInteger)fineValue
                          coarseValue:(NSString *)coarseValue
                           lockWindow:(BOOL)lockWindow
                    completionHandler:(void (^)(NSError *error))completion {
    [sPostbackFineValues addObject:@(fineValue)];
}

@end

static NSString * const kInstallLinkURL = @"https://example.app.link/install-link";
static NSString * const kClickedLinkPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":true,"
     "\"$canonical_identifier\":\"content/12345\",\"$og_title\":\"Install Content\","
     "\"~campaign\":\"beta launch\","
     "\"~referring_link\":\"https://example.app.link/install-link\"}";

@interface BranchRequestOpenInstallTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *fakeQueue;
@property (nonatomic, copy) NSString *savedBundleToken;
@property (nonatomic, copy) NSString *savedInstallParams;
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
@property (nonatomic, strong) NSDate *savedFirstAppLaunchTime;
@property (nonatomic, assign) NSInteger savedSkanWindow;
@property (nonatomic, assign) NSInteger savedHighestConversionValue;
@property (nonatomic, assign) BOOL savedInvokeRegisterApp;
// The stubbed open responses write real-looking session credentials. BNCServerRequestOperation
// drops a non-init request when these are missing, so leaving them behind lets later tests
// reach the network they would otherwise have skipped.
@property (nonatomic, copy) NSString *savedSessionID;
@property (nonatomic, copy) NSString *savedDeviceToken;
@end

@implementation BranchRequestOpenInstallTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedBundleToken = preferenceHelper.randomizedBundleToken;
    self.savedInstallParams = preferenceHelper.installParams;
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedFirstAppLaunchTime = preferenceHelper.firstAppLaunchTime;
    self.savedSkanWindow = preferenceHelper.skanCurrentWindow;
    self.savedHighestConversionValue = preferenceHelper.highestConversionValueSent;
    self.savedInvokeRegisterApp = preferenceHelper.invokeRegisterApp;
    self.savedSessionID = preferenceHelper.sessionID;
    self.savedDeviceToken = preferenceHelper.randomizedDeviceToken;

    // A first-ever launch: no bundle token yet, nothing attributed yet.
    preferenceHelper.randomizedBundleToken = nil;
    preferenceHelper.installParams = nil;
    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    // Pin the SKAN window to the first window with no conversion value sent yet, so the
    // open-only conversion path is deterministically eligible rather than incidentally
    // suppressed by ambient install-date state.
    preferenceHelper.firstAppLaunchTime = [NSDate date];
    preferenceHelper.skanCurrentWindow = 0;
    preferenceHelper.highestConversionValueSent = 0;
    preferenceHelper.invokeRegisterApp = NO;

    // BNCPreferenceHelper is a singleton backed by NSUserDefaults. installParams left over
    // from an earlier test would satisfy getFirstReferringParams without the code under test
    // ever writing it, so the clean slate is asserted rather than assumed.
    XCTAssertNil(preferenceHelper.installParams,
                 @"Precondition: installParams must be empty before the test runs.");
    XCTAssertNil(preferenceHelper.randomizedBundleToken,
                 @"Precondition: this must look like a first-ever launch.");

    sPostbackFineValues = [NSMutableArray array];
    sRegisterAppCallCount = 0;
    object_setClass([BNCSKAdNetwork sharedInstance], [BNCSKAdNetworkSpy class]);

    self.fakeQueue = [BNCServerRequestQueue new];
    self.fakeQueue.operationQueue.suspended = YES;
    [self.branch setValue:self.fakeQueue forKey:@"requestQueue"];
}

- (void)tearDown {
    object_setClass([BNCSKAdNetwork sharedInstance], [BNCSKAdNetwork class]);
    sPostbackFineValues = nil;
    sRegisterAppCallCount = 0;

    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    self.fakeQueue = nil;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.randomizedBundleToken = self.savedBundleToken;
    preferenceHelper.installParams = self.savedInstallParams;
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.firstAppLaunchTime = self.savedFirstAppLaunchTime;
    preferenceHelper.skanCurrentWindow = self.savedSkanWindow;
    preferenceHelper.highestConversionValueSent = self.savedHighestConversionValue;
    preferenceHelper.invokeRegisterApp = self.savedInvokeRegisterApp;
    preferenceHelper.sessionID = self.savedSessionID;
    preferenceHelper.randomizedDeviceToken = self.savedDeviceToken;
    preferenceHelper.referringURL = nil;

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

// The open request the SDK itself built for this launch. Reading it back from the queue is
// what makes these tests characterize the production construction rather than a hand-made
// request that could be given whatever isInstall value the test wanted.
- (BranchRequestOpen *)openRequestEnqueuedBySDK {
    for (NSOperation *op in self.fakeQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        id request = [op valueForKey:@"request"];
        if ([NSStringFromClass([request class]) isEqualToString:@"BranchRequestOpen"]) {
            return (BranchRequestOpen *)request;
        }
    }
    return nil;
}

- (BNCServerResponse *)openResponseWithExtras:(NSDictionary *)extras {
    NSMutableDictionary *data = [@{
        BRANCH_RESPONSE_KEY_SESSION_DATA: kClickedLinkPayloadJSON,
        BRANCH_RESPONSE_KEY_SESSION_ID: @"session_id",
        BRANCH_RESPONSE_KEY_RANDOMIZED_BUNDLE_TOKEN: @"bundle_token"
    } mutableCopy];
    [data addEntriesFromDictionary:extras];

    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    response.data = data;
    return response;
}

// Drives the launch the way the SDK does, then settles it with the given response.
- (BranchRequestOpen *)settleFirstLaunchOpenWithResponse:(BNCServerResponse *)response {
    [self.branch sendOpen];

    BranchRequestOpen *openRequest = [self openRequestEnqueuedBySDK];
    XCTAssertNotNil(openRequest, @"sendOpen must enqueue a BranchRequestOpen.");
    [openRequest processResponse:response error:nil];
    return openRequest;
}

#pragma mark - Tests

// getFirstReferringParams is backed by installParams, which is only written when the open
// knows it is an install. On the 4.0 path it never does, so first-referring attribution is
// empty for the lifetime of the app.
- (void)testFirstLaunchOpenWithClickedLinkPopulatesFirstReferringParams {
    [self settleFirstLaunchOpenWithResponse:[self openResponseWithExtras:@{}]];

    NSDictionary *firstParams = [self.branch getFirstReferringParams];
    XCTAssertTrue([firstParams[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"A first-ever launch attributed to a clicked link must be readable via getFirstReferringParams.");
    XCTAssertEqualObjects(firstParams[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kInstallLinkURL);
    XCTAssertEqualObjects(firstParams[@"$canonical_identifier"], @"content/12345");
    XCTAssertEqualObjects(firstParams[@"~campaign"], @"beta launch",
                          @"The whole install payload must be persisted, not just the fields the SDK reads internally.");
}

// The install registration is gated on the same isInstall flag.
- (void)testFirstLaunchOpenRegistersInstallWithAdNetwork {
    [self settleFirstLaunchOpenWithResponse:
        [self openResponseWithExtras:@{ BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP: @YES }]];

    BOOL registeredInstall = sRegisterAppCallCount > 0 || [sPostbackFineValues containsObject:@0];
    XCTAssertTrue(registeredInstall,
                  @"A first-ever launch must register the install with SKAdNetwork. Recorded postbacks: %@, registerApp calls: %ld.",
                  sPostbackFineValues, (long)sRegisterAppCallCount);
}

// The mirror image: the conversion-value update is explicitly gated on !isInstall, so with
// isInstall permanently NO it also fires on a first launch, where it must be suppressed.
- (void)testFirstLaunchOpenSuppressesTheOpenOnlyConversionValueUpdate {
    [self settleFirstLaunchOpenWithResponse:[self openResponseWithExtras:@{
        BRANCH_RESPONSE_KEY_INVOKE_REGISTER_APP: @YES,
        BRANCH_RESPONSE_KEY_UPDATE_CONVERSION_VALUE: @7
    }]];

    XCTAssertFalse([sPostbackFineValues containsObject:@7],
                   @"The open-only conversion value update must not fire on a first-ever launch. Recorded postbacks: %@.",
                   sPostbackFineValues);
}

// A genuine second launch must keep behaving like an open: no install params written.
- (void)testSecondLaunchOpenDoesNotOverwriteFirstReferringParams {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.randomizedBundleToken = @"existing_bundle_token";
    preferenceHelper.installParams = @"{\"+clicked_branch_link\":true,\"~campaign\":\"original install\"}";

    [self settleFirstLaunchOpenWithResponse:[self openResponseWithExtras:@{}]];

    NSDictionary *firstParams = [self.branch getFirstReferringParams];
    XCTAssertEqualObjects(firstParams[@"~campaign"], @"original install",
                          @"A later open must not overwrite the install attribution.");
}

@end

//
//  BranchRequestDeepLinkTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  Characterization tests for BranchRequestDeepLink and -requestDeepLinkData:callback:.
//  EMT-4023: the resolved link payload must survive deep link resolution.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "BNCServerRequestOperation.h"
#import "BNCServerResponse.h"
#import "BranchRequestDeepLink.h"
#import "BranchRequestOpen.h"

// Lets a test suspend the queue and inspect what was enqueued before it can hit the network.
@interface BNCServerRequestQueue (DeepLinkIntrospectionTest)
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@end

// -invokeFeatures: lives in the .m only; declare it so the stub below can override it.
@interface BranchRequestDeepLink (WebRedirectTest)
- (BOOL)invokeFeatures:(NSDictionary *)invokeFeatures;
@end

// Reports a web redirect as taken without actually opening a browser, so the early-return
// path in -processResponse: can be exercised without navigating away from the test host.
@interface BranchRequestDeepLinkWebRedirectStub : BranchRequestDeepLink
@end

@implementation BranchRequestDeepLinkWebRedirectStub
- (BOOL)invokeFeatures:(NSDictionary *)invokeFeatures {
    return YES;
}
@end

// The resolved link payload as measured off a real /v3/deeplink response: the "data" value
// is a JSON *string*, and carries +clicked_branch_link and ~referring_link.
static NSString * const kResolvedLinkURL = @"https://example.app.link/resolved-link";
static NSString * const kResolvedLinkPayloadJSON =
    @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,\"+match_guaranteed\":true,"
     "\"$canonical_identifier\":\"content/12345\",\"$og_title\":\"Resolved Content\","
     "\"~campaign\":\"beta launch\",\"~channel\":\"email\",\"~feature\":\"sharing\","
     "\"~referring_link\":\"https://example.app.link/resolved-link\"}";

@interface BranchRequestDeepLinkTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong) BNCServerRequestQueue *fakeQueue;
@property (nonatomic, copy) NSString *savedSessionParams;
@property (nonatomic, copy) NSString *savedAttributionLevel;
// The stubbed open response writes a real-looking session id. BNCServerRequestOperation drops
// a non-init request when the session credentials are missing, so leaving one behind lets
// later tests reach the network they would otherwise have skipped.
@property (nonatomic, copy) NSString *savedSessionID;
@property (nonatomic, copy) NSString *savedSpotlightIdentifier;
@end

@implementation BranchRequestDeepLinkTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedSessionParams = preferenceHelper.sessionParams;
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    self.savedSessionID = preferenceHelper.sessionID;
    self.savedSpotlightIdentifier = preferenceHelper.spotlightIdentifier;

    preferenceHelper.sessionParams = nil;
    preferenceHelper.referringURL = nil;
    // Deterministic regardless of ambient state: sendOpen is a no-op at level None.
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;

    // BNCPreferenceHelper is a singleton backed by NSUserDefaults. Residue from an earlier
    // test read back as if the code under test had written it would make the defect look
    // fixed, so the clean slate is asserted rather than assumed.
    XCTAssertNil(preferenceHelper.sessionParams,
                 @"Precondition: sessionParams must be empty before the test runs.");

    // A disposable, permanently-suspended queue. Requests enqueued during a test can be read
    // back without touching the network. Never cancel or resume it — cancelling a suspended,
    // never-started BNCServerRequestOperation trips an NSOperationQueue consistency check.
    self.fakeQueue = [BNCServerRequestQueue new];
    self.fakeQueue.operationQueue.suspended = YES;
    [self.branch setValue:self.fakeQueue forKey:@"requestQueue"];
}

- (void)tearDown {
    [self.branch setValue:[BNCServerRequestQueue getInstance] forKey:@"requestQueue"];
    self.fakeQueue = nil;

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.sessionParams = self.savedSessionParams;
    preferenceHelper.referringURL = nil;
    preferenceHelper.attributionLevel = self.savedAttributionLevel;
    preferenceHelper.sessionID = self.savedSessionID;
    preferenceHelper.spotlightIdentifier = self.savedSpotlightIdentifier;

    // Drain any already-scheduled async block against this clean baseline.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];

    self.branch = nil;
    [super tearDown];
}

#pragma mark - Helpers

// This project loads BNCServerRequestOperation from two images at once, so Class-pointer
// identity is unreliable here; name-based matching is not.
- (BNCServerRequest *)firstEnqueuedRequestOfClassNamed:(NSString *)className {
    for (NSOperation *op in self.fakeQueue.operationQueue.operations) {
        if (![NSStringFromClass([op class]) isEqualToString:@"BNCServerRequestOperation"]) continue;
        BNCServerRequest *request = [op valueForKey:@"request"];
        if ([NSStringFromClass([request class]) isEqualToString:className]) {
            return request;
        }
    }
    return nil;
}

- (BNCServerResponse *)responseWithData:(id)data {
    BNCServerResponse *response = [BNCServerResponse new];
    response.statusCode = @200;
    response.data = data;
    return response;
}

// What a real /v3/deeplink round trip delivers for a clicked Branch link.
- (BNCServerResponse *)resolvedDeepLinkResponse {
    return [self responseWithData:@{ BRANCH_RESPONSE_KEY_SESSION_DATA: kResolvedLinkPayloadJSON }];
}

#pragma mark - EMT-4023: resolved link data must be persisted

// The public read path for the resolved link. -processResponse: reads the payload only to
// pull ~referring_link out of it, and never writes preferenceHelper.sessionParams.
- (void)testDeepLinkResolutionPersistsResolvedParamsForLatestReferringParams {
    BranchRequestDeepLink *request = [[BranchRequestDeepLink alloc] initWithCallback:nil];
    request.urlString = kResolvedLinkURL;
    request.uri = kResolvedLinkURL;

    [request processResponse:[self resolvedDeepLinkResponse] error:nil];

    NSDictionary *params = [self.branch getLatestReferringParams];
    XCTAssertTrue([params[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"The resolved link payload must be readable via getLatestReferringParams once the deep link resolves.");
    XCTAssertEqualObjects(params[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
    XCTAssertEqualObjects(params[@"$canonical_identifier"], @"content/12345",
                          @"The whole payload must be persisted, not just the fields the SDK reads internally.");
}

// The app-facing contract: the callback handed to requestDeepLinkData: receives the link's
// params. It reads them back through getLatestReferringParams, so an unwritten
// sessionParams surfaces to the app as an empty dictionary.
- (void)testRequestDeepLinkDataCallbackReceivesResolvedParams {
    XCTestExpectation *expectation = [self expectationWithDescription:@"requestDeepLinkData callback invoked"];
    __block NSDictionary *receivedParams = nil;
    __block NSError *receivedError = nil;

    [self.branch requestDeepLinkData:kResolvedLinkURL callback:^(NSDictionary *params, NSError *error) {
        receivedParams = params;
        receivedError = error;
        [expectation fulfill];
    }];

    BranchRequestDeepLink *enqueued =
        (BranchRequestDeepLink *)[self firstEnqueuedRequestOfClassNamed:@"BranchRequestDeepLink"];
    XCTAssertNotNil(enqueued, @"requestDeepLinkData: must enqueue a deep link resolution request.");

    [enqueued processResponse:[self resolvedDeepLinkResponse] error:nil];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertNil(receivedError);
    XCTAssertTrue([receivedParams[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"The app's callback must receive the resolved link params, not an empty dictionary.");
    XCTAssertEqualObjects(receivedParams[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
    XCTAssertEqualObjects(receivedParams[@"$og_title"], @"Resolved Content");
    XCTAssertEqualObjects(receivedParams[@"~campaign"], @"beta launch");
}

// A /v3/deeplink response with no session data of its own must not erase what was already
// persisted -- the same non-destruction contract the open guard enforces, but exercised
// against -persistSessionParams:preferenceHelper:error: directly.
- (void)testDeepLinkResolutionWithoutSessionDataDoesNotEraseExistingParams {
    // Seeded by the test rather than by a preceding resolution, so the assertions below can
    // only be satisfied by the seed surviving -- this is a non-destruction contract.
    [BNCPreferenceHelper sharedInstance].sessionParams = kResolvedLinkPayloadJSON;

    BranchRequestDeepLink *request = [[BranchRequestDeepLink alloc] initWithCallback:nil];
    request.urlString = kResolvedLinkURL;
    request.uri = kResolvedLinkURL;

    [request processResponse:[self responseWithData:@{}] error:nil];

    NSDictionary *params = [self.branch getLatestReferringParams];
    XCTAssertTrue([params[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"A resolution response with no session data must leave the already-persisted params intact.");
    XCTAssertEqualObjects(params[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
}

// Same contract, but with a spotlight identifier set: the spotlight merge block must not turn
// a data-less response into a write that replaces the existing payload with just the identifier.
- (void)testDeepLinkResolutionWithoutSessionDataAndSpotlightIdentifierDoesNotEraseExistingParams {
    [BNCPreferenceHelper sharedInstance].sessionParams = kResolvedLinkPayloadJSON;
    [BNCPreferenceHelper sharedInstance].spotlightIdentifier = @"spotlight-id";

    BranchRequestDeepLink *request = [[BranchRequestDeepLink alloc] initWithCallback:nil];
    request.urlString = kResolvedLinkURL;
    request.uri = kResolvedLinkURL;

    [request processResponse:[self responseWithData:@{}] error:nil];

    NSDictionary *params = [self.branch getLatestReferringParams];
    XCTAssertTrue([params[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"A data-less response with a spotlight identifier set must not replace the existing payload with just the identifier.");
    XCTAssertEqualObjects(params[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
}

// The open that follows resolution carries no "data" key of its own. It must not wipe what
// the deep link resolution already established.
- (void)testOpenResponseWithoutDataDoesNotEraseResolvedParams {
    // Seeded by the test rather than by a preceding resolution, so the assertions below can
    // only be satisfied by the seed surviving — this is a non-destruction contract.
    [BNCPreferenceHelper sharedInstance].sessionParams = kResolvedLinkPayloadJSON;

    BranchRequestOpen *openRequest = [[BranchRequestOpen alloc] initWithCallback:nil];
    [openRequest processResponse:[self responseWithData:@{ BRANCH_RESPONSE_KEY_SESSION_ID: @"session_id" }]
                           error:nil];

    NSDictionary *params = [self.branch getLatestReferringParams];
    XCTAssertTrue([params[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"An open response with no session data must leave the already-resolved params intact.");
    XCTAssertEqualObjects(params[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
}

// The web-redirect branch returns early, before the point where the normal flow completes.
// Persistence must not be skipped just because the redirect suppressed the init callback.
- (void)testWebRedirectResolutionStillPersistsResolvedParams {
    BranchRequestDeepLinkWebRedirectStub *request =
        [[BranchRequestDeepLinkWebRedirectStub alloc] initWithCallback:nil];
    request.urlString = kResolvedLinkURL;
    request.uri = kResolvedLinkURL;

    BNCServerResponse *response = [self responseWithData:@{
        BRANCH_RESPONSE_KEY_SESSION_DATA: kResolvedLinkPayloadJSON,
        BRANCH_RESPONSE_KEY_INVOKE_FEATURES: @{
            BRANCH_RESPONSE_KEY_ENHANCED_WEB_LINK_UX: WEB_UX_EXTERNAL_BROWSER,
            BRANCH_RESPONSE_KEY_WEB_LINK_REDIRECT_URL: @"https://example.com/landing"
        }
    }];
    [request processResponse:response error:nil];

    NSDictionary *params = [self.branch getLatestReferringParams];
    XCTAssertTrue([params[BRANCH_RESPONSE_KEY_CLICKED_BRANCH_LINK] boolValue],
                  @"The web-redirect path returns early, but the resolved params must still be persisted.");
    XCTAssertEqualObjects(params[BRANCH_RESPONSE_KEY_BRANCH_REFERRING_LINK], kResolvedLinkURL);
    XCTAssertEqualObjects(params[@"$canonical_identifier"], @"content/12345");
}

@end

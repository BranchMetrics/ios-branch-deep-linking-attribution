//
//  BranchLinkBuilderTests.m
//  Branch-SDK-Tests
//
//  Created by Brandon Boothe on 8/31/26.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchLinkBuilder.h"
#import "BranchLinkBuilder+Private.h"
#import "BNCLinkData.h"
#import "BNCPreferenceHelper.h"
#import "BNCLinkCache.h"
#import "BNCServerInterface.h"
#import "BNCServerResponse.h"
#import "BNCServerRequestQueue.h"
#import "BranchConstants.h"
#import "NSError+Branch.h"
#import "BranchShortUrlRequest.h"
#import "BranchSpotlightUrlRequest.h"
#import "BranchUniversalObject.h"
#import "BranchLinkProperties.h"
// Exposes isolationQueue so a test can wait for the async terminal's work to drain.
#import "Branch+LinkGeneration.h"

#pragma mark - Fake server interface (seam B)

// Substituted for the real BNCServerInterface on a test-owned Branch, via
// -[Branch initWithInterface:queue:cache:preferenceHelper:key:] and the serverInterface property
// that Branch (LinkGeneration) exposes. BranchShortUrlSyncRequest takes the interface as a
// parameter of -makeRequest:key:, so overriding this one method substitutes the whole network layer
// with no KVC and no private-ivar access.
@interface BNCFakeServerInterface : BNCServerInterface
@property (nonatomic, assign) NSInteger requestCount;
@property (nonatomic, copy) NSDictionary *lastPostBody;
@property (nonatomic, copy) NSString *lastURL;
@property (nonatomic, copy) NSString *lastKey;
// Configured per test. When stubResponse is nil, -postRequestSynchronous:… returns nil, modelling
// the transport failing outright.
@property (nonatomic, strong) BNCServerResponse *stubResponse;
// Async path only; handed to the BNCServerCallback alongside stubResponse.
@property (nonatomic, strong) NSError *stubError;
@end

@implementation BNCFakeServerInterface

- (BNCServerResponse *)postRequestSynchronous:(NSDictionary *)post url:(NSString *)url key:(NSString *)key {
    self.requestCount += 1;
    self.lastPostBody = post;
    self.lastURL = url;
    self.lastKey = key;
    return self.stubResponse;
}

// The async requests (BranchShortUrlRequest and its BranchSpotlightUrlRequest subclass) post through
// -makeRequest:key:callback: rather than the synchronous variant. Recording both means a request the
// BNCRecordingRequestQueue captured can be driven to its callback by hand, so a test can assert on
// the outgoing body without ever running the real operation queue.
- (void)postRequest:(NSDictionary *)post url:(NSString *)url key:(NSString *)key callback:(BNCServerCallback)callback {
    self.requestCount += 1;
    self.lastPostBody = post;
    self.lastURL = url;
    self.lastKey = key;
    if (callback) callback(self.stubResponse, self.stubError);
}

+ (BNCServerResponse *)responseWithStatusCode:(NSInteger)statusCode url:(NSString *)url {
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @(statusCode);
    response.data = url ? @{BRANCH_RESPONSE_KEY_URL: url} : @{};
    return response;
}

@end

#pragma mark - Recording request queue

// Captures what the async terminals enqueue and, by not calling super, stops it from executing --
// so these tests observe the enqueue without any network activity.
@interface BNCRecordingRequestQueue : BNCServerRequestQueue
@property (nonatomic, strong) NSMutableArray<BNCServerRequest *> *enqueued;
@end

@implementation BNCRecordingRequestQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        _enqueued = [NSMutableArray array];
    }
    return self;
}

- (void)enqueue:(BNCServerRequest *)request {
    @synchronized (self) {
        [self.enqueued addObject:request];
    }
}

- (void)enqueue:(BNCServerRequest *)request withPriority:(NSOperationQueuePriority)priority {
    [self enqueue:request];
}

- (NSArray<BNCServerRequest *> *)snapshot {
    @synchronized (self) {
        return [self.enqueued copy];
    }
}

@end

#pragma mark - Recording pass-through interface

// Real networking, but records what came back so a failing live test can say *why* rather than only
// "got nil". Without this, a non-200 is indistinguishable from a transport failure at the assert.
@interface BNCRecordingServerInterface : BNCServerInterface
@property (nonatomic, strong) BNCServerResponse *lastResponse;
@end

@implementation BNCRecordingServerInterface

- (BNCServerResponse *)postRequestSynchronous:(NSDictionary *)post url:(NSString *)url key:(NSString *)key {
    BNCServerResponse *response = [super postRequestSynchronous:post url:url key:key];
    self.lastResponse = response;
    return response;
}

@end

// The live key BranchClassTests initializes with; the expected URL strings below embed it.
static NSString * const kTestBranchKey = @"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB";

// Base64 of the JSON for @{@"key": @"value"}.
static NSString * const kEncodedKeyValueParams = @"eyJrZXkiOiJ2YWx1ZSJ9";

@interface Branch (BranchLinkBuilderTest)
// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
+ (void)resetInitializationGuardForTesting;
@end

@interface BranchLinkBuilderTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, copy) NSString *savedUserUrl;
@end

@implementation BranchLinkBuilderTests

- (void)setUp {
    [super setUp];
    [self initializeBranch];
    // userUrl lives on the shared preference helper and is written by any open response, so the
    // app-link tests below both depend on it and would leak into later test classes. Snapshot it.
    self.savedUserUrl = [BNCPreferenceHelper sharedInstance].userUrl;
}

- (void)tearDown {
    [BNCPreferenceHelper sharedInstance].userUrl = self.savedUserUrl;
    // testBranchIsResolvedLazilyRatherThanAtInit clears the guard. Leave the process initialized so
    // the next test class finds the singleton in the same state BranchClassTests leaves it in.
    [self initializeBranch];
    [super tearDown];
}

- (void)initializeBranch {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"];
    self.branch = [Branch initialize:config];
}

// The link content, behavior and data the terminals take as an argument. Most tests below vary one
// option, so they build their own; this is the shared shape. The control params are the payload
// kEncodedKeyValueParams is the base64 of.
- (BranchLinkProperties *)linkPropertiesWithChannel:(NSString *)channel {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.channel = channel;
    linkProperties.controlParams = @{@"key": @"value"};
    return linkProperties;
}

#pragma mark - Defaults

// Every link option lives on BranchLinkProperties, so its defaults are what decide what a link
// with no options set sends. The builder itself holds no state.
- (void)testLinkPropertiesDefaults {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];

    XCTAssertNil(linkProperties.tags);
    XCTAssertNil(linkProperties.alias);
    XCTAssertNil(linkProperties.channel);
    XCTAssertNil(linkProperties.feature);
    XCTAssertNil(linkProperties.stage);
    XCTAssertNil(linkProperties.campaign);

    XCTAssertEqual(linkProperties.matchDuration, (NSUInteger)0);
    XCTAssertEqual(linkProperties.linkType, BranchLinkTypeUnlimitedUse);

    // Not nil: the getter lazily substitutes an empty dictionary. The builder has to treat that as
    // "no params" -- see testLinkDataTreatsEmptyControlParamsAsNoParams.
    XCTAssertEqualObjects(linkProperties.controlParams, @{});
}

// BranchLinkTypeUnlimitedUse is 0, which is what lets longUrlWithBaseUrl:'s `if (type)` guard omit
// `type=` for a default link. Pin the numeric value, not just the constant, so a reordering of the
// enum is caught here rather than as a wire-format change.
- (void)testDefaultLinkTypeIsZero {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    XCTAssertEqual((NSUInteger)linkProperties.linkType, (NSUInteger)0);
}

#pragma mark - Property round-trips

- (void)testControlParamsRoundTrip {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    NSDictionary *controlParams = @{@"$og_title": @"Sale", @"custom": @2};

    linkProperties.controlParams = controlParams;
    XCTAssertEqualObjects(linkProperties.controlParams, controlParams);

    // -addControlParam:withValue: rebuilds the dictionary rather than mutating it in place.
    [linkProperties addControlParam:@"$desktop_url" withValue:@"https://example.com"];
    XCTAssertEqualObjects(linkProperties.controlParams[@"$og_title"], @"Sale");
    XCTAssertEqualObjects(linkProperties.controlParams[@"$desktop_url"], @"https://example.com");
}

- (void)testLinkPropertiesRoundTrip {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    NSArray<NSString *> *tags = @[@"tag1", @"tag2"];

    linkProperties.tags = tags;
    linkProperties.alias = @"summer-sale";
    linkProperties.channel = @"sms";
    linkProperties.feature = @"share";
    linkProperties.stage = @"level_2";
    linkProperties.campaign = @"back-to-school";
    linkProperties.matchDuration = 300;
    linkProperties.linkType = BranchLinkTypeOneTimeUse;

    XCTAssertEqualObjects(linkProperties.tags, tags);
    XCTAssertEqualObjects(linkProperties.alias, @"summer-sale");
    XCTAssertEqualObjects(linkProperties.channel, @"sms");
    XCTAssertEqualObjects(linkProperties.feature, @"share");
    XCTAssertEqualObjects(linkProperties.stage, @"level_2");
    XCTAssertEqualObjects(linkProperties.campaign, @"back-to-school");
    XCTAssertEqual(linkProperties.matchDuration, (NSUInteger)300);
    XCTAssertEqual(linkProperties.linkType, BranchLinkTypeOneTimeUse);
}

// linkType is the option that moved onto BranchLinkProperties, so it also has to survive the
// dictionary round trip that populates a referring link's properties.
- (void)testLinkPropertiesFromDictionaryCarriesLinkType {
    BranchLinkProperties *linkProperties =
        [BranchLinkProperties getBranchLinkPropertiesFromDictionary:@{@"~type": @1}];

    XCTAssertEqual(linkProperties.linkType, BranchLinkTypeOneTimeUse);
}

- (void)testLinkPropertiesFromDictionaryWithoutLinkTypeKeepsTheDefault {
    BranchLinkProperties *linkProperties =
        [BranchLinkProperties getBranchLinkPropertiesFromDictionary:@{@"~channel": @"sms"}];

    XCTAssertEqual(linkProperties.linkType, BranchLinkTypeUnlimitedUse);
}

- (void)testLinkPropertiesDescriptionIncludesLinkType {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.linkType = BranchLinkTypeOneTimeUse;

    XCTAssertTrue([[linkProperties description] containsString:@"linkType: 1"],
                  @"%@", [linkProperties description]);
}

#pragma mark - Branch resolution

- (void)testInitWithBranchStoresTheInjectedInstance {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    XCTAssertIdentical(builder.branch, self.branch);
}

- (void)testInitWithNilBranchResolvesTheSharedInstance {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:nil];
    XCTAssertIdentical(builder.branch, [Branch sharedInstance]);
}

- (void)testInitMatchesInitWithNilBranch {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
    XCTAssertIdentical(builder.branch, [Branch sharedInstance]);
}

// +[Branch sharedInstance] logs a BNCInitError and returns nil when +initialize: has not run.
// Constructing a builder must not resolve it -- none of the overloads this builder replaces could
// fail at construction, since they were messages to an instance the caller already held.
// Resolution is deferred to the first `branch` read, which is inside a terminal.
- (void)testBranchIsResolvedLazilyRatherThanAtInit {
    [Branch resetInitializationGuardForTesting];

    BranchLinkBuilder *builder = nil;
    XCTAssertNoThrow(builder = [[BranchLinkBuilder alloc] init]);
    XCTAssertNotNil(builder);

    // The deferred resolution is what fails, and only when something actually needs the instance.
    XCTAssertNil([builder branch]);
}

// The async terminals dispatch onto branch.isolationQueue. With no instance to resolve that is a
// nil queue, and dispatch_async with a nil queue crashes the calling app rather than reporting
// anything -- so each terminal has to answer its own contract instead of passing nil along.
- (void)testTerminalsReportInitErrorRatherThanCrashingBeforeInitialize {
    [Branch resetInitializationGuardForTesting];

    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];

    XCTAssertNil([[[BranchLinkBuilder alloc] init] getShortURLWithLinkProperties:linkProperties],
                 @"The blocking terminal must report failure by returning nil.");

    XCTestExpectation *shortURLCalledBack = [self expectationWithDescription:@"async short URL"];
    [[[BranchLinkBuilder alloc] init] getShortURLWithParamsWithLinkProperties:linkProperties
                                                                    callback:^(NSString *url, NSError *error) {
        XCTAssertNil(url);
        XCTAssertEqual(error.code, BNCInitError);
        [shortURLCalledBack fulfill];
    }];

    XCTestExpectation *spotlightCalledBack = [self expectationWithDescription:@"spotlight URL"];
    [[[BranchLinkBuilder alloc] init] getSpotlightURLWithParams:@{@"key": @"value"}
                                                      callback:^(NSDictionary *params, NSError *error) {
        XCTAssertEqualObjects(params, @{});
        XCTAssertEqual(error.code, BNCInitError);
        [spotlightCalledBack fulfill];
    }];

    // A nil callback must be equally survivable: the crash was in the dispatch, not the callback.
    XCTAssertNoThrow([[[BranchLinkBuilder alloc] init] getShortURLWithParamsWithLinkProperties:linkProperties
                                                                                     callback:nil]);
    XCTAssertNoThrow([[[BranchLinkBuilder alloc] init] getSpotlightURLWithParams:nil callback:nil]);

    [self waitForExpectations:@[shortURLCalledBack, spotlightCalledBack] timeout:5.0];
}

// The long-URL terminal needs a Branch key and the preference-helper singleton, neither of which
// requires the Branch singleton -- so the one offline terminal stays usable before +initialize:.
- (void)testGetLongURLDoesNotRequireTheSharedInstance {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;
    [Branch resetInitializationGuardForTesting];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    NSString *url = nil;
    XCTAssertNoThrow(url = [builder getLongURLWithLinkProperties:nil useAppLinkDomain:NO]);

    NSString *expectedPrefix = [NSString stringWithFormat:@"https://bnc.lt/a/%@?", kTestBranchKey];
    XCTAssertTrue([url hasPrefix:expectedPrefix], @"%@", url);
}

- (void)testInjectedBranchIsUsedEvenWhenSharedInstanceIsUnavailable {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    Branch *injected = self.branch;

    [Branch resetInitializationGuardForTesting];

    XCTAssertIdentical(builder.branch, injected);
}

#pragma mark - getLongURLWithLinkProperties:useAppLinkDomain:

- (BranchLinkBuilder *)longURLBuilder {
    return [[BranchLinkBuilder alloc] initWithBranch:self.branch];
}

- (BranchLinkProperties *)fullyPopulatedLinkProperties {
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.controlParams = @{@"key": @"value"};
    linkProperties.tags = @[@"tag1", @"tag2"];
    linkProperties.alias = @"alias1";
    linkProperties.channel = @"channel1";
    linkProperties.feature = @"feature1";
    linkProperties.stage = @"stage1";
    return linkProperties;
}

// The exact string the deleted -getLongURLWithParams:andChannel:andTags:andFeature:andStage:andAlias:
// produced, plus channel=channel1& -- see testLongURLEmitsChannel.
- (void)testLongURLDefaultDomainExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:NO];

    XCTAssertEqualObjects(url, expected);
}

// The default domain is built without a trailing "?" and -sanitizedMutableBaseURL: adds the
// separator; the app-link branch pre-terminates with "?" instead. Both must yield exactly one "?".
- (void)testLongURLAppLinkDomainWithoutUserUrlExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:YES];

    XCTAssertEqualObjects(url, expected);
}

- (void)testLongURLAppLinkDomainWithUserUrlExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link/xyz789";

    NSString *expected = [NSString stringWithFormat:
        @"https://example.app.link/xyz789?tags=tag1&tags=tag2&alias=alias1&channel=channel1"
        @"&feature=feature1&stage=stage1&source=ios&data=%@", kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:YES];

    XCTAssertEqualObjects(url, expected);
}

// userUrl only matters when useAppLinkDomain is set; the default domain ignores it entirely.
- (void)testLongURLDefaultDomainIgnoresUserUrl {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link/xyz789";

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:NO];
    NSString *expectedPrefix = [NSString stringWithFormat:@"https://bnc.lt/a/%@?", kTestBranchKey];

    XCTAssertTrue([url hasPrefix:expectedPrefix], @"%@", url);
    XCTAssertFalse([url containsString:@"example.app.link"], @"%@", url);
}

// Decision 2: the methods this replaces accepted a channel and dropped it. The builder emits it.
- (void)testLongURLEmitsChannel {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?channel=channel1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self linkPropertiesWithChannel:@"channel1"]
                                                      useAppLinkDomain:NO];

    XCTAssertEqualObjects(url, expected);
}

- (void)testLongURLOmitsChannelWhenUnset {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:nil useAppLinkDomain:NO];

    XCTAssertFalse([url containsString:@"channel="], @"%@", url);
}

// BranchLinkTypeUnlimitedUse is 0 and matchDuration defaults to 0, and both are emitted behind
// truthiness guards, so default link properties must emit neither.
- (void)testLongURLOmitsTypeAndDurationAtDefaults {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:NO];

    XCTAssertFalse([url containsString:@"type="], @"%@", url);
    XCTAssertFalse([url containsString:@"duration="], @"%@", url);
}

// matchDuration is the property name; `duration` is the wire spelling -- the one
// BRANCH_REQUEST_KEY_URL_DURATION, the Web SDK and Android's ServerRequestCreateUrl all use.
- (void)testLongURLEmitsTypeAndDurationWhenSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkProperties *linkProperties = [self fullyPopulatedLinkProperties];
    linkProperties.linkType = BranchLinkTypeOneTimeUse;
    linkProperties.matchDuration = 300;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&type=1&duration=300&source=ios&data=%@",
        kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:linkProperties
                                                      useAppLinkDomain:NO];

    XCTAssertEqualObjects(url, expected);
}

// The methods this replaces had no campaign parameter, so a campaign never reached a long link.
// It does now, after `stage` and before `type`, matching Android's ServerRequestCreateUrl.
- (void)testLongURLEmitsCampaign {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkProperties *linkProperties = [self fullyPopulatedLinkProperties];
    linkProperties.campaign = @"back-to-school";

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&campaign=back-to-school&source=ios&data=%@",
        kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:linkProperties
                                                      useAppLinkDomain:NO];

    XCTAssertEqualObjects(url, expected);
}

- (void)testLongURLOmitsCampaignWhenUnset {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:NO];

    XCTAssertFalse([url containsString:@"campaign="], @"%@", url);
}

// Values go through +[BNCEncodingUtils stringByPercentEncodingStringForQuery:], which uses
// URLQueryAllowedCharacterSet -- the set legal *anywhere* in a query component. It escapes spaces
// but deliberately permits sub-delimiters, so "/" and "&" pass through unescaped and a channel
// containing "&" yields a structurally broken URL. That is long-standing SDK behavior, carried over
// verbatim by this port; pinned here so a future encoder change is a visible decision rather than a
// silent wire-format change.
- (void)testLongURLEncodesValuesWithURLQueryAllowedCharacterSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"a b&c"];
    linkProperties.tags = @[@"x/y"];

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=x/y&channel=a%%20b&c&source=ios&data=%@",
        kTestBranchKey, kEncodedKeyValueParams];

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:linkProperties
                                                      useAppLinkDomain:NO];

    XCTAssertEqualObjects(url, expected);
}

- (void)testLongURLWithNoOptionsSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    NSString *url = [builder getLongURLWithLinkProperties:nil useAppLinkDomain:NO];
    NSString *expectedPrefix = [NSString stringWithFormat:@"https://bnc.lt/a/%@?source=ios&data=", kTestBranchKey];

    XCTAssertTrue([url hasPrefix:expectedPrefix], @"%@", url);
}

// The base64 alphabet includes "+", which a server decodes as a space -- so an unencoded data=
// blob loses the params it exists to carry. A "+" needs a byte of ">" or "~", or any multi-byte
// UTF-8, at an offset of 3n+2; the HTML email params make that ordinary rather than exotic.
- (void)testLongURLPercentEncodesTheBase64DataParameter {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.controlParams = @{BRANCH_LINK_DATA_KEY_EMAIL_HTML_HEADER: @"<style>a{color:red}</style>"};

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    NSString *url = [builder getLongURLWithLinkProperties:linkProperties useAppLinkDomain:NO];
    NSString *data = [url componentsSeparatedByString:@"&data="].lastObject;

    XCTAssertTrue([data containsString:@"%2B"], @"expected an escaped '+', got %@", url);

    NSCharacterSet *rawBase64Punctuation = [NSCharacterSet characterSetWithCharactersInString:@"+/="];
    XCTAssertEqual([data rangeOfCharacterFromSet:rawBase64Punctuation].location, (NSUInteger)NSNotFound,
                   @"data= must carry no raw base64 punctuation: %@", url);

    NSString *decoded = [data stringByRemovingPercentEncoding];
    NSDictionary *roundTripped = [NSJSONSerialization JSONObjectWithData:[[NSData alloc] initWithBase64EncodedString:decoded options:0]
                                                                 options:0
                                                                   error:nil];
    XCTAssertEqualObjects(roundTripped, linkProperties.controlParams);
}

// -sanitizedMutableBaseURL: strips a randomized bundle token at attribution level NONE. That must
// not cost the "?" separator, or every query parameter fuses onto the Branch key.
- (void)testLongURLIsWellFormedAtAttributionLevelNone {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;
    NSString *savedLevel = [BNCPreferenceHelper sharedInstance].attributionLevel;
    [BNCPreferenceHelper sharedInstance].attributionLevel = BranchAttributionLevelNone;

    NSString *url = [[self longURLBuilder] getLongURLWithLinkProperties:[self fullyPopulatedLinkProperties]
                                                      useAppLinkDomain:NO];

    [BNCPreferenceHelper sharedInstance].attributionLevel = savedLevel;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects(url, expected,
                          @"the query separator must survive the randomized-token strip");
}

#pragma mark - Short URL — link data / cache key

// BNCLinkCache keys on -[BNCLinkData hash], so the exact setupX: sequence the builder uses is what
// decides whether links cached by earlier SDK versions are still found. Compared against a
// hand-constructed BNCLinkData rather than against the old overload, so this test survives Step 8's
// deletion of that overload.
- (void)testLinkDataMatchesTheDocumentedSetupSequence {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];

    BranchLinkProperties *linkProperties = [self fullyPopulatedLinkProperties];
    linkProperties.campaign = @"campaign1";
    linkProperties.matchDuration = 300;
    linkProperties.linkType = BranchLinkTypeOneTimeUse;

    BNCLinkData *expected = [[BNCLinkData alloc] init];
    [expected setupType:BranchLinkTypeOneTimeUse];
    [expected setupTags:@[@"tag1", @"tag2"]];
    [expected setupChannel:@"channel1"];
    [expected setupFeature:@"feature1"];
    [expected setupStage:@"stage1"];
    [expected setupCampaign:@"campaign1"];
    [expected setupAlias:@"alias1"];
    [expected setupMatchDuration:300];
    [expected setupIgnoreUAString:nil];
    [expected setupParams:@{@"key": @"value"}];

    BNCLinkData *actual = [builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil];

    XCTAssertEqual([actual hash], [expected hash]);
    XCTAssertEqualObjects(actual.data, expected.data);
}

// ignoreUAString reaches the wire payload...
- (void)testIgnoreUAStringReachesTheLinkDataPayload {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    BNCLinkData *linkData = [builder linkDataWithLinkProperties:nil
                                                ignoreUAString:@"Slackbot-LinkExpanding"];

    XCTAssertEqualObjects(linkData.data[BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING], @"Slackbot-LinkExpanding");
}

// ...and the cache key. A link created with an ignoreUAString does not count its first click, so it
// must never be served to a later call that did not ask for one.
- (void)testIgnoreUAStringAffectsTheCacheKey {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"channel1"];

    BNCLinkData *withUA = [builder linkDataWithLinkProperties:linkProperties
                                              ignoreUAString:@"Slackbot-LinkExpanding"];
    BNCLinkData *withoutUA = [builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil];

    XCTAssertNotEqual([withUA hash], [withoutUA hash]);
    XCTAssertNotEqualObjects(withUA.data, withoutUA.data);
}

// -[BranchLinkProperties controlParams] lazily returns an empty dictionary, and
// -[BNCLinkData setupParams:] only skips a *nil* one -- so passing it straight through would start
// sending "data": {} on every optionless link, where the deleted overloads sent no data key at all.
- (void)testLinkDataTreatsEmptyControlParamsAsNoParams {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.channel = @"sms";

    BNCLinkData *linkData = [builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil];

    XCTAssertNil(linkData.data[BRANCH_REQUEST_KEY_URL_DATA]);
    XCTAssertEqualObjects(linkData.data[BRANCH_REQUEST_KEY_URL_CHANNEL], @"sms");
}

// ...and the same request body, which is what the server sees.
- (void)testEmptyControlParamsSendNoDataKey {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.channel = @"sms";

    [builder getShortURLWithLinkProperties:linkProperties];

    XCTAssertEqual(fake.requestCount, 1);
    XCTAssertNil(fake.lastPostBody[BRANCH_REQUEST_KEY_URL_DATA]);
}

// The link properties the builder reads come from the argument, so nil must be equivalent to a
// BranchLinkProperties with nothing set rather than a special case.
- (void)testNilLinkPropertiesMatchDefaultLinkProperties {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];

    BNCLinkData *fromNil = [builder linkDataWithLinkProperties:nil ignoreUAString:nil];
    BNCLinkData *fromDefaults = [builder linkDataWithLinkProperties:[[BranchLinkProperties alloc] init]
                                                    ignoreUAString:nil];

    XCTAssertEqual([fromNil hash], [fromDefaults hash]);
    XCTAssertEqualObjects(fromNil.data, fromDefaults.data);
}

#pragma mark - Short URL — blocking, network (stubbed)

// A Branch wired to a fake server interface, with its own link cache and request queue so nothing
// here touches the shared singleton state.
- (Branch *)branchWithFakeInterface:(BNCFakeServerInterface *)fake linkCache:(BNCLinkCache *)linkCache {
    return [[Branch alloc] initWithInterface:fake
                                       queue:[[BNCServerRequestQueue alloc] init]
                                       cache:linkCache
                            preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                         key:kTestBranchKey];
}

- (void)testGetShortURLReturnsServerURLAndCachesIt {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties], @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1);

    // -[BranchShortUrlSyncRequest processResponse:] caches on a 200, so the second call must not
    // reach the network.
    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties], @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1, @"second call should have been served from the cache");
    XCTAssertEqualObjects([linkCache objectForKey:[builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil]],
                          @"https://example.app.link/abc123");
}

// The one-argument terminal chains into the ignoreUAString: variant with nil, so both must produce
// the same link data -- otherwise the two would key the shared cache differently.
- (void)testGetShortURLChainsIntoTheIgnoreUAStringVariantWithNil {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties ignoreUAString:nil],
                          @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1);

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties],
                          @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1, @"the chained call must hit the same cache entry");
}

// Behavior #3: an ignoreUAString bypasses the cache *read*, so a request is issued even when a
// cached link for the same key already exists.
- (void)testGetShortURLWithIgnoreUAStringBypassesTheCacheRead {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];

    [builder getShortURLWithLinkProperties:linkProperties];
    XCTAssertEqual(fake.requestCount, 1);

    [builder getShortURLWithLinkProperties:linkProperties ignoreUAString:@"Slackbot-LinkExpanding"];
    XCTAssertEqual(fake.requestCount, 2, @"ignoreUAString must force a fresh request");

    // ...and again, every time: the read is skipped even though the entry is now keyed separately.
    [builder getShortURLWithLinkProperties:linkProperties ignoreUAString:@"Slackbot-LinkExpanding"];
    XCTAssertEqual(fake.requestCount, 3);
}

// The cache-key isolation has to hold end to end -- an ignoreUAString link must not become the
// answer to a later ordinary fetch, whose first click is supposed to be counted.
- (void)testIgnoreUAStringLinkIsNotServedToAnOrdinaryFetch {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/ignore-ua"];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties ignoreUAString:@"Slackbot-LinkExpanding"],
                          @"https://example.app.link/ignore-ua");

    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/ordinary"];

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties], @"https://example.app.link/ordinary");
    XCTAssertEqual(fake.requestCount, 2);
}

// This branch has no layer1-logger-tests.yml, so these are the only assertions on the outgoing
// short-link request body that exist anywhere.
- (void)testGetShortURLRequestBody {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];

    BranchLinkProperties *linkProperties = [self fullyPopulatedLinkProperties];
    linkProperties.campaign = @"campaign1";
    linkProperties.matchDuration = 300;
    linkProperties.linkType = BranchLinkTypeOneTimeUse;

    [builder getShortURLWithLinkProperties:linkProperties ignoreUAString:@"Slackbot-LinkExpanding"];

    NSDictionary *body = fake.lastPostBody;
    XCTAssertNotNil(body);
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_TAGS], (@[@"tag1", @"tag2"]));
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_ALIAS], @"alias1");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_CHANNEL], @"channel1");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_FEATURE], @"feature1");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_STAGE], @"stage1");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_CAMPAIGN], @"campaign1");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_DURATION], @300);
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_LINK_TYPE], @(BranchLinkTypeOneTimeUse));
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING], @"Slackbot-LinkExpanding");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"value"});
    XCTAssertEqualObjects(fake.lastKey, kTestBranchKey);
}

// Non-200 falls back to a long link built from userUrl (BranchShortUrlSyncRequest.m:66-77).
- (void)testGetShortURLNon200FallsBackToLongURLWhenUserUrlIsSet {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link";

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:500 url:nil];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];

    NSString *url = [builder getShortURLWithLinkProperties:[self linkPropertiesWithChannel:@"channel1"]];

    XCTAssertNotNil(url);
    XCTAssertTrue([url hasPrefix:@"https://example.app.link?"], @"%@", url);
    XCTAssertTrue([url containsString:@"channel=channel1&"], @"%@", url);
    XCTAssertTrue([url containsString:@"source=ios&data="], @"%@", url);
}

// The fallback is a degraded result, not an answer. Caching it would make one transient failure
// permanent for the process, for the async terminal too since both share the cache.
- (void)testGetShortURLDoesNotCacheTheNon200Fallback {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link";

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:500 url:nil];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"channel1"];

    XCTAssertNotNil([builder getShortURLWithLinkProperties:linkProperties]);
    XCTAssertNil([linkCache objectForKey:[builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil]]);

    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    XCTAssertEqualObjects([builder getShortURLWithLinkProperties:linkProperties], @"https://example.app.link/abc123",
                          @"the retry must reach the network rather than return the cached fallback");
    XCTAssertEqual(fake.requestCount, 2);
}

// ...and returns nil when no link domain is known, which is exactly why a short-URL test may not
// assert merely on an "https://" prefix: the same failure yields a URL or nil depending on
// whether an earlier test happened to populate userUrl.
- (void)testGetShortURLNon200ReturnsNilWhenUserUrlIsUnset {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:500 url:nil];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];

    XCTAssertNil([builder getShortURLWithLinkProperties:[self linkPropertiesWithChannel:@"channel1"]]);
}

- (void)testGetShortURLReturnsNilWhenTransportReturnsNoResponse {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];

    XCTAssertNil([builder getShortURLWithLinkProperties:nil]);
    XCTAssertEqual(fake.requestCount, 1);
}

// A 200 whose body carries no url key: nothing to return, nothing to cache.
- (void)testGetShortURL200WithoutURLReturnsNilAndCachesNothing {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:nil];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];

    XCTAssertNil([builder getShortURLWithLinkProperties:nil]);
    XCTAssertNil([linkCache objectForKey:[builder linkDataWithLinkProperties:nil ignoreUAString:nil]]);
}

#pragma mark - Short URL — async

// A Branch whose request queue records instead of executing, so the async terminal can be observed
// without a network call.
- (Branch *)branchWithRecordingQueue:(BNCRecordingRequestQueue *)queue linkCache:(BNCLinkCache *)linkCache {
    return [[Branch alloc] initWithInterface:[[BNCFakeServerInterface alloc] init]
                                       queue:queue
                                       cache:linkCache
                            preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                         key:kTestBranchKey];
}

- (void)testAsyncShortURLEnqueuesRequestOnCacheMiss {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    [builder getShortURLWithParamsWithLinkProperties:[self linkPropertiesWithChannel:@"sms"]
                                           callback:^(NSString *url, NSError *error) { }];

    // The body runs on the isolation queue, so wait for it to drain rather than asserting inline.
    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    NSArray *enqueued = [queue snapshot];
    XCTAssertEqual(enqueued.count, (NSUInteger)1);
    XCTAssertTrue([enqueued.firstObject isKindOfClass:[BranchShortUrlRequest class]]);
}

// Behavior #5: the cache-hit callback hops to the main queue explicitly. On a miss that is
// BranchShortUrlRequest's responsibility; on a hit nothing else would do it.
- (void)testAsyncShortURLCacheHitCallsBackOnMainQueueAndEnqueuesNothing {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];
    [linkCache setObject:@"https://example.app.link/cached"
                  forKey:[builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    __block NSError *deliveredError = nil;
    __block BOOL onMainThread = NO;

    [builder getShortURLWithParamsWithLinkProperties:linkProperties
                                           callback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        deliveredError = error;
        onMainThread = [NSThread isMainThread];
        [calledBack fulfill];
    }];

    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertTrue(onMainThread, @"cache-hit callback must be delivered on the main queue");
    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/cached");
    XCTAssertNil(deliveredError);
    XCTAssertEqual([queue snapshot].count, (NSUInteger)0, @"a cache hit must not reach the queue");
}

// The async terminal hardcodes ignoreUAString:nil into its BNCLinkData, so its cache key is the one
// the blocking terminal produces for a nil ignoreUAString -- the two share the cache.
- (void)testAsyncShortURLSharesTheCacheKeyWithTheBlockingTerminal {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];
    [linkCache setObject:@"https://example.app.link/cached"
                  forKey:[builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    [builder getShortURLWithParamsWithLinkProperties:linkProperties
                                           callback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        [calledBack fulfill];
    }];
    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/cached");
    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

// The terminal snapshots its options at call time, not when the isolation-queue block runs. The
// funnel this replaces got them as method arguments, so a caller mutating the link properties
// immediately after the call could not affect the in-flight request.
//
// Verified through the cache: the cache lookup uses the BNCLinkData built from the snapshot, so a
// hit proves the pre-mutation values were used.
- (void)testAsyncShortURLSnapshotsOptionsAtCallTime {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"sms"];
    [linkCache setObject:@"https://example.app.link/sms"
                  forKey:[builder linkDataWithLinkProperties:linkProperties ignoreUAString:nil]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    [builder getShortURLWithParamsWithLinkProperties:linkProperties
                                           callback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        [calledBack fulfill];
    }];

    // Mutate immediately, before the isolation-queue block can have run. Only "email" is cached-miss;
    // if the block read the link properties late it would miss the cache and enqueue instead.
    linkProperties.channel = @"email";

    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/sms",
                          @"the request must use the options as of the call, not the mutated ones");
    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

- (void)testAsyncShortURLAcceptsNilCallback {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    XCTAssertNoThrow([builder getShortURLWithParamsWithLinkProperties:[self linkPropertiesWithChannel:@"sms"]
                                                            callback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    // The link is still requested; only the delivery is skipped.
    XCTAssertEqual([queue snapshot].count, (NSUInteger)1);
}

// A nil callback on a cache hit returns early without ever dispatching to main.
- (void)testAsyncShortURLNilCallbackOnCacheHitDoesNothing {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    [linkCache setObject:@"https://example.app.link/cached"
                  forKey:[builder linkDataWithLinkProperties:nil ignoreUAString:nil]];

    XCTAssertNoThrow([builder getShortURLWithParamsWithLinkProperties:nil callback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

// Link creation carries no attribution and BNCServerInterface whitelists /v1/url at attribution
// level NONE, so the request has to survive BNCServerRequestOperation's gate to reach that check.
// A dropped operation never runs -processResponse:error:, which is where the callback lives, so a
// drop here does not fail the call -- it strands the caller forever.
- (void)testAsyncShortURLStillCallsBackAtAttributionLevelNone {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSString *savedLevel = preferenceHelper.attributionLevel;
    NSString *savedDeviceToken = preferenceHelper.randomizedDeviceToken;
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.randomizedDeviceToken = @"device_token";
    preferenceHelper.randomizedBundleToken = @"bundle_token";
    preferenceHelper.attributionLevel = BranchAttributionLevelNone;

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    BNCServerRequestQueue *queue = [[BNCServerRequestQueue alloc] init];
    [queue configureWithServerInterface:fake branchKey:kTestBranchKey preferenceHelper:preferenceHelper];

    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:preferenceHelper
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    [builder getShortURLWithParamsWithLinkProperties:[self linkPropertiesWithChannel:@"sms"]
                                           callback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        [calledBack fulfill];
    }];
    [self waitForExpectations:@[calledBack] timeout:5];

    preferenceHelper.attributionLevel = savedLevel;
    preferenceHelper.randomizedDeviceToken = savedDeviceToken;
    preferenceHelper.randomizedBundleToken = savedBundleToken;

    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1);
}

#pragma mark - getSpotlightURLWithParams:callback:

// Drives a request the recording queue captured through to its callback against the fake interface,
// so the outgoing body can be asserted without running the real operation queue. The async requests
// post through -postRequest:url:key:callback:, which BNCFakeServerInterface also records.
- (void)deliver:(BNCServerRequest *)request
      interface:(BNCFakeServerInterface *)fake
       response:(BNCServerResponse *)response
          error:(NSError *)error {
    fake.stubResponse = response;
    fake.stubError = error;
    [request makeRequest:fake key:kTestBranchKey callback:^(BNCServerResponse *r, NSError *e) {
        [request processResponse:r error:e];
    }];
}

- (Branch *)branchWithRecordingQueue:(BNCRecordingRequestQueue *)queue fakeInterface:(BNCFakeServerInterface *)fake {
    return [[Branch alloc] initWithInterface:fake
                                       queue:queue
                                       cache:[[BNCLinkCache alloc] init]
                            preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                         key:kTestBranchKey];
}

- (void)testSpotlightURLEnqueuesSpotlightRequest {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    [builder getSpotlightURLWithParams:@{@"key": @"value"} callback:^(NSDictionary *params, NSError *error) { }];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    NSArray *enqueued = [queue snapshot];
    XCTAssertEqual(enqueued.count, (NSUInteger)1);
    XCTAssertTrue([enqueued.firstObject isKindOfClass:[BranchSpotlightUrlRequest class]]);
    XCTAssertTrue([(BranchSpotlightUrlRequest *)enqueued.firstObject isSpotlightRequest]);
}

// The only wire assertions for the spotlight body that exist anywhere -- this branch has no
// layer1-logger-tests.yml. Note the fixed channel, and that isSpotlightRequest suppresses the
// randomized *bundle* token while keeping the device token
// (BNCRequestFactory.m addShortURLTokensToJSON:isSpotlightRequest:).
- (void)testSpotlightURLRequestBody {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue fakeInterface:fake];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    [builder getSpotlightURLWithParams:@{@"key": @"value"} callback:nil];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    NSDictionary *body = fake.lastPostBody;
    XCTAssertNotNil(body);
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_CHANNEL], @"spotlight");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"value"});
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_SOURCE], @"ios");
    XCTAssertNil(body[BRANCH_REQUEST_KEY_RANDOMIZED_BUNDLE_TOKEN],
                 @"a spotlight request omits the randomized bundle token");
    XCTAssertEqualObjects(fake.lastKey, kTestBranchKey);
}

// A Spotlight link's shape is fixed by BranchSpotlightUrlRequest, so the terminal takes no link
// properties at all and its data payload is the argument. Nothing about an ordinary link can reach
// this body.
- (void)testSpotlightURLSendsOnlyItsArgumentAndTheFixedChannel {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue fakeInterface:fake];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    [builder getSpotlightURLWithParams:@{@"key": @"from-the-argument"} callback:nil];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    NSDictionary *body = fake.lastPostBody;
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"from-the-argument"});
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_CHANNEL], @"spotlight");
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_TAGS]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_ALIAS]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_STAGE]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_CAMPAIGN]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_DURATION]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_LINK_TYPE]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING]);
}

// Unlike the two short-URL terminals, the spotlight callback receives the server's whole payload --
// Core Spotlight needs the accompanying fields, not just the URL.
- (void)testSpotlightURLDeliversTheWholeResponsePayload {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue fakeInterface:fake];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    __block NSDictionary *deliveredParams = nil;
    __block NSError *deliveredError = nil;
    [builder getSpotlightURLWithParams:@{@"key": @"value"} callback:^(NSDictionary *params, NSError *error) {
        deliveredParams = params;
        deliveredError = error;
    }];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    XCTAssertEqualObjects(deliveredParams[BRANCH_RESPONSE_KEY_URL], @"https://example.app.link/spot");
    XCTAssertNil(deliveredError);
}

// On an error the callback gets an empty dictionary plus the error, not nil -- pinned because a
// caller checking `if (params)` rather than `if (error)` would otherwise silently change behavior.
- (void)testSpotlightURLOnErrorDeliversAnEmptyDictionaryAndTheError {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue fakeInterface:fake];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    __block NSDictionary *deliveredParams = nil;
    __block NSError *deliveredError = nil;
    [builder getSpotlightURLWithParams:@{@"key": @"value"} callback:^(NSDictionary *params, NSError *error) {
        deliveredParams = params;
        deliveredError = error;
    }];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    NSError *stubError = [NSError errorWithDomain:@"BranchLinkBuilderTests" code:42 userInfo:nil];
    [self deliver:[queue snapshot].firstObject interface:fake response:nil error:stubError];

    XCTAssertNotNil(deliveredParams);
    XCTAssertEqual(deliveredParams.count, (NSUInteger)0);
    XCTAssertEqualObjects(deliveredError, stubError);
}

// The params dictionary is handed to BranchSpotlightUrlRequest as-is, not copied, so a caller that
// keeps mutating it after the call changes the request that is still in flight. That is the behavior
// of the -getSpotlightUrlWithParams:callback: overload this replaces, carried over verbatim; pinned
// here so adding a defensive copy is a visible decision rather than a silent change.
- (void)testSpotlightURLDoesNotCopyItsParamsDictionary {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue fakeInterface:fake];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"key": @"at-call-time"}];
    [builder getSpotlightURLWithParams:params callback:nil];

    params[@"key"] = @"mutated";

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    XCTAssertEqualObjects(fake.lastPostBody[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"mutated"});
}

// BranchSpotlightUrlRequest is constructed with linkCache:nil, so spotlight links neither read nor
// write the cache the two short-URL terminals share.
- (void)testSpotlightURLDoesNotUseTheLinkCache {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    // A cached entry under the key the short-URL terminals would use for these options.
    [linkCache setObject:@"https://example.app.link/cached"
                  forKey:[builder linkDataWithLinkProperties:nil ignoreUAString:nil]];

    [builder getSpotlightURLWithParams:@{@"key": @"value"} callback:nil];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)1,
                   @"a cached short link must not short-circuit a spotlight request");
}

- (void)testSpotlightURLAcceptsNilCallbackAndNilParams {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    XCTAssertNoThrow([builder getSpotlightURLWithParams:nil callback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)1);
}

#pragma mark - Short URL — live smoke test

// Replaces BranchClassTests' testGetShortURL. That test asserted only hasPrefix:@"https://", which
// the non-200 long-URL fallback also satisfies -- so it could not fail for the reason it existed,
// and whether it passed depended on whether an earlier test had populated userUrl. This asserts the
// result is a *short* link on a Branch domain, which the fallback cannot satisfy: the fallback
// carries a "source=ios&data=" query, and with userUrl cleared it returns nil outright.
//
// Runs on a background queue because the blocking terminal blocks. This is the only test here that
// touches the real network, so it is skipped by the BranchSDKTests plan -- the one verify.yml runs --
// and selected by BranchSDKTestsLiveNetwork.xctestplan instead.
- (void)testGetShortURLLiveSmokeTest {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.userUrl = nil;

    // Other test classes write placeholder device/bundle tokens into the shared preference helper
    // (e.g. BranchClassTests sets randomizedBundleToken = @"some_token"), and BNCPreferenceHelper
    // persists to the BNCPreferences archive on disk -- so the junk survives across whole test runs
    // and the API rejects the request with 400 "randomized_device_token doesn't pass regex".
    // Clearing them makes the SDK omit both fields, which the API accepts. Restored below.
    NSString *savedDeviceToken = preferenceHelper.randomizedDeviceToken;
    NSString *savedBundleToken = preferenceHelper.randomizedBundleToken;
    preferenceHelper.randomizedDeviceToken = nil;
    preferenceHelper.randomizedBundleToken = nil;

    BNCRecordingServerInterface *recorder = [[BNCRecordingServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:recorder
                                                 queue:[[BNCServerRequestQueue alloc] init]
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    BranchLinkProperties *linkProperties = [self linkPropertiesWithChannel:@"unit-test"];
    linkProperties.feature = @"EMT-4069-smoke";
    // Defeat the link cache so this exercises the network even if an earlier test cached a link.
    linkProperties.stage = [[NSUUID UUID] UUIDString];

    XCTestExpectation *done = [self expectationWithDescription:@"live short URL"];
    __block NSString *shortURL = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        shortURL = [builder getShortURLWithLinkProperties:linkProperties];
        [done fulfill];
    });
    [self waitForExpectations:@[done] timeout:30];

    preferenceHelper.randomizedDeviceToken = savedDeviceToken;
    preferenceHelper.randomizedBundleToken = savedBundleToken;

    NSString *diagnosis = [NSString stringWithFormat:@"status=%@ data=%@",
                           recorder.lastResponse.statusCode, recorder.lastResponse.data];

    XCTAssertNotNil(shortURL, @"live short-link request returned nil (%@)", diagnosis);
    XCTAssertTrue([shortURL containsString:@"bnc.lt"] || [shortURL containsString:@"app.link"],
                  @"expected a Branch link domain, got %@ (%@)", shortURL, diagnosis);
    XCTAssertFalse([shortURL containsString:@"source=ios&data="],
                   @"got the long-URL fallback, not a short link: %@ (%@)", shortURL, diagnosis);
}

#pragma mark - Migrated caller: BranchUniversalObject

// BranchUniversalObject's link methods were rewritten onto the builder in Step 7. Their signatures
// did not change, so these guard the option assembly rather than the API.
//
// The seam is the shared link cache: the blocking terminal reads it before going to the network, so
// seeding it under exactly the options BranchUniversalObject is expected to produce turns "did it
// build the right BNCLinkData?" into a hit-or-miss with no network call. BNCLinkCache keys on
// -[BNCLinkData hash], so one wrong option is a different key and a miss.
- (void)seedSharedLinkCacheWithURL:(NSString *)url linkProperties:(BranchLinkProperties *)linkProperties {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
    [[Branch sharedInstance].linkCache setObject:url
                                          forKey:[builder linkDataWithLinkProperties:linkProperties
                                                                      ignoreUAString:nil]];
}

- (BranchUniversalObject *)universalObjectForLinkTests {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    buo.title = @"Title";
    return buo;
}

// What BranchUniversalObject is expected to hand the builder: the caller's link properties with the
// control params replaced by the full server-request payload.
- (BranchLinkProperties *)expectedRequestPropertiesFor:(BranchUniversalObject *)buo
                                        linkProperties:(BranchLinkProperties *)linkProperties {
    BranchLinkProperties *expected = [[BranchLinkProperties alloc] init];
    expected.tags = linkProperties.tags;
    expected.alias = linkProperties.alias;
    expected.channel = linkProperties.channel;
    expected.feature = linkProperties.feature;
    expected.stage = linkProperties.stage;
    expected.campaign = linkProperties.campaign;
    expected.matchDuration = linkProperties.matchDuration;
    expected.linkType = linkProperties.linkType;
    expected.controlParams = [buo getParamsForServerRequestWithAddedLinkProperties:linkProperties];
    return expected;
}

- (BranchLinkProperties *)linkPropertiesForLinkTestsWithAlias:(NSString *)alias {
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    lp.tags = @[@"tag1"];
    lp.alias = alias;
    lp.channel = @"sms";
    lp.feature = @"share";
    lp.stage = @"stage1";
    lp.campaign = @"campaign1";
    lp.matchDuration = 300;
    return lp;
}

// Decision 2, seen through BranchUniversalObject: -getLongUrlWithChannel:… accepted a channel and
// then passed nil for it into the URL assembly, so the channel never reached the link. It does now.
- (void)testUniversalObjectLongURLNowCarriesTheChannel {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *url = [[self universalObjectForLinkTests] getLongUrlWithChannel:@"sms"
                                                                      andTags:@[@"tag1"]
                                                                   andFeature:@"share"
                                                                     andStage:@"stage1"
                                                                     andAlias:@"alias1"];

    // data= is a base64 blob of the BUO dictionary, so pin everything up to it: base URL, parameter
    // order, and the presence of channel=.
    NSString *expectedPrefix = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&alias=alias1&channel=sms&feature=share&stage=stage1"
        @"&source=ios&data=", kTestBranchKey];

    XCTAssertTrue([url hasPrefix:expectedPrefix], @"expected prefix %@, got %@", expectedPrefix, url);
}

- (void)testUniversalObjectSyncShortURLCarriesEveryLinkProperty {
    NSString *alias = [[NSUUID UUID] UUIDString];
    BranchUniversalObject *buo = [self universalObjectForLinkTests];
    BranchLinkProperties *lp = [self linkPropertiesForLinkTestsWithAlias:alias];
    NSString *cached = @"https://example.app.link/buo-sync";

    [self seedSharedLinkCacheWithURL:cached linkProperties:[self expectedRequestPropertiesFor:buo linkProperties:lp]];

    XCTAssertEqualObjects([buo getShortUrlWithLinkProperties:lp], cached,
                          @"a miss means the options handed to the builder differ from the link "
                          @"properties -- most likely matchDuration or campaign was dropped");
}

- (void)testUniversalObjectAsyncShortURLCarriesEveryLinkProperty {
    NSString *alias = [[NSUUID UUID] UUIDString];
    BranchUniversalObject *buo = [self universalObjectForLinkTests];
    BranchLinkProperties *lp = [self linkPropertiesForLinkTestsWithAlias:alias];
    NSString *cached = @"https://example.app.link/buo-async";

    [self seedSharedLinkCacheWithURL:cached linkProperties:[self expectedRequestPropertiesFor:buo linkProperties:lp]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    __block BOOL onMainThread = NO;
    [buo getShortUrlWithLinkProperties:lp andCallback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        onMainThread = [NSThread isMainThread];
        [calledBack fulfill];
    }];
    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertEqualObjects(deliveredURL, cached);
    XCTAssertTrue(onMainThread);
}

// BranchUniversalObject folds its own dictionary into the control params it sends, which means
// deriving a new BranchLinkProperties -- the caller's object belongs to the app and outlives the
// call, so writing the payload into it would be visible corruption.
- (void)testUniversalObjectDoesNotMutateTheCallersLinkProperties {
    BranchUniversalObject *buo = [self universalObjectForLinkTests];
    BranchLinkProperties *lp = [self linkPropertiesForLinkTestsWithAlias:[[NSUUID UUID] UUIDString]];
    [lp addControlParam:@"$desktop_url" withValue:@"https://example.com"];

    NSString *cached = @"https://example.app.link/buo-no-mutation";
    [self seedSharedLinkCacheWithURL:cached linkProperties:[self expectedRequestPropertiesFor:buo linkProperties:lp]];

    XCTAssertEqualObjects([buo getShortUrlWithLinkProperties:lp], cached);

    XCTAssertEqualObjects(lp.controlParams, @{@"$desktop_url": @"https://example.com"},
                          @"the caller's control params must come back untouched");
}

// Both short-URL methods bail before any link generation when the content cannot be identified.
- (void)testUniversalObjectShortURLRequiresACanonicalIdentifierOrTitle {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] init];

    XCTAssertNil([buo getShortUrlWithLinkProperties:[[BranchLinkProperties alloc] init]]);

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSError *deliveredError = nil;
    [buo getShortUrlWithLinkProperties:[[BranchLinkProperties alloc] init]
                           andCallback:^(NSString *url, NSError *error) {
        deliveredError = error;
        [calledBack fulfill];
    }];
    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertNotNil(deliveredError);
}

#pragma mark - Reuse

// The terminals do not consume the builder or mutate the link properties handed to them, so one
// builder can generate links for several sets of link properties.
- (void)testBuilderIsReusableAcrossLinkProperties {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [self longURLBuilder];
    BranchLinkProperties *sms = [self linkPropertiesWithChannel:@"sms"];
    BranchLinkProperties *email = [self linkPropertiesWithChannel:@"email"];

    NSString *smsURL = [builder getLongURLWithLinkProperties:sms useAppLinkDomain:NO];
    NSString *emailURL = [builder getLongURLWithLinkProperties:email useAppLinkDomain:NO];

    XCTAssertTrue([smsURL containsString:@"channel=sms&"], @"%@", smsURL);
    XCTAssertTrue([emailURL containsString:@"channel=email&"], @"%@", emailURL);
    XCTAssertEqualObjects(sms.channel, @"sms", @"the terminal must not mutate the link properties");
}

@end

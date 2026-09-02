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

#pragma mark - Defaults

- (void)testDefaults {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    XCTAssertNil(builder.params);
    XCTAssertNil(builder.tags);
    XCTAssertNil(builder.alias);
    XCTAssertNil(builder.channel);
    XCTAssertNil(builder.feature);
    XCTAssertNil(builder.stage);
    XCTAssertNil(builder.campaign);
    XCTAssertNil(builder.ignoreUAString);

    XCTAssertEqual(builder.matchDuration, (NSUInteger)0);
    XCTAssertEqual(builder.linkType, BranchLinkTypeUnlimitedUse);
    XCTAssertFalse(builder.useAppLinkDomain);
}

// BranchLinkTypeUnlimitedUse is 0, which is what lets longUrlWithBaseUrl:'s `if (type)` guard omit
// `type=` for a default link. Pin the numeric value, not just the constant, so a reordering of the
// enum is caught here rather than as a wire-format change.
- (void)testDefaultLinkTypeIsZero {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
    XCTAssertEqual((NSUInteger)builder.linkType, (NSUInteger)0);
}

#pragma mark - Property round-trips

- (void)testPropertiesRoundTrip {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    NSDictionary *params = @{@"$og_title": @"Sale", @"custom": @2};
    NSArray<NSString *> *tags = @[@"tag1", @"tag2"];

    builder.params = params;
    builder.tags = tags;
    builder.alias = @"summer-sale";
    builder.channel = @"sms";
    builder.feature = @"share";
    builder.stage = @"level_2";
    builder.campaign = @"back-to-school";
    builder.matchDuration = 300;
    builder.linkType = BranchLinkTypeOneTimeUse;
    builder.ignoreUAString = @"Slackbot-LinkExpanding";
    builder.useAppLinkDomain = YES;

    XCTAssertEqualObjects(builder.params, params);
    XCTAssertEqualObjects(builder.tags, tags);
    XCTAssertEqualObjects(builder.alias, @"summer-sale");
    XCTAssertEqualObjects(builder.channel, @"sms");
    XCTAssertEqualObjects(builder.feature, @"share");
    XCTAssertEqualObjects(builder.stage, @"level_2");
    XCTAssertEqualObjects(builder.campaign, @"back-to-school");
    XCTAssertEqual(builder.matchDuration, (NSUInteger)300);
    XCTAssertEqual(builder.linkType, BranchLinkTypeOneTimeUse);
    XCTAssertEqualObjects(builder.ignoreUAString, @"Slackbot-LinkExpanding");
    XCTAssertTrue(builder.useAppLinkDomain);
}

- (void)testPropertiesAcceptNilAfterBeingSet {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    builder.params = @{@"a": @"b"};
    builder.tags = @[@"tag"];
    builder.alias = @"alias";
    builder.channel = @"channel";
    builder.feature = @"feature";
    builder.stage = @"stage";
    builder.campaign = @"campaign";
    builder.ignoreUAString = @"ua";

    builder.params = nil;
    builder.tags = nil;
    builder.alias = nil;
    builder.channel = nil;
    builder.feature = nil;
    builder.stage = nil;
    builder.campaign = nil;
    builder.ignoreUAString = nil;

    XCTAssertNil(builder.params);
    XCTAssertNil(builder.tags);
    XCTAssertNil(builder.alias);
    XCTAssertNil(builder.channel);
    XCTAssertNil(builder.feature);
    XCTAssertNil(builder.stage);
    XCTAssertNil(builder.campaign);
    XCTAssertNil(builder.ignoreUAString);
}

// params and tags are declared `copy`, so a caller mutating the collection it handed over cannot
// change what the builder will send. The terminals read these long after assignment.
- (void)testCollectionPropertiesAreCopied {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"a": @"b"}];
    NSMutableArray *tags = [NSMutableArray arrayWithArray:@[@"tag1"]];

    builder.params = params;
    builder.tags = tags;

    params[@"c"] = @"d";
    [tags addObject:@"tag2"];

    XCTAssertEqualObjects(builder.params, @{@"a": @"b"});
    XCTAssertEqualObjects(builder.tags, @[@"tag1"]);
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

// +[Branch sharedInstance] raises when +initialize: has not run. Constructing a builder must not
// trigger that -- none of the overloads this builder replaces could fail at construction, since
// they were messages to an instance the caller already held. Resolution is deferred to the first
// `branch` read, which is inside a terminal.
- (void)testBranchIsResolvedLazilyRatherThanAtInit {
    [Branch resetInitializationGuardForTesting];

    BranchLinkBuilder *builder = nil;
    XCTAssertNoThrow(builder = [[BranchLinkBuilder alloc] init]);
    XCTAssertNotNil(builder);

    // Setting options is likewise safe before initialization.
    XCTAssertNoThrow(builder.channel = @"sms");

    // The deferred resolution is what raises, and only when something actually needs the instance.
    XCTAssertThrows([builder branch]);
}

- (void)testInjectedBranchIsUsedEvenWhenSharedInstanceIsUnavailable {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    Branch *injected = self.branch;

    [Branch resetInitializationGuardForTesting];

    XCTAssertIdentical(builder.branch, injected);
}

#pragma mark - buildLongURL

- (BranchLinkBuilder *)fullyPopulatedLongURLBuilder {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.params = @{@"key": @"value"};
    builder.tags = @[@"tag1", @"tag2"];
    builder.alias = @"alias1";
    builder.channel = @"channel1";
    builder.feature = @"feature1";
    builder.stage = @"stage1";
    return builder;
}

// The exact string the deleted -getLongURLWithParams:andChannel:andTags:andFeature:andStage:andAlias:
// produced, plus channel=channel1& -- see testLongURLEmitsChannel.
- (void)testLongURLDefaultDomainExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects([[self fullyPopulatedLongURLBuilder] buildLongURL], expected);
}

// The default domain is built without a trailing "?" and -sanitizedMutableBaseURL: adds the
// separator; the app-link branch pre-terminates with "?" instead. Both must yield exactly one "?".
- (void)testLongURLAppLinkDomainWithoutUserUrlExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [self fullyPopulatedLongURLBuilder];
    builder.useAppLinkDomain = YES;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects([builder buildLongURL], expected);
}

- (void)testLongURLAppLinkDomainWithUserUrlExactString {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link/xyz789";

    BranchLinkBuilder *builder = [self fullyPopulatedLongURLBuilder];
    builder.useAppLinkDomain = YES;

    NSString *expected = [NSString stringWithFormat:
        @"https://example.app.link/xyz789?tags=tag1&tags=tag2&alias=alias1&channel=channel1"
        @"&feature=feature1&stage=stage1&source=ios&data=%@", kEncodedKeyValueParams];

    XCTAssertEqualObjects([builder buildLongURL], expected);
}

// userUrl only matters when useAppLinkDomain is set; the default domain ignores it entirely.
- (void)testLongURLDefaultDomainIgnoresUserUrl {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link/xyz789";

    NSString *url = [[self fullyPopulatedLongURLBuilder] buildLongURL];
    NSString *expectedPrefix = [NSString stringWithFormat:@"https://bnc.lt/a/%@?", kTestBranchKey];

    XCTAssertTrue([url hasPrefix:expectedPrefix], @"%@", url);
    XCTAssertFalse([url containsString:@"example.app.link"], @"%@", url);
}

// Decision 2: the methods this replaces accepted a channel and dropped it. The builder emits it.
- (void)testLongURLEmitsChannel {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.params = @{@"key": @"value"};
    builder.channel = @"channel1";

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?channel=channel1&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects([builder buildLongURL], expected);
}

- (void)testLongURLOmitsChannelWhenUnset {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.params = @{@"key": @"value"};

    NSString *url = [builder buildLongURL];
    XCTAssertFalse([url containsString:@"channel="], @"%@", url);
}

// BranchLinkTypeUnlimitedUse is 0 and matchDuration defaults to 0, and both are emitted behind
// truthiness guards, so a default builder must emit neither.
- (void)testLongURLOmitsTypeAndMatchDurationAtDefaults {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *url = [[self fullyPopulatedLongURLBuilder] buildLongURL];

    XCTAssertFalse([url containsString:@"type="], @"%@", url);
    XCTAssertFalse([url containsString:@"matchDuration="], @"%@", url);
}

- (void)testLongURLEmitsTypeAndMatchDurationWhenSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [self fullyPopulatedLongURLBuilder];
    builder.linkType = BranchLinkTypeOneTimeUse;
    builder.matchDuration = 300;

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&channel=channel1&feature=feature1"
        @"&stage=stage1&type=1&matchDuration=300&source=ios&data=%@",
        kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects([builder buildLongURL], expected);
}

// campaign has no place in a long URL. The methods this replaces had no campaign parameter at all,
// so setting one must not change the output.
- (void)testLongURLIgnoresCampaign {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *without = [[self fullyPopulatedLongURLBuilder] buildLongURL];

    BranchLinkBuilder *builder = [self fullyPopulatedLongURLBuilder];
    builder.campaign = @"back-to-school";

    XCTAssertEqualObjects([builder buildLongURL], without);
}

// ignoreUAString applies to fetchShortURL only. It degrades with a warning, so the URL is unchanged.
- (void)testLongURLIgnoresIgnoreUAString {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    NSString *without = [[self fullyPopulatedLongURLBuilder] buildLongURL];

    BranchLinkBuilder *builder = [self fullyPopulatedLongURLBuilder];
    builder.ignoreUAString = @"Slackbot-LinkExpanding";

    XCTAssertEqualObjects([builder buildLongURL], without);
}

// Values go through +[BNCEncodingUtils stringByPercentEncodingStringForQuery:], which uses
// URLQueryAllowedCharacterSet -- the set legal *anywhere* in a query component. It escapes spaces
// but deliberately permits sub-delimiters, so "/" and "&" pass through unescaped and a channel
// containing "&" yields a structurally broken URL. That is long-standing SDK behavior, carried over
// verbatim by this port; pinned here so a future encoder change is a visible decision rather than a
// silent wire-format change.
- (void)testLongURLEncodesValuesWithURLQueryAllowedCharacterSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.params = @{@"key": @"value"};
    builder.channel = @"a b&c";
    builder.tags = @[@"x/y"];

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=x/y&channel=a%%20b&c&source=ios&data=%@",
        kTestBranchKey, kEncodedKeyValueParams];

    XCTAssertEqualObjects([builder buildLongURL], expected);
}

- (void)testLongURLWithNoOptionsSet {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    NSString *url = [builder buildLongURL];
    NSString *expectedPrefix = [NSString stringWithFormat:@"https://bnc.lt/a/%@?source=ios&data=", kTestBranchKey];

    XCTAssertTrue([url hasPrefix:expectedPrefix], @"%@", url);
}

#pragma mark - fetchShortURL — link data / cache key

// BNCLinkCache keys on -[BNCLinkData hash], so the exact setupX: sequence the builder uses is what
// decides whether links cached by earlier SDK versions are still found. Compared against a
// hand-constructed BNCLinkData rather than against the old overload, so this test survives Step 8's
// deletion of that overload.
- (void)testLinkDataMatchesTheDocumentedSetupSequence {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.params = @{@"key": @"value"};
    builder.tags = @[@"tag1", @"tag2"];
    builder.alias = @"alias1";
    builder.channel = @"channel1";
    builder.feature = @"feature1";
    builder.stage = @"stage1";
    builder.campaign = @"campaign1";
    builder.matchDuration = 300;
    builder.linkType = BranchLinkTypeOneTimeUse;

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

    BNCLinkData *actual = [builder linkDataWithIgnoreUAString:nil];

    XCTAssertEqual([actual hash], [expected hash]);
    XCTAssertEqualObjects(actual.data, expected.data);
}

// ignoreUAString reaches the wire payload...
- (void)testIgnoreUAStringReachesTheLinkDataPayload {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    BNCLinkData *linkData = [builder linkDataWithIgnoreUAString:@"Slackbot-LinkExpanding"];

    XCTAssertEqualObjects(linkData.data[BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING], @"Slackbot-LinkExpanding");
}

// ...but NOT the cache key. -[BNCLinkData hash] omits ignoreUAString, and BNCLinkCache keys on that
// hash alone, so an ignoreUAString link is cached under the same key as an ordinary one. Contradicts
// research.md Behavior #3's claim that it is "part of the cache key"; pinned here because the
// difference decides whether the cache-bypass test below means anything.
- (void)testIgnoreUAStringDoesNotAffectTheCacheKey {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:self.branch];
    builder.channel = @"channel1";

    BNCLinkData *withUA = [builder linkDataWithIgnoreUAString:@"Slackbot-LinkExpanding"];
    BNCLinkData *withoutUA = [builder linkDataWithIgnoreUAString:nil];

    XCTAssertEqual([withUA hash], [withoutUA hash]);
    XCTAssertNotEqualObjects(withUA.data, withoutUA.data, @"payloads should still differ");
}

#pragma mark - fetchShortURL — network (stubbed)

// A Branch wired to a fake server interface, with its own link cache and request queue so nothing
// here touches the shared singleton state.
- (Branch *)branchWithFakeInterface:(BNCFakeServerInterface *)fake linkCache:(BNCLinkCache *)linkCache {
    return [[Branch alloc] initWithInterface:fake
                                       queue:[[BNCServerRequestQueue alloc] init]
                                       cache:linkCache
                            preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                         key:kTestBranchKey];
}

- (void)testFetchShortURLReturnsServerURLAndCachesIt {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    builder.channel = @"sms";

    XCTAssertEqualObjects([builder fetchShortURL], @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1);

    // Cache write (Branch.m:1864) -- the second call must not reach the network.
    XCTAssertEqualObjects([builder fetchShortURL], @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1, @"second call should have been served from the cache");
    XCTAssertEqualObjects([linkCache objectForKey:[builder linkDataWithIgnoreUAString:nil]], @"https://example.app.link/abc123");
}

// Behavior #3: an ignoreUAString bypasses the cache *read*, so a request is issued even when a
// cached link for the same key already exists.
- (void)testFetchShortURLWithIgnoreUAStringBypassesTheCacheRead {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];
    builder.channel = @"sms";

    [builder fetchShortURL];
    XCTAssertEqual(fake.requestCount, 1);

    builder.ignoreUAString = @"Slackbot-LinkExpanding";
    [builder fetchShortURL];
    XCTAssertEqual(fake.requestCount, 2, @"ignoreUAString must force a fresh request");

    // ...and again, every time, because the read is skipped rather than the entry isolated.
    [builder fetchShortURL];
    XCTAssertEqual(fake.requestCount, 3);
}

// This branch has no layer1-logger-tests.yml, so these are the only assertions on the outgoing
// short-link request body that exist anywhere.
- (void)testFetchShortURLRequestBody {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    builder.params = @{@"key": @"value"};
    builder.tags = @[@"tag1", @"tag2"];
    builder.alias = @"alias1";
    builder.channel = @"channel1";
    builder.feature = @"feature1";
    builder.stage = @"stage1";
    builder.campaign = @"campaign1";
    builder.matchDuration = 300;
    builder.linkType = BranchLinkTypeOneTimeUse;
    builder.ignoreUAString = @"Slackbot-LinkExpanding";

    [builder fetchShortURL];

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
- (void)testFetchShortURLNon200FallsBackToLongURLWhenUserUrlIsSet {
    [BNCPreferenceHelper sharedInstance].userUrl = @"https://example.app.link";

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:500 url:nil];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    builder.channel = @"channel1";

    NSString *url = [builder fetchShortURL];

    XCTAssertNotNil(url);
    XCTAssertTrue([url hasPrefix:@"https://example.app.link?"], @"%@", url);
    XCTAssertTrue([url containsString:@"channel=channel1&"], @"%@", url);
    XCTAssertTrue([url containsString:@"source=ios&data="], @"%@", url);
}

// ...and returns nil when no link domain is known, which is exactly why a short-URL test may not
// assert merely on an "https://" prefix: the same failure yields a URL or nil depending on
// whether an earlier test happened to populate userUrl.
- (void)testFetchShortURLNon200ReturnsNilWhenUserUrlIsUnset {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:500 url:nil];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    builder.channel = @"channel1";

    XCTAssertNil([builder fetchShortURL]);
}

- (void)testFetchShortURLReturnsNilWhenTransportReturnsNoResponse {
    [BNCPreferenceHelper sharedInstance].userUrl = nil;

    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = nil;

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];

    XCTAssertNil([builder fetchShortURL]);
    XCTAssertEqual(fake.requestCount, 1);
}

// A 200 whose body carries no url key: nothing to return, nothing to cache.
- (void)testFetchShortURL200WithoutURLReturnsNilAndCachesNothing {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:nil];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:linkCache]];

    XCTAssertNil([builder fetchShortURL]);
    XCTAssertNil([linkCache objectForKey:[builder linkDataWithIgnoreUAString:nil]]);
}

- (void)testFetchShortURLIgnoresUseAppLinkDomain {
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    fake.stubResponse = [BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/abc123"];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:[self branchWithFakeInterface:fake linkCache:[[BNCLinkCache alloc] init]]];
    builder.useAppLinkDomain = YES;

    XCTAssertEqualObjects([builder fetchShortURL], @"https://example.app.link/abc123");
    XCTAssertEqual(fake.requestCount, 1);
}

#pragma mark - fetchShortURLWithCallback:

// A Branch whose request queue records instead of executing, so the async terminal can be observed
// without a network call.
- (Branch *)branchWithRecordingQueue:(BNCRecordingRequestQueue *)queue linkCache:(BNCLinkCache *)linkCache {
    return [[Branch alloc] initWithInterface:[[BNCFakeServerInterface alloc] init]
                                       queue:queue
                                       cache:linkCache
                            preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                         key:kTestBranchKey];
}

- (void)testFetchShortURLWithCallbackEnqueuesRequestOnCacheMiss {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.channel = @"sms";

    [builder fetchShortURLWithCallback:^(NSString *url, NSError *error) { }];

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
- (void)testFetchShortURLWithCallbackCacheHitCallsBackOnMainQueueAndEnqueuesNothing {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.channel = @"sms";
    [linkCache setObject:@"https://example.app.link/cached" forKey:[builder linkDataWithIgnoreUAString:nil]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    __block NSError *deliveredError = nil;
    __block BOOL onMainThread = NO;

    [builder fetchShortURLWithCallback:^(NSString *url, NSError *error) {
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

// Unlike fetchShortURL, the async terminal has no ignoreUAString option: it hardcodes nil into the
// BNCLinkData and does not bypass the cache read. So a cached ordinary link is still served even
// with ignoreUAString set -- which is also why the property warns here.
- (void)testFetchShortURLWithCallbackIgnoresIgnoreUAStringAndStillReadsTheCache {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.channel = @"sms";
    [linkCache setObject:@"https://example.app.link/cached" forKey:[builder linkDataWithIgnoreUAString:nil]];

    builder.ignoreUAString = @"Slackbot-LinkExpanding";

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    [builder fetchShortURLWithCallback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        [calledBack fulfill];
    }];
    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/cached");
    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

// The terminal snapshots its options at call time, not when the isolation-queue block runs. The
// funnel this replaces got them as method arguments, so a caller mutating the builder immediately
// after the call could not affect the in-flight request -- and the builder is documented as
// reusable, so that sequence is expected usage.
//
// Verified through the cache: the cache lookup uses the BNCLinkData built from the snapshot, so a
// hit proves the pre-mutation values were used.
- (void)testFetchShortURLWithCallbackSnapshotsOptionsAtCallTime {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.channel = @"sms";
    [linkCache setObject:@"https://example.app.link/sms" forKey:[builder linkDataWithIgnoreUAString:nil]];

    XCTestExpectation *calledBack = [self expectationWithDescription:@"callback"];
    __block NSString *deliveredURL = nil;
    [builder fetchShortURLWithCallback:^(NSString *url, NSError *error) {
        deliveredURL = url;
        [calledBack fulfill];
    }];

    // Mutate immediately, before the isolation-queue block can have run. Only "email" is cached-miss;
    // if the block read the property late it would miss the cache and enqueue instead.
    builder.channel = @"email";

    [self waitForExpectations:@[calledBack] timeout:5];

    XCTAssertEqualObjects(deliveredURL, @"https://example.app.link/sms",
                          @"the request must use the options as of the call, not the mutated ones");
    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

- (void)testFetchShortURLWithCallbackAcceptsNilCallback {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.channel = @"sms";

    XCTAssertNoThrow([builder fetchShortURLWithCallback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    // The link is still requested; only the delivery is skipped.
    XCTAssertEqual([queue snapshot].count, (NSUInteger)1);
}

// A nil callback on a cache hit returns early without ever dispatching to main.
- (void)testFetchShortURLWithCallbackNilCallbackOnCacheHitDoesNothing {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    [linkCache setObject:@"https://example.app.link/cached" forKey:[builder linkDataWithIgnoreUAString:nil]];

    XCTAssertNoThrow([builder fetchShortURLWithCallback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)0);
}

#pragma mark - fetchSpotlightURLWithCallback:

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

- (void)testFetchSpotlightURLEnqueuesSpotlightRequest {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};

    [builder fetchSpotlightURLWithCallback:^(NSDictionary *params, NSError *error) { }];

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
- (void)testFetchSpotlightURLRequestBody {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};

    [builder fetchSpotlightURLWithCallback:nil];

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

// params is the only property the terminal reads. Everything else is fixed by
// BranchSpotlightUrlRequest, so a builder carrying options from an earlier share link must not leak
// them into the spotlight body.
- (void)testFetchSpotlightURLIgnoresEveryOptionButParams {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};
    builder.tags = @[@"tag1"];
    builder.alias = @"alias1";
    builder.channel = @"sms";
    builder.feature = @"feature1";
    builder.stage = @"stage1";
    builder.campaign = @"campaign1";
    builder.matchDuration = 300;
    builder.linkType = BranchLinkTypeOneTimeUse;
    builder.ignoreUAString = @"Slackbot-LinkExpanding";
    builder.useAppLinkDomain = YES;

    [builder fetchSpotlightURLWithCallback:nil];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    NSDictionary *body = fake.lastPostBody;
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_CHANNEL], @"spotlight",
                          @"the builder's channel must not override the fixed spotlight channel");
    XCTAssertEqualObjects(body[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"value"});
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_TAGS]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_ALIAS]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_FEATURE]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_STAGE]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_CAMPAIGN]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_DURATION]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_LINK_TYPE]);
    XCTAssertNil(body[BRANCH_REQUEST_KEY_URL_IGNORE_UA_STRING]);
}

// Unlike the two short-URL terminals, the spotlight callback receives the server's whole payload --
// Core Spotlight needs the accompanying fields, not just the URL.
- (void)testFetchSpotlightURLDeliversTheWholeResponsePayload {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};

    __block NSDictionary *deliveredParams = nil;
    __block NSError *deliveredError = nil;
    [builder fetchSpotlightURLWithCallback:^(NSDictionary *params, NSError *error) {
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
- (void)testFetchSpotlightURLOnErrorDeliversAnEmptyDictionaryAndTheError {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};

    __block NSDictionary *deliveredParams = nil;
    __block NSError *deliveredError = nil;
    [builder fetchSpotlightURLWithCallback:^(NSDictionary *params, NSError *error) {
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

// Same contract as -fetchShortURLWithCallback:: options are fixed at call time, not read late from
// inside the isolation-queue block, so mutating a reusable builder cannot change a request already
// in flight.
- (void)testFetchSpotlightURLSnapshotsParamsAtCallTime {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCFakeServerInterface *fake = [[BNCFakeServerInterface alloc] init];
    Branch *branch = [[Branch alloc] initWithInterface:fake
                                                 queue:queue
                                                 cache:[[BNCLinkCache alloc] init]
                                      preferenceHelper:[BNCPreferenceHelper sharedInstance]
                                                   key:kTestBranchKey];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"at-call-time"};

    [builder fetchSpotlightURLWithCallback:nil];

    // Mutate immediately, before the isolation-queue block can have run.
    builder.params = @{@"key": @"mutated"};

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    [self deliver:[queue snapshot].firstObject
        interface:fake
         response:[BNCFakeServerInterface responseWithStatusCode:200 url:@"https://example.app.link/spot"]
            error:nil];

    XCTAssertEqualObjects(fake.lastPostBody[BRANCH_REQUEST_KEY_URL_DATA], @{@"key": @"at-call-time"});
}

// BranchSpotlightUrlRequest is constructed with linkCache:nil, so spotlight links neither read nor
// write the cache the two fetchShortURL terminals share.
- (void)testFetchSpotlightURLDoesNotUseTheLinkCache {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    BNCLinkCache *linkCache = [[BNCLinkCache alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:linkCache];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];
    builder.params = @{@"key": @"value"};
    // A cached entry under the key the short-URL terminals would use for these options.
    [linkCache setObject:@"https://example.app.link/cached" forKey:[builder linkDataWithIgnoreUAString:nil]];

    [builder fetchSpotlightURLWithCallback:nil];

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)1,
                   @"a cached short link must not short-circuit a spotlight request");
}

- (void)testFetchSpotlightURLAcceptsNilCallbackAndNilParams {
    BNCRecordingRequestQueue *queue = [[BNCRecordingRequestQueue alloc] init];
    Branch *branch = [self branchWithRecordingQueue:queue linkCache:[[BNCLinkCache alloc] init]];

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] initWithBranch:branch];

    XCTAssertNoThrow([builder fetchSpotlightURLWithCallback:nil]);

    XCTestExpectation *drained = [self expectationWithDescription:@"isolation queue drained"];
    dispatch_async(branch.isolationQueue, ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];

    XCTAssertEqual([queue snapshot].count, (NSUInteger)1);
}

#pragma mark - fetchShortURL — live smoke test

// Replaces BranchClassTests' testGetShortURL. That test asserted only hasPrefix:@"https://", which
// the non-200 long-URL fallback also satisfies -- so it could not fail for the reason it existed,
// and whether it passed depended on whether an earlier test had populated userUrl. This asserts the
// result is a *short* link on a Branch domain, which the fallback cannot satisfy: the fallback
// carries a "source=ios&data=" query, and with userUrl cleared it returns nil outright.
//
// Runs on a background queue because fetchShortURL blocks; the real network makes this the slowest
// test in the class.
- (void)testFetchShortURLLiveSmokeTest {
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
    builder.channel = @"unit-test";
    builder.feature = @"EMT-4069-smoke";
    // Defeat the link cache so this exercises the network even if an earlier test cached a link.
    builder.stage = [[NSUUID UUID] UUIDString];

    XCTestExpectation *done = [self expectationWithDescription:@"live short URL"];
    __block NSString *shortURL = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        shortURL = [builder fetchShortURL];
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
// The seam is the shared link cache: -fetchShortURL reads it before going to the network, so seeding
// it under exactly the options BranchUniversalObject is expected to produce turns "did it build the
// right BNCLinkData?" into a hit-or-miss with no network call. BNCLinkCache keys on
// -[BNCLinkData hash], so one wrong option is a different key and a miss.
- (void)seedSharedLinkCacheWithURL:(NSString *)url
                     fromBuilderBlock:(void (^)(BranchLinkBuilder *builder))configure {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
    configure(builder);
    [[Branch sharedInstance].linkCache setObject:url forKey:[builder linkDataWithIgnoreUAString:nil]];
}

- (BranchUniversalObject *)universalObjectForLinkTests {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    buo.title = @"Title";
    return buo;
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

    [self seedSharedLinkCacheWithURL:cached fromBuilderBlock:^(BranchLinkBuilder *builder) {
        builder.params = [buo getParamsForServerRequestWithAddedLinkProperties:lp];
        builder.tags = lp.tags;
        builder.alias = lp.alias;
        builder.channel = lp.channel;
        builder.feature = lp.feature;
        builder.stage = lp.stage;
        builder.campaign = lp.campaign;
        builder.matchDuration = lp.matchDuration;
    }];

    XCTAssertEqualObjects([buo getShortUrlWithLinkProperties:lp], cached,
                          @"a miss means the options handed to the builder differ from the link "
                          @"properties -- most likely matchDuration or campaign was dropped");
}

- (void)testUniversalObjectAsyncShortURLCarriesEveryLinkProperty {
    NSString *alias = [[NSUUID UUID] UUIDString];
    BranchUniversalObject *buo = [self universalObjectForLinkTests];
    BranchLinkProperties *lp = [self linkPropertiesForLinkTestsWithAlias:alias];
    NSString *cached = @"https://example.app.link/buo-async";

    [self seedSharedLinkCacheWithURL:cached fromBuilderBlock:^(BranchLinkBuilder *builder) {
        builder.params = [buo getParamsForServerRequestWithAddedLinkProperties:lp];
        builder.tags = lp.tags;
        builder.alias = lp.alias;
        builder.channel = lp.channel;
        builder.feature = lp.feature;
        builder.stage = lp.stage;
        builder.campaign = lp.campaign;
        builder.matchDuration = lp.matchDuration;
    }];

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

// The terminals do not consume the builder, so the same instance can produce several links.
- (void)testBuilderIsReusableAcrossPropertyChanges {
    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];

    builder.channel = @"sms";
    XCTAssertEqualObjects(builder.channel, @"sms");

    builder.channel = @"email";
    XCTAssertEqualObjects(builder.channel, @"email");
}

@end

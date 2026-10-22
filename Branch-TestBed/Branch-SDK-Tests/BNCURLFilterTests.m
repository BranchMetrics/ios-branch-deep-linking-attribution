/**
 @file          BNCURLFilterTests.m
 @package       Branch-SDK-Tests
 @brief         BNCURLFilter  tests.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "BNCURLFilter.h"
#import "BNCNetworkService.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerRequestQueue.h"
#import "Branch.h"

// Exposes BNCURLFilter internals to the tests.
@interface BNCURLFilter (Testing)
- (NSArray<NSString *> *)patternList;
- (NSInteger)listVersion;
- (BOOL)hasUpdatedPatternList;
- (void)setHasUpdatedPatternList:(BOOL)hasUpdatedPatternList;
- (BOOL)isUpdatingPatternList;
- (void)setIsUpdatingPatternList:(BOOL)isUpdatingPatternList;
- (void)processServerOperation:(id<BNCNetworkOperationProtocol>)operation;
@end

#pragma mark - Mock network

// A canned network operation. Completes asynchronously on a background queue, like BNCNetworkOperation.
@interface BNCURLFilterTestOperation : NSObject <BNCNetworkOperationProtocol>
@property (nonatomic, readwrite, copy) NSURLRequest *request;
@property (nonatomic, readwrite, copy) NSHTTPURLResponse *response;
@property (nonatomic, readwrite, strong) NSData *responseData;
@property (nonatomic, readwrite, copy) NSError *error;
@property (nonatomic, readwrite, copy) NSDate *startDate;
@property (nonatomic, readwrite, copy) NSDate *timeoutDate;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, copy) void (^completion)(id<BNCNetworkOperationProtocol> operation);
@property (nonatomic, strong) dispatch_semaphore_t gate;
@end

@implementation BNCURLFilterTestOperation

- (void)start {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if (self.gate) {
            // Bounded wait, then pass the signal on, so one signal releases every waiting operation and a
            // failing test can't leave GCD threads blocked for the rest of the run.
            dispatch_semaphore_wait(self.gate, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
            dispatch_semaphore_signal(self.gate);
        }
        if (self.completion) {
            self.completion(self);
        }
    });
}

@end

// Canned response returned for skip-list requests. Configured by the tests.
static NSInteger bnc_mockStatusCode = 200;
static NSData *bnc_mockResponseData = nil;
static NSError *bnc_mockError = nil;
static BOOL bnc_mockReturnsNilOperation = NO;
static dispatch_semaphore_t bnc_mockGate = nil;
static NSMutableArray<NSURLRequest *> *bnc_mockRequests = nil;

// Mock network service for skip-list requests. Anything else is passed through to BNCNetworkService,
// so the Branch singleton isn't affected while the mock is installed.
@interface BNCURLFilterTestNetworkService : NSObject <BNCNetworkServiceProtocol>
@property (nonatomic, strong) NSDictionary *userInfo;
@end

@implementation BNCURLFilterTestNetworkService

+ (void)reset {
    @synchronized (self) {
        bnc_mockStatusCode = 200;
        bnc_mockResponseData = nil;
        bnc_mockError = nil;
        bnc_mockReturnsNilOperation = NO;
        bnc_mockGate = nil;
        bnc_mockRequests = [NSMutableArray new];
    }
}

+ (NSArray<NSURLRequest *> *)requests {
    @synchronized (self) {
        return [bnc_mockRequests copy];
    }
}

- (id<BNCNetworkOperationProtocol>)networkOperationWithURLRequest:(NSMutableURLRequest *)request
                completion:(void (^)(id<BNCNetworkOperationProtocol> operation))completion {
    if (![request.URL.absoluteString containsString:@"uriskiplist"]) {
        return [[BNCNetworkService new] networkOperationWithURLRequest:request completion:completion];
    }

    @synchronized (BNCURLFilterTestNetworkService.class) {
        [bnc_mockRequests addObject:request];
        if (bnc_mockReturnsNilOperation) {
            return nil;
        }

        BNCURLFilterTestOperation *operation = [BNCURLFilterTestOperation new];
        operation.request = request;
        operation.response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:bnc_mockStatusCode HTTPVersion:@"HTTP/1.1" headerFields:nil];
        operation.responseData = bnc_mockResponseData;
        operation.error = bnc_mockError;
        operation.gate = bnc_mockGate;
        operation.completion = completion;
        return operation;
    }
}

@end

#pragma mark - Tests

@interface BNCURLFilterTests : XCTestCase
@property (nonatomic, strong) NSArray<NSString *> *originalSavedPatternList;
@property (nonatomic, assign) NSInteger originalSavedPatternListVersion;
@property (nonatomic, assign) IMP originalNetworkServiceClassIMP;
@end

@implementation BNCURLFilterTests

- (void)setUp {
    // Server updates write to the shared preferences, so restore them after each test.
    self.originalSavedPatternList = [BNCPreferenceHelper sharedInstance].savedURLPatternList;
    self.originalSavedPatternListVersion = [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion;
    [BNCURLFilterTestNetworkService reset];
}

- (void)tearDown {
    [self uninstallMockNetworkService];
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = self.originalSavedPatternList;
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = self.originalSavedPatternListVersion;
}

#pragma mark Helpers

// +[Branch setNetworkServiceClass:] can only be set once per process, so swap the getter instead.
- (void)installMockNetworkService {
    Method method = class_getClassMethod(Branch.class, @selector(networkServiceClass));
    IMP mockIMP = imp_implementationWithBlock(^Class(id _self) {
        return BNCURLFilterTestNetworkService.class;
    });
    self.originalNetworkServiceClassIMP = method_setImplementation(method, mockIMP);
}

- (void)uninstallMockNetworkService {
    if (self.originalNetworkServiceClassIMP) {
        Method method = class_getClassMethod(Branch.class, @selector(networkServiceClass));
        method_setImplementation(method, self.originalNetworkServiceClassIMP);
        self.originalNetworkServiceClassIMP = NULL;
    }
}

- (NSData *)skipListDataWithPatterns:(NSArray<NSString *> *)patterns version:(NSInteger)version {
    return [NSJSONSerialization dataWithJSONObject:@{ @"uri_skip_list": patterns, @"version": @(version) } options:0 error:nil];
}

- (BNCURLFilterTestOperation *)operationWithStatusCode:(NSInteger)statusCode data:(NSData *)data error:(NSError *)error {
    NSURL *url = [NSURL URLWithString:@"https://cdn.branch.io/sdk/uriskiplist_v0.json"];
    BNCURLFilterTestOperation *operation = [BNCURLFilterTestOperation new];
    operation.request = [NSURLRequest requestWithURL:url];
    operation.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:statusCode HTTPVersion:@"HTTP/1.1" headerFields:nil];
    operation.responseData = data;
    operation.error = error;
    return operation;
}

// Asserts the filter still has the default pattern list and was not marked as updated.
- (void)assertFilterHasDefaultList:(BNCURLFilter *)filter {
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertEqual(filter.listVersion, -1);
    XCTAssertFalse(filter.hasUpdatedPatternList);
}

- (void)testPatternMatchingURL_nil {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = nil;
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertNil(matchingRegex);
}

- (void)testPatternMatchingURL_emptyString {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:@""];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertNil(matchingRegex);
}

- (void)testPatternMatchingURL_fbRegexMatches {
    NSString *pattern = @"^fb\\d+:((?!campaign_ids).)*$";
    NSString *sampleURL = @"fb12345://";
    
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:sampleURL];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertTrue([pattern isEqualToString:matchingRegex]);
}

- (void)testPatternMatchingURL_fbRegexDoesNotMatch {
    NSString *pattern = @"^fb\\d+:((?!campaign_ids).)*$";
    NSString *sampleURL = @"fb12345://campaign_ids";
    
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:sampleURL];
    NSString *matchingRegex = [filter patternMatchingURL:url];
    XCTAssertFalse([pattern isEqualToString:matchingRegex]);
}


- (void)testIgnoredSuspectedAuthURLs {
    NSArray *urls = @[
        @"fb123456:login/464646",
        @"shsh:oauth/login",
        @"https://myapp.app.link/oauth_token=fred",
        @"https://myapp.app.link/auth_token=fred",
        @"https://myapp.app.link/authtoken=fred",
        @"https://myapp.app.link/auth=fred",
        @"myscheme:path/to/resource?oauth=747474",
        @"myscheme:oauth=747474",
        @"myscheme:/oauth=747474",
        @"myscheme://oauth=747474",
        @"myscheme://path/oauth=747474",
        @"myscheme://path/:oauth=747474",
        @"https://google.com/userprofile/devonbanks=oauth?"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testAllowedURLsSimilarToAuthURLs {
    NSArray *urls = @[
        @"shshs:/content/path",
        @"shshs:content/path",
        @"https://myapp.app.link/12345/link",
        @"https://myapp.app.link?authentic=true&tokemonsta=false",
        @"myscheme://path/brauth=747474"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'", URL);
    }
}

- (void)testIgnoredFacebookURLs {
    // Most FB URIs are ignored
    NSArray *urls = @[
        @"fb123456://login/464646",
        @"fb1234:",
        @"fb1234:/",
        @"fb1234:/this-is-some-extra-info/?whatever",
        @"fb1234:/this-is-some-extra-info/?whatever:andstuff"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testAllowedFacebookURLs {
    NSArray *urls = @[
        // Facebook URIs do not contain letters other than an fb prefix
        @"fb123x://",
        // FB URIs with campaign ids are allowed
        @"fb1234://helloworld?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"
    ];
    
    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertFalse([filter shouldIgnoreURL:URL], @"Checking '%@'", URL);
    }
}

- (void)testCustomPatternList {
    BNCURLFilter *filter = [BNCURLFilter new];
    
    // sanity check default pattern list
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);

    // confirm new pattern list is enforced
    [filter useCustomPatternList:@[@"^branch\\d+:"]];
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

// This is an end to end test and relies on a server call
- (void)testUpdatePatternListFromServer {
    BNCURLFilter *filter = [BNCURLFilter new];

    // confirm new pattern list is enforced
    [filter useCustomPatternList:@[@"^branch\\d+:"]];
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"List updated"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) { }];
    
    // the retrieved list should match default pattern list
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

- (void)testCustomPatternListIsCopied {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSMutableArray<NSString *> *patternList = [NSMutableArray arrayWithObject:@"^branch\\d+:"];
    [filter useCustomPatternList:patternList];

    // mutating the caller's array must not change the filter
    [patternList removeAllObjects];
    [patternList addObject:@"^other\\d+:"];
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"other123://"]]);
}

- (void)testConcurrentCustomPatternListAndMatching {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:@"branch123://"];

    dispatch_queue_t queue = dispatch_queue_create("BNCURLFilterTests.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < 1000; i++) {
        dispatch_group_async(group, queue, ^{
            if (i % 2 == 0) {
                [filter useCustomPatternList:@[[NSString stringWithFormat:@"^branch\\d+:%lu", (unsigned long)i], @"^branch\\d+:"]];
            } else {
                [filter patternMatchingURL:url];
            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    XCTAssertTrue([filter shouldIgnoreURL:url]);
}

- (void)testConcurrentSetUrlPatternsToIgnore {
    Branch *branch = [Branch getInstance];

    dispatch_queue_t queue = dispatch_queue_create("BNCURLFilterTests.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < 1000; i++) {
        dispatch_group_async(group, queue, ^{
            [branch setUrlPatternsToIgnore:@[[NSString stringWithFormat:@"^branchtest%lu:", (unsigned long)i]]];
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    [branch setUrlPatternsToIgnore:@[]];
}

#pragma mark Default list

- (void)testDefaultPatternListState {
    BNCURLFilter *filter = [BNCURLFilter new];
    [self assertFilterHasDefaultList:filter];
    XCTAssertFalse(filter.isUpdatingPatternList);
    XCTAssertEqual(filter.patternList.count, 7);
}

- (void)testIgnoredDeprecatedAndGoogleURLs {
    NSArray *urls = @[
        @"li123456:login",
        @"pdk123456:login",
        @"twitterkit-abcdef:login",
        @"com.googleusercontent.apps.123456-abcdef:/oauth2redirect"
    ];

    BNCURLFilter *filter = [BNCURLFilter new];
    for (NSString *string in urls) {
        NSURL *URL = [NSURL URLWithString:string];
        XCTAssertTrue([filter shouldIgnoreURL:URL], @"Checking '%@'.", URL);
    }
}

- (void)testShouldIgnoreURL_nil {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = nil;
    XCTAssertFalse([filter shouldIgnoreURL:url]);
}

#pragma mark Custom list

- (void)testCustomPatternListSetsVersionZero {
    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useCustomPatternList:@[@"^branch\\d+:"]];
    XCTAssertEqual(filter.listVersion, 0);
    XCTAssertEqualObjects(filter.patternList, @[@"^branch\\d+:"]);
}

- (void)testCustomPatternList_emptyKeepsCurrentList {
    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useCustomPatternList:@[]];
    [self assertFilterHasDefaultList:filter];
}

- (void)testCustomPatternList_invalidRegexIsSkipped {
    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useCustomPatternList:@[@"[", @"^branch\\d+:"]];
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
}

- (void)testCustomPatternList_allInvalidIgnoresNothing {
    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useCustomPatternList:@[@"[", @"("]];
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

#pragma mark Saved list

- (void)testUseSavedPatternList {
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = @[@"^saved\\d+:"];
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 7;

    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useSavedPatternList];
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"saved123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertEqual(filter.listVersion, 7);
    XCTAssertFalse(filter.hasUpdatedPatternList);
}

- (void)testUseSavedPatternList_noSavedListKeepsDefault {
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = nil;
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 7;

    BNCURLFilter *filter = [BNCURLFilter new];
    [filter useSavedPatternList];
    [self assertFilterHasDefaultList:filter];
}

#pragma mark Server response handling

- (void)testProcessServerOperation_success {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSData *data = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:3];
    [filter processServerOperation:[self operationWithStatusCode:200 data:data error:nil]];

    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
    XCTAssertEqual(filter.listVersion, 3);
    XCTAssertTrue(filter.hasUpdatedPatternList);

    // the update is persisted for the next launch
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].savedURLPatternList, @[@"^branch\\d+:"]);
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].savedURLPatternListVersion, 3);
}

- (void)testProcessServerOperation_invalidRegexIsSkipped {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSData *data = [self skipListDataWithPatterns:@[@"[", @"^branch\\d+:"] version:3];
    [filter processServerOperation:[self operationWithStatusCode:200 data:data error:nil]];

    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertTrue(filter.hasUpdatedPatternList);
}

- (void)testProcessServerOperation_failuresKeepCurrentList {
    NSData *validData = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:3];
    NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    NSDictionary<NSString *, BNCURLFilterTestOperation *> *operations = @{
        @"404": [self operationWithStatusCode:404 data:validData error:nil],
        @"500": [self operationWithStatusCode:500 data:validData error:nil],
        @"network error": [self operationWithStatusCode:200 data:validData error:networkError],
        @"no data": [self operationWithStatusCode:200 data:nil error:nil],
        @"invalid JSON": [self operationWithStatusCode:200 data:[@"not json" dataUsingEncoding:NSUTF8StringEncoding] error:nil],
        @"missing list": [self operationWithStatusCode:200 data:[NSJSONSerialization dataWithJSONObject:@{ @"version": @3 } options:0 error:nil] error:nil],
        @"list not an array": [self operationWithStatusCode:200 data:[NSJSONSerialization dataWithJSONObject:@{ @"uri_skip_list": @"^branch\\d+:", @"version": @3 } options:0 error:nil] error:nil],
        @"missing version": [self operationWithStatusCode:200 data:[NSJSONSerialization dataWithJSONObject:@{ @"uri_skip_list": @[@"^branch\\d+:"] } options:0 error:nil] error:nil],
        @"version not a number": [self operationWithStatusCode:200 data:[NSJSONSerialization dataWithJSONObject:@{ @"uri_skip_list": @[@"^branch\\d+:"], @"version": @"3" } options:0 error:nil] error:nil],
    };

    [BNCPreferenceHelper sharedInstance].savedURLPatternList = @[@"^saved\\d+:"];
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 7;

    for (NSString *name in operations) {
        BNCURLFilter *filter = [BNCURLFilter new];
        [filter processServerOperation:operations[name]];

        XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]], @"Checking '%@'.", name);
        XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]], @"Checking '%@'.", name);
        XCTAssertEqual(filter.listVersion, -1, @"Checking '%@'.", name);
        XCTAssertFalse(filter.hasUpdatedPatternList, @"Checking '%@'.", name);

        // nothing is persisted
        XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].savedURLPatternList, @[@"^saved\\d+:"], @"Checking '%@'.", name);
        XCTAssertEqual([BNCPreferenceHelper sharedInstance].savedURLPatternListVersion, 7, @"Checking '%@'.", name);
    }
}

#pragma mark Server update (mock network)

- (void)testUpdatePatternList_requestsNextVersion {
    [self installMockNetworkService];
    bnc_mockStatusCode = 404;

    BNCURLFilter *filter = [BNCURLFilter new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Default list request"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    [BNCPreferenceHelper sharedInstance].savedURLPatternList = @[@"^saved\\d+:"];
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 7;
    [filter useSavedPatternList];
    expectation = [self expectationWithDescription:@"Saved list request"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    NSArray<NSURLRequest *> *requests = [BNCURLFilterTestNetworkService requests];
    XCTAssertEqual(requests.count, 2);
    NSString *baseURL = [BNCPreferenceHelper sharedInstance].patternListURL;
    XCTAssertEqualObjects(requests[0].URL.absoluteString, ([NSString stringWithFormat:@"%@/sdk/uriskiplist_v0.json", baseURL]));
    XCTAssertEqualObjects(requests[1].URL.absoluteString, ([NSString stringWithFormat:@"%@/sdk/uriskiplist_v8.json", baseURL]));
}

- (void)testUpdatePatternList_success {
    [self installMockNetworkService];
    bnc_mockResponseData = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:3];

    BNCURLFilter *filter = [BNCURLFilter new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"List updated"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertEqual(filter.listVersion, 3);
    XCTAssertTrue(filter.hasUpdatedPatternList);
    XCTAssertFalse(filter.isUpdatingPatternList);
}

- (void)testUpdatePatternList_skippedAfterSuccess {
    [self installMockNetworkService];

    BNCURLFilter *filter = [BNCURLFilter new];
    filter.hasUpdatedPatternList = YES;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion is not called"];
    expectation.inverted = YES;
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];

    XCTAssertEqual([BNCURLFilterTestNetworkService requests].count, 0);
}

- (void)testUpdatePatternList_skippedWhileInFlight {
    [self installMockNetworkService];

    BNCURLFilter *filter = [BNCURLFilter new];
    filter.isUpdatingPatternList = YES;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion is not called"];
    expectation.inverted = YES;
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];

    XCTAssertEqual([BNCURLFilterTestNetworkService requests].count, 0);
}

- (void)testUpdatePatternList_failureAllowsRetry {
    [self installMockNetworkService];
    bnc_mockStatusCode = 500;

    BNCURLFilter *filter = [BNCURLFilter new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Failed request"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    [self assertFilterHasDefaultList:filter];
    XCTAssertFalse(filter.isUpdatingPatternList);

    // a later call retries and can succeed
    bnc_mockStatusCode = 200;
    bnc_mockResponseData = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:3];
    expectation = [self expectationWithDescription:@"Retried request"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertEqual([BNCURLFilterTestNetworkService requests].count, 2);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
    XCTAssertTrue(filter.hasUpdatedPatternList);
}

- (void)testUpdatePatternList_nilOperationClearsInFlightFlag {
    [self installMockNetworkService];
    bnc_mockReturnsNilOperation = YES;

    BNCURLFilter *filter = [BNCURLFilter new];
    [filter updatePatternListFromServerWithCompletion:nil];
    XCTAssertFalse(filter.isUpdatingPatternList);

    // a later call is not blocked
    bnc_mockReturnsNilOperation = NO;
    bnc_mockStatusCode = 404;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Retried request"];
    [filter updatePatternListFromServerWithCompletion:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertEqual([BNCURLFilterTestNetworkService requests].count, 2);
}

#pragma mark Concurrency

// Overlapping session inits must not issue duplicate skip-list requests.
- (void)testConcurrentUpdatePatternList_singleRequestInFlight {
    [self installMockNetworkService];
    bnc_mockResponseData = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:3];
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    bnc_mockGate = gate;

    BNCURLFilter *filter = [BNCURLFilter new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Single completion"];
    expectation.expectedFulfillmentCount = 1;
    expectation.assertForOverFulfill = YES;

    dispatch_queue_t queue = dispatch_queue_create("BNCURLFilterTests.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < 100; i++) {
        dispatch_group_async(group, queue, ^{
            [filter updatePatternListFromServerWithCompletion:^{
                [expectation fulfill];
            }];
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    // every call has returned while the first request is still held open
    XCTAssertEqual([BNCURLFilterTestNetworkService requests].count, 1);
    XCTAssertTrue(filter.isUpdatingPatternList);

    dispatch_semaphore_signal(gate);
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertFalse(filter.isUpdatingPatternList);
    XCTAssertTrue(filter.hasUpdatedPatternList);
    XCTAssertTrue([filter shouldIgnoreURL:[NSURL URLWithString:@"branch123://"]]);
}

// Server responses completing in parallel while URLs are matched. Each list carries its own version as a
// pattern, so the final state also checks the list and version were swapped together.
- (void)testConcurrentProcessServerOperationAndMatching {
    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:@"branch123://"];

    dispatch_queue_t queue = dispatch_queue_create("BNCURLFilterTests.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < 400; i++) {
        dispatch_group_async(group, queue, ^{
            if (i % 2 == 0) {
                NSArray *patterns = @[@"^branch\\d+:", [NSString stringWithFormat:@"^version%lu:", (unsigned long)i]];
                NSData *data = [self skipListDataWithPatterns:patterns version:(NSInteger)i];
                [filter processServerOperation:[self operationWithStatusCode:200 data:data error:nil]];
            } else {
                [filter patternMatchingURL:url];
                [filter shouldIgnoreURL:url];
            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    XCTAssertTrue([filter shouldIgnoreURL:url]);
    XCTAssertTrue(filter.hasUpdatedPatternList);
    NSURL *versionURL = [NSURL URLWithString:[NSString stringWithFormat:@"version%ld://", (long)filter.listVersion]];
    XCTAssertTrue([filter shouldIgnoreURL:versionURL]);
}

// Every way of replacing the list, racing each other and the readers.
- (void)testConcurrentListReplacementAndMatching {
    [BNCPreferenceHelper sharedInstance].savedURLPatternList = @[@"^branch\\d+:"];
    [BNCPreferenceHelper sharedInstance].savedURLPatternListVersion = 7;

    BNCURLFilter *filter = [BNCURLFilter new];
    NSURL *url = [NSURL URLWithString:@"branch123://"];

    dispatch_queue_t queue = dispatch_queue_create("BNCURLFilterTests.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger i = 0; i < 400; i++) {
        dispatch_group_async(group, queue, ^{
            switch (i % 4) {
                case 0:
                    [filter useCustomPatternList:@[@"^branch\\d+:"]];
                    break;
                case 1:
                    [filter useSavedPatternList];
                    break;
                case 2: {
                    NSData *data = [self skipListDataWithPatterns:@[@"^branch\\d+:"] version:7];
                    [filter processServerOperation:[self operationWithStatusCode:200 data:data error:nil]];
                    break;
                }
                default:
                    [filter shouldIgnoreURL:url];
                    break;
            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    XCTAssertTrue([filter shouldIgnoreURL:url]);
    XCTAssertFalse([filter shouldIgnoreURL:[NSURL URLWithString:@"fb123://"]]);
}

@end

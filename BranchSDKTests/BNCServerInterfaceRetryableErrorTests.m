//
//  BNCServerInterfaceRetryableErrorTests.m
//  BranchSDKTests
//
//  Verifies that errors delivered by BNCServerInterface carry the additive
//  BNCErrorIsRetryableKey classification once the SDK's HTTP retries are exhausted.
//

#import <XCTest/XCTest.h>
#import "BNCServerInterface.h"
#import "BNCPreferenceHelper.h"
#import "BNCNetworkServiceProtocol.h"
#import "NSError+Branch.h"

// Expose the private exponential-backoff helper for direct verification.
@interface BNCServerInterface (Testing)
- (NSTimeInterval)backoffDelayForRetryNumber:(NSInteger)retryNumber;
@end

#pragma mark - Mock network operation

@interface BNCRetryMockOperation : NSObject <BNCNetworkOperationProtocol>
@property (nonatomic, readonly, copy) NSURLRequest *request;
@property (nonatomic, readonly, copy) NSHTTPURLResponse *response;
@property (nonatomic, readonly, strong) NSData *responseData;
@property (nonatomic, readonly, copy) NSError *error;
@property (nonatomic, readonly, copy) NSDate *startDate;
@property (nonatomic, readonly, copy) NSDate *timeoutDate;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, copy) void (^completion)(id<BNCNetworkOperationProtocol>);
@end

@implementation BNCRetryMockOperation
@synthesize request = _request, response = _response, responseData = _responseData,
            error = _error, startDate = _startDate, timeoutDate = _timeoutDate;

- (instancetype)initWithRequest:(NSURLRequest *)request
                       response:(NSHTTPURLResponse *)response
                          error:(NSError *)error {
    self = [super init];
    if (self) {
        _request = [request copy];
        _response = [response copy];
        _error = [error copy];
        _startDate = [NSDate date];
        _timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60];
    }
    return self;
}

- (void)start {
    if (self.completion) {
        self.completion(self);
    }
}

@end

#pragma mark - Mock network service

@interface BNCRetryMockNetworkService : NSObject <BNCNetworkServiceProtocol>
@property (nonatomic, strong) NSDictionary *userInfo;
// Configured by the test before use.
@property (nonatomic, strong) NSHTTPURLResponse *stubResponse;
@property (nonatomic, strong) NSError *stubError;
@property (nonatomic, assign) NSInteger operationCount;
@end

// Shared config so the class-instantiated service (`+new`) can reach test-provided stubs.
static NSHTTPURLResponse *gStubResponse = nil;
static NSError *gStubError = nil;
static NSInteger gOperationCount = 0;

@implementation BNCRetryMockNetworkService

+ (id<BNCNetworkServiceProtocol>)new {
    return [[self alloc] init];
}

- (id<BNCNetworkOperationProtocol>)networkOperationWithURLRequest:(NSMutableURLRequest *)request
                                                       completion:(void (^)(id<BNCNetworkOperationProtocol>))completion {
    gOperationCount += 1;
    BNCRetryMockOperation *op = [[BNCRetryMockOperation alloc] initWithRequest:request
                                                                      response:gStubResponse
                                                                         error:gStubError];
    op.completion = completion;
    return op;
}

- (void)cancelAllOperations { }

@end

#pragma mark - Tests

@interface BNCServerInterfaceRetryableErrorTests : XCTestCase
@property (nonatomic, strong) BNCServerInterface *serverInterface;
@property (nonatomic, strong) BNCPreferenceHelper *preferenceHelper;
@end

@implementation BNCServerInterfaceRetryableErrorTests

- (void)setUp {
    [super setUp];
    gStubResponse = nil;
    gStubError = nil;
    gOperationCount = 0;

    self.preferenceHelper = [[BNCPreferenceHelper alloc] init];
    self.preferenceHelper.retryCount = 3;
    self.preferenceHelper.retryInterval = 0; // don't slow the test down

    self.serverInterface = [[BNCServerInterface alloc] init];
    self.serverInterface.preferenceHelper = self.preferenceHelper;
    // Route the interface through our mock network service.
    [self.serverInterface setValue:[BNCRetryMockNetworkService new] forKey:@"networkService"];
}

- (void)tearDown {
    gStubResponse = nil;
    gStubError = nil;
    gOperationCount = 0;
    [super tearDown];
}

- (NSHTTPURLResponse *)responseWithStatus:(NSInteger)status {
    return [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api2.branch.io/v1/url"]
                                       statusCode:status
                                      HTTPVersion:@"HTTP/1.1"
                                     headerFields:nil];
}

// A network timeout (raw NSURLError) should be retried up to the limit, then delivered
// with BNCErrorIsRetryableKey == YES.
- (void)testTimeoutErrorIsRetriedAndDeliveredAsRetryable {
    gStubError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    __block NSError *deliveredError = nil;
    [self.serverInterface postRequest:@{}
                                  url:@"https://api2.branch.io/v1/url"
                                  key:@"key_live_test"
                             callback:^(BNCServerResponse *response, NSError *error) {
        deliveredError = error;
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];

    XCTAssertNotNil(deliveredError);
    XCTAssertNotNil(deliveredError.userInfo[BNCErrorIsRetryableKey]);
    XCTAssertTrue([deliveredError.userInfo[BNCErrorIsRetryableKey] boolValue]);
    // Initial attempt + retryCount retries.
    XCTAssertEqual(gOperationCount, self.preferenceHelper.retryCount + 1);
}

// A 500 response is retryable at the HTTP layer; after retries are exhausted the delivered
// error is still classified retryable (or nil error but retryable server response).
- (void)testServerErrorIsRetried {
    gStubResponse = [self responseWithStatus:500];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    [self.serverInterface postRequest:@{}
                                  url:@"https://api2.branch.io/v1/url"
                                  key:@"key_live_test"
                             callback:^(BNCServerResponse *response, NSError *error) {
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];
    XCTAssertEqual(gOperationCount, self.preferenceHelper.retryCount + 1);
}

// A 400 response is NOT retried; whatever error is surfaced is classified non-retryable
// when it originates from a Branch error code.
- (void)testBadRequestIsNotRetried {
    gStubResponse = [self responseWithStatus:400];

    XCTestExpectation *expectation = [self expectationWithDescription:@"callback"];
    [self.serverInterface postRequest:@{}
                                  url:@"https://api2.branch.io/v1/url"
                                  key:@"key_live_test"
                             callback:^(BNCServerResponse *response, NSError *error) {
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:5.0];
    // No retries for a 4xx.
    XCTAssertEqual(gOperationCount, 1);
}

#pragma mark - Exponential backoff

// Out of the box (retryInterval untouched) retries back off at 1s, 2s, 4s.
- (void)testBackoffIsOneTwoFourByDefault {
    BNCPreferenceHelper *defaults = [[BNCPreferenceHelper alloc] init];
    XCTAssertEqualWithAccuracy(defaults.retryInterval, 1.0, 0.0001);
    self.serverInterface.preferenceHelper = defaults;
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:0], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:1], 2.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:2], 4.0, 0.0001);
}

// Explicitly opting into a zero interval disables backoff and retries fire immediately.
- (void)testBackoffIsZeroWhenIntervalIsZero {
    self.preferenceHelper.retryInterval = 0;
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:0], 0.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:1], 0.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:2], 0.0, 0.0001);
}

// A base interval of 1s doubles on each successive retry: 1s, 2s, 4s, 8s.
- (void)testBackoffDoublesEachRetry {
    self.preferenceHelper.retryInterval = 1.0;
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:0], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:1], 2.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:2], 4.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:3], 8.0, 0.0001);
}

// Scales off whatever base interval is configured.
- (void)testBackoffScalesWithBaseInterval {
    self.preferenceHelper.retryInterval = 0.5;
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:0], 0.5, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:1], 1.0, 0.0001);
    XCTAssertEqualWithAccuracy([self.serverInterface backoffDelayForRetryNumber:2], 2.0, 0.0001);
}

@end

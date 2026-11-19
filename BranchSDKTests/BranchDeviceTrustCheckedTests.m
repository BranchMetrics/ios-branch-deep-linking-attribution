//
//  BranchDeviceTrustCheckedTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//
//  EMT-4318: the open response handlers decided whether a request had carried an
//  initialization_context by looking for a top-level attestationObject_b64 key that the provider
//  no longer emits, so deviceTrustChecked never flipped and the attestation claim was never
//  released. These tests pin the nested branch_sdk_secure_context shape the provider returns.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCRequestFactory.h"
#import "BNCServerResponse.h"
#import "BranchOpenRequest.h"
#import "BranchRequestOpen.h"

// Records what the host asks of the provider instead of attesting or signing.
@interface BNCFakeSecureSDKProvider : NSObject <BranchSecureSDKProvider>
@property (nonatomic, assign) NSInteger releaseCount;
@property (nonatomic, assign) NSInteger signCount;
@property (nonatomic, assign) NSInteger attestCount;
@end

@implementation BNCFakeSecureSDKProvider

- (void)initializeBranchSecureSDKWithBranchKey:(NSString *)branchKey {}

- (NSDictionary *)addDeviceTrustParams:(NSDictionary *)params {
    self.attestCount++;
    return @{ BRANCH_REQUEST_KEY_SECURE_CONTEXT: @{ BRANCH_REQUEST_KEY_SECURE_CONTEXT_INITIALIZATION: @{ @"attestation_object": @"b64" } } };
}

- (NSDictionary *)addSignatureAndNonceForParams:(NSDictionary *)params {
    self.signCount++;
    return @{ BRANCH_REQUEST_KEY_SECURE_CONTEXT: @{ @"activity_context": @{ @"nonce": @"n" } } };
}

- (void)releaseAttestationClaim {
    self.releaseCount++;
}

@end

// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
@interface Branch (DeviceTrustTest)
+ (void)resetInitializationGuardForTesting;
@end

@interface BranchDeviceTrustCheckedTests : XCTestCase
@property (nonatomic, strong) BNCFakeSecureSDKProvider *provider;
@property (nonatomic, assign) BOOL savedDeviceTrustChecked;
@property (nonatomic, assign) BOOL savedDropURLOpen;
@end

@implementation BranchDeviceTrustCheckedTests

- (void)setUp {
    [super setUp];
    // +sharedInstance requires the SDK to be initialized first.
    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"]];

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedDeviceTrustChecked = preferenceHelper.deviceTrustChecked;
    self.savedDropURLOpen = preferenceHelper.dropURLOpen;
    preferenceHelper.deviceTrustChecked = NO;
    preferenceHelper.dropURLOpen = NO;

    // The handler property is weak; the test owns the provider.
    self.provider = [BNCFakeSecureSDKProvider new];
    [Branch sharedInstance].fraudDefenseHandler = self.provider;
    XCTAssertEqual([Branch sharedInstance].fraudDefenseHandler, self.provider);
}

- (void)tearDown {
    [Branch sharedInstance].fraudDefenseHandler = nil;
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    preferenceHelper.deviceTrustChecked = self.savedDeviceTrustChecked;
    preferenceHelper.dropURLOpen = self.savedDropURLOpen;
    [super tearDown];
}

- (NSDictionary *)paramsWithInitializationContext {
    return @{
        @"ios_vendor_id": @"vendor",
        BRANCH_REQUEST_KEY_SECURE_CONTEXT: @{
            @"context_key": @"vendor",
            BRANCH_REQUEST_KEY_SECURE_CONTEXT_INITIALIZATION: @{ @"attestation_object": @"b64" }
        }
    };
}

- (NSDictionary *)paramsWithActivityContext {
    return @{
        @"ios_vendor_id": @"vendor",
        BRANCH_REQUEST_KEY_SECURE_CONTEXT: @{
            @"context_key": @"vendor",
            @"activity_context": @{ @"request_signature": @"sig", @"nonce": @"n" }
        }
    };
}

- (BNCServerResponse *)successResponse {
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @200;
    response.data = @{};
    return response;
}

- (NSError *)networkError {
    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
}

- (void)processRequestOpenWithParams:(NSDictionary *)params error:(NSError *)error {
    BranchRequestOpen *request = [[BranchRequestOpen alloc] initWithCallback:nil isInstall:NO];
    request.requestParams = params;
    [request processResponse:[self successResponse] error:error];
}

- (void)processOpenRequestWithParams:(NSDictionary *)params error:(NSError *)error {
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:nil isInstall:NO];
    request.requestParams = params;
    [request processResponse:[self successResponse] error:error];
}

#pragma mark - paramsCarryInitializationContext:

- (void)testDetectsNestedInitializationContext {
    XCTAssertTrue([BNCRequestFactory paramsCarryInitializationContext:[self paramsWithInitializationContext]]);
}

- (void)testActivityContextIsNotAnInitializationContext {
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:[self paramsWithActivityContext]]);
}

- (void)testMissingOrMalformedSecureContextIsNotAnInitializationContext {
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:nil]);
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:@{}]);
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:@{ BRANCH_REQUEST_KEY_SECURE_CONTEXT: @"not a dictionary" }]);
    // The stale pre-envelope shape must not count.
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:@{ @"attestationObject_b64": @"b64" }]);
}

#pragma mark - BranchRequestOpen

- (void)testRequestOpenSuccessWithInitializationContextMarksDeviceTrustChecked {
    [self processRequestOpenWithParams:[self paramsWithInitializationContext] error:nil];

    XCTAssertTrue([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

- (void)testRequestOpenFailureWithInitializationContextReleasesClaimOnly {
    [self processRequestOpenWithParams:[self paramsWithInitializationContext] error:[self networkError]];

    XCTAssertFalse([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

// dropURLOpen turns the failure into a dummy success; the server still never saw the attestation.
- (void)testRequestOpenDroppedURLFailureDoesNotMarkDeviceTrustChecked {
    [BNCPreferenceHelper sharedInstance].dropURLOpen = YES;

    [self processRequestOpenWithParams:[self paramsWithInitializationContext] error:[self networkError]];

    XCTAssertFalse([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

- (void)testRequestOpenSuccessWithoutInitializationContextLeavesFlagAlone {
    [self processRequestOpenWithParams:[self paramsWithActivityContext] error:nil];

    XCTAssertFalse([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 0);
}

#pragma mark - BranchOpenRequest

- (void)testOpenRequestSuccessWithInitializationContextMarksDeviceTrustChecked {
    [self processOpenRequestWithParams:[self paramsWithInitializationContext] error:nil];

    XCTAssertTrue([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

- (void)testOpenRequestFailureWithInitializationContextReleasesClaimOnly {
    [self processOpenRequestWithParams:[self paramsWithInitializationContext] error:[self networkError]];

    XCTAssertFalse([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

- (void)testOpenRequestDroppedURLFailureDoesNotMarkDeviceTrustChecked {
    [BNCPreferenceHelper sharedInstance].dropURLOpen = YES;

    [self processOpenRequestWithParams:[self paramsWithInitializationContext] error:[self networkError]];

    XCTAssertFalse([BNCPreferenceHelper sharedInstance].deviceTrustChecked);
    XCTAssertEqual(self.provider.releaseCount, 1);
}

#pragma mark - addSignatureAndNonceParams:

// Until the backend has acknowledged an initialization_context it holds no HMAC secret for this
// device, so nothing may be signed — this is the only path left at attribution level NONE.
- (void)testSigningIsSkippedBeforeDeviceTrustIsChecked {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_live_test" UUID:@"uuid" TimeStamp:@0];
    NSMutableDictionary *json = [@{ @"ios_vendor_id": @"vendor" } mutableCopy];

    [factory addSignatureAndNonceParams:json];

    XCTAssertEqual(self.provider.signCount, 0);
    XCTAssertNil(json[BRANCH_REQUEST_KEY_SECURE_CONTEXT]);
}

- (void)testSigningRunsOnceDeviceTrustIsChecked {
    [BNCPreferenceHelper sharedInstance].deviceTrustChecked = YES;
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_live_test" UUID:@"uuid" TimeStamp:@0];
    NSMutableDictionary *json = [@{ @"ios_vendor_id": @"vendor" } mutableCopy];

    [factory addSignatureAndNonceParams:json];

    XCTAssertEqual(self.provider.signCount, 1);
    XCTAssertNotNil(json[BRANCH_REQUEST_KEY_SECURE_CONTEXT]);
}

#pragma mark - Attestation is sent only on the open request

- (BNCRequestFactory *)factory {
    return [[BNCRequestFactory alloc] initWithBranchKey:@"key_live_test" UUID:@"uuid" TimeStamp:@0];
}

- (void)testRequestOpenAttestsBeforeDeviceTrustIsChecked {
    NSDictionary *json = [[self factory] dataForRequestOpenWithURLString:nil];

    XCTAssertEqual(self.provider.attestCount, 1);
    XCTAssertTrue([BNCRequestFactory paramsCarryInitializationContext:json]);
}

- (void)testDeepLinkDoesNotAttestBeforeDeviceTrustIsChecked {
    NSDictionary *json = [[self factory] dataForDeepLinkWithURLString:@"https://example.app.link/abc"];

    XCTAssertEqual(self.provider.attestCount, 0);
    XCTAssertEqual(self.provider.signCount, 0);
    XCTAssertNil(json[BRANCH_REQUEST_KEY_SECURE_CONTEXT]);
}

- (void)testDeepLinkIsSignedOnceAfterDeviceTrustIsChecked {
    [BNCPreferenceHelper sharedInstance].deviceTrustChecked = YES;

    NSDictionary *json = [[self factory] dataForDeepLinkWithURLString:@"https://example.app.link/abc"];

    XCTAssertEqual(self.provider.attestCount, 0);
    XCTAssertEqual(self.provider.signCount, 1);
    XCTAssertFalse([BNCRequestFactory paramsCarryInitializationContext:json]);
    XCTAssertNotNil(json[BRANCH_REQUEST_KEY_SECURE_CONTEXT]);
}

@end

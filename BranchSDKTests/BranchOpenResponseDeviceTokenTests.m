//
//  BranchOpenResponseDeviceTokenTests.m
//  BranchSDKTests
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerResponse.h"
#import "BranchOpenRequest.h"
#import "BranchRequestOpen.h"

static NSString * const deprecatedDeviceTokenKey = @"device_fingerprint_id";

@interface BranchOpenResponseDeviceTokenTests : XCTestCase
@property (nonatomic, copy) NSString *savedDeviceToken;
@end

@implementation BranchOpenResponseDeviceTokenTests

- (void)setUp {
    self.savedDeviceToken = [BNCPreferenceHelper sharedInstance].randomizedDeviceToken;
    [BNCPreferenceHelper sharedInstance].randomizedDeviceToken = nil;
}

- (void)tearDown {
    [BNCPreferenceHelper sharedInstance].randomizedDeviceToken = self.savedDeviceToken;
}

- (BNCServerResponse *)responseWithData:(NSDictionary *)data {
    BNCServerResponse *response = [[BNCServerResponse alloc] init];
    response.statusCode = @200;
    response.data = data;
    return response;
}

- (void)processOpenResponseData:(NSDictionary *)data {
    BranchRequestOpen *request = [[BranchRequestOpen alloc] initWithCallback:nil isInstall:NO];
    [request processResponse:[self responseWithData:data] error:nil];
}

- (void)processLegacyOpenResponseData:(NSDictionary *)data {
    BranchOpenRequest *request = [[BranchOpenRequest alloc] initWithCallback:nil isInstall:NO];
    [request processResponse:[self responseWithData:data] error:nil];
}

#pragma mark - BranchRequestOpen

// The regression: a response carrying only the deprecated key stored no device token,
// because the fallback was nested inside a guard requiring the modern key.
- (void)testRequestOpenStoresDeviceTokenFromDeprecatedKeyOnly {
    [self processOpenResponseData:@{ deprecatedDeviceTokenKey: @"legacy_device_token" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"legacy_device_token");
}

- (void)testRequestOpenStoresDeviceTokenFromModernKey {
    [self processOpenResponseData:@{ BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"modern_device_token" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"modern_device_token");
}

- (void)testRequestOpenPrefersModernKeyOverDeprecatedKey {
    [self processOpenResponseData:@{
        BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"modern_device_token",
        deprecatedDeviceTokenKey: @"legacy_device_token"
    }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"modern_device_token");
}

// A response carrying neither key must not clobber a token from an earlier session.
- (void)testRequestOpenKeepsExistingDeviceTokenWhenResponseHasNeitherKey {
    [BNCPreferenceHelper sharedInstance].randomizedDeviceToken = @"previously_stored_token";

    [self processOpenResponseData:@{ BRANCH_RESPONSE_KEY_SESSION_ID: @"session_id" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"previously_stored_token");
}

// The wire may deliver these identifiers as numbers, but the property is an NSString.
- (void)testRequestOpenNormalizesNumericDeviceToken {
    [self processOpenResponseData:@{ deprecatedDeviceTokenKey: @1234567890 }];

    NSString *token = [BNCPreferenceHelper sharedInstance].randomizedDeviceToken;
    XCTAssertTrue([token isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(token, @"1234567890");
}

#pragma mark - BranchOpenRequest

- (void)testOpenRequestStoresDeviceTokenFromDeprecatedKeyOnly {
    [self processLegacyOpenResponseData:@{ deprecatedDeviceTokenKey: @"legacy_device_token" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"legacy_device_token");
}

- (void)testOpenRequestStoresDeviceTokenFromModernKey {
    [self processLegacyOpenResponseData:@{ BRANCH_RESPONSE_KEY_RANDOMIZED_DEVICE_TOKEN: @"modern_device_token" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"modern_device_token");
}

- (void)testOpenRequestKeepsExistingDeviceTokenWhenResponseHasNeitherKey {
    [BNCPreferenceHelper sharedInstance].randomizedDeviceToken = @"previously_stored_token";

    [self processLegacyOpenResponseData:@{ BRANCH_RESPONSE_KEY_SESSION_ID: @"session_id" }];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].randomizedDeviceToken, @"previously_stored_token");
}

- (void)testOpenRequestNormalizesNumericDeviceToken {
    [self processLegacyOpenResponseData:@{ deprecatedDeviceTokenKey: @1234567890 }];

    NSString *token = [BNCPreferenceHelper sharedInstance].randomizedDeviceToken;
    XCTAssertTrue([token isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(token, @"1234567890");
}

@end

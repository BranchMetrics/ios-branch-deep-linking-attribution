//
//  BranchConfigurationTests.m
//  Branch-SDK-Tests
//
//  Created by Brandon Boothe on 7/21/26.
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BranchLogger.h"
#import "BranchDMAParameters.h"
#import "BNCPreferenceHelper.h"
// BranchConfigurationController is now implemented in Swift (BranchSwiftSDK).
#if SWIFT_PACKAGE
@import BranchSwiftSDK;
#elif __has_include(<BranchSDK/BranchSDK-Swift.h>)
#import <BranchSDK/BranchSDK-Swift.h>
#else
#import "BranchSDK-Swift.h"
#endif

@interface Branch (BranchConfigurationTest)
// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
+ (void)resetInitializationGuardForTesting;
@end

@interface BranchConfigurationTests : XCTestCase
@end

@implementation BranchConfigurationTests

#pragma mark - Defaults

- (void)testDefaults {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    XCTAssertEqualObjects(config.branchKey, @"key_live_abc");
    XCTAssertFalse(config.testMode);
    XCTAssertNil(config.apiUrl);
    XCTAssertNil(config.safeTrackAPIUrl);
    XCTAssertNil(config.cdnBaseUrl);
    XCTAssertFalse(config.euEndpoint);
    XCTAssertEqual(config.logLevel, BranchLogLevelError);
    XCTAssertNil(config.loggingCallback);
    XCTAssertNil(config.requestTracingCallback);
    XCTAssertEqualWithAccuracy(config.networkTimeout, 5.5, 0.001);
    XCTAssertEqual(config.retryCount, 3);
    XCTAssertEqualWithAccuracy(config.retryInterval, 0, 0.001);
    XCTAssertNil(config.remoteInterface);
    XCTAssertEqualWithAccuracy(config.thirdPartyAPIsWaitTime, 0.5, 0.001);
    XCTAssertNil(config.attributionLevel);
    XCTAssertFalse(config.limitFacebookAttribution);
    XCTAssertFalse(config.adNetworkCalloutsDisabled);
    XCTAssertNil(config.dmaParameters);
    XCTAssertEqual(config.allowedSchemes.count, 0);
    XCTAssertEqual(config.urlPatternsToIgnore.count, 0);
    XCTAssertEqual(config.requestMetadata.count, 0);
    XCTAssertTrue(config.automaticOpenEvents);
    XCTAssertFalse(config.checkPasteboardOnInstall);
    XCTAssertNil(config.appClipAppGroup);
    XCTAssertNil(config.deepLinkDebugParams);
}

#pragma mark - Factory helpers

- (void)testDebugFactory {
    BranchConfiguration *config = [BranchConfiguration debug:@"key_test_abc"];
    XCTAssertEqual(config.logLevel, BranchLogLevelVerbose);
    XCTAssertTrue(config.testMode);
}

- (void)testProductionFactory {
    BranchConfiguration *config = [BranchConfiguration production:@"key_live_abc"];
    XCTAssertEqual(config.logLevel, BranchLogLevelWarning);
    XCTAssertFalse(config.testMode);
}

- (void)testComplianceFactory {
    BranchConfiguration *config = [BranchConfiguration compliance:@"key_live_abc"];
    XCTAssertEqualObjects(config.attributionLevel, BranchAttributionLevelMinimal);
}

#pragma mark - Collection mutators

- (void)testAddAllowedScheme {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [config addAllowedScheme:@"myapp"];
    [config addAllowedScheme:@"https"];
    XCTAssertEqualObjects(config.allowedSchemes, (@[@"myapp", @"https"]));
}

- (void)testAddMetadata {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [config addMetadataWithKey:@"store" value:@"app_store"];
    XCTAssertEqualObjects(config.requestMetadata[@"store"], @"app_store");
}

- (void)testDMAParameters {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.dmaParameters = [BranchDMAParameters eeaRegion:YES
                                adPersonalizationConsent:NO
                                  adUserDataUsageConsent:YES];
    XCTAssertNotNil(config.dmaParameters);
    XCTAssertTrue(config.dmaParameters.eeaRegion);
    XCTAssertFalse(config.dmaParameters.adPersonalizationConsent);
    XCTAssertTrue(config.dmaParameters.adUserDataUsageConsent);
}

- (void)testDMAParametersImmutableValueSemantics {
    // A DMAParameters object assigned to the config should preserve its named field values regardless of
    // assignment order — the whole point of replacing the three positional booleans.
    BranchDMAParameters *params = [BranchDMAParameters eeaRegion:NO
                                       adPersonalizationConsent:YES
                                         adUserDataUsageConsent:NO];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.dmaParameters = params;
    XCTAssertFalse(config.dmaParameters.eeaRegion);
    XCTAssertTrue(config.dmaParameters.adPersonalizationConsent);
    XCTAssertFalse(config.dmaParameters.adUserDataUsageConsent);
}

#pragma mark - Validation

- (void)testValidateAcceptsValidConfig {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    XCTAssertNoThrow([config validate]);
}

- (void)testValidateRejectsEmptyKey {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@""];
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateRejectsZeroTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 0;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateRejectsExcessiveTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 61;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateAcceptsBoundaryTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 60;
    XCTAssertNoThrow([config validate]);
}

- (void)testValidateRejectsNegativeRetryCount {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.retryCount = -1;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateRejectsNegativeRetryInterval {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.retryInterval = -1;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateRejectsZeroThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 0;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateRejectsExcessiveThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 11;
    XCTAssertThrowsSpecificNamed([config validate], NSException, NSInvalidArgumentException);
}

- (void)testValidateAcceptsBoundaryThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 10;
    XCTAssertNoThrow([config validate]);
}

#pragma mark - initialize: reinitialization guard

// These tests mutate the process-wide singleton, so they reset the guard around each run.
- (void)testInitializeReturnsInstance {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    Branch *branch = [Branch initialize:config];
    XCTAssertNotNil(branch);
}

- (void)testInitializeSetsKeySourceToInitFunction {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [Branch initialize:config];
    XCTAssertEqualObjects([BranchConfigurationController sharedInstance].branchKeySource,
                          BRANCH_KEY_SOURCE_INIT_FUNCTION);
}

- (void)testSecondInitializeIsIgnoredAndReturnsSameInstance {
    [Branch resetInitializationGuardForTesting];

    BranchConfiguration *first = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    first.networkTimeout = 10.0;
    Branch *branch1 = [Branch initialize:first];
    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 10.0, 0.001);

    // A second initialize: must warn and no-op: its settings are NOT applied.
    BranchConfiguration *second = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    second.networkTimeout = 20.0;
    Branch *branch2 = [Branch initialize:second];

    XCTAssertEqual(branch1, branch2, @"Reinitialization must return the existing singleton");
    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 10.0, 0.001,
                               @"Second initialize: must not re-apply configuration");
}

- (void)testInitializeAppliesCheckPasteboardOnInstall {
    [Branch resetInitializationGuardForTesting];
    [BranchConfigurationController sharedInstance].checkPasteboardOnInstall = NO;

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.checkPasteboardOnInstall = YES;
    [Branch initialize:config];

    XCTAssertTrue([BranchConfigurationController sharedInstance].checkPasteboardOnInstall,
                  @"initialize: must enable pasteboard checking when configured");
}

- (void)testInitializeDoesNotEnablePasteboardByDefault {
    [Branch resetInitializationGuardForTesting];
    [BranchConfigurationController sharedInstance].checkPasteboardOnInstall = NO;

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [Branch initialize:config];

    XCTAssertFalse([BranchConfigurationController sharedInstance].checkPasteboardOnInstall,
                   @"initialize: must not enable pasteboard checking when the flag is off");
}

- (void)testInitializeAppliesConfigAfterGuardReset {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *first = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    first.networkTimeout = 10.0;
    [Branch initialize:first];

    // After resetting the guard, initialize: is allowed to apply configuration again.
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *second = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    second.networkTimeout = 15.0;
    [Branch initialize:second];

    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 15.0, 0.001);
}

@end

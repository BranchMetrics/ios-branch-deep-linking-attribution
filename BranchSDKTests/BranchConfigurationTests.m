//
//  BranchConfigurationTests.m
//  Branch-SDK-Tests
//
//  Created by Brandon Boothe on 7/21/26.
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConfiguration+Private.h"
#import "BranchConstants.h"
#import "BranchLogger.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerAPI.h"
#import "BranchConfigurationController.h"
#import "NSError+Branch.h"

@interface Branch (BranchConfigurationTest)
// Test-only reset for the +initialize: reinitialization guard (file-private in Branch.m).
+ (void)resetInitializationGuardForTesting;
@end

@interface BranchConfigurationTests : XCTestCase
@end

@implementation BranchConfigurationTests

// BranchLogger is a dispatch_once singleton, so logger state leaks between tests unless it is put
// back to the values +[BranchLogger shared] starts with.
- (void)setUp {
    [super setUp];
    [self resetSharedLogger];
    [self resetSharedServerAPI];
}

- (void)tearDown {
    [self resetSharedLogger];
    [self resetSharedServerAPI];
    [super tearDown];
}

// BNCServerAPI is a singleton too, and the EU routing tests below write to it directly.
- (void)resetSharedServerAPI {
    [BNCServerAPI sharedInstance].useEUServers = NO;
}

- (void)resetSharedLogger {
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = NO;
    logger.logLevelThreshold = BranchLogLevelDebug;
    logger.logCallback = nil;
    logger.advancedLogCallback = nil;
}

#pragma mark - Defaults

- (void)testDefaults {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    XCTAssertEqualObjects(config.branchKey, @"key_live_abc");
    XCTAssertFalse(config.testMode);
    XCTAssertNil(config.apiUrl);
    XCTAssertNil(config.safeTrackAPIUrl);
    XCTAssertNil(config.cdnBaseUrl);
    XCTAssertFalse(config.euEndpoint);
    XCTAssertFalse(config.euEndpointWasSet, @"A fresh configuration must not report euEndpoint as set");
    XCTAssertEqual(config.logLevel, BranchLogLevelError);
    XCTAssertFalse(config.logLevelWasSet, @"A fresh configuration must not report logLevel as set");
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
    XCTAssertTrue(config.logLevelWasSet, @"The debug preset must count as an explicit log level");
    XCTAssertTrue(config.testMode);
}

- (void)testProductionFactory {
    BranchConfiguration *config = [BranchConfiguration production:@"key_live_abc"];
    XCTAssertEqual(config.logLevel, BranchLogLevelWarning);
    XCTAssertTrue(config.logLevelWasSet);
    XCTAssertFalse(config.testMode);
}

- (void)testComplianceFactory {
    BranchConfiguration *config = [BranchConfiguration compliance:@"key_live_abc"];
    XCTAssertEqualObjects(config.attributionLevel, BranchAttributionLevelMinimal);
}

#pragma mark - Log level "was set" tracking

// BranchLogLevelVerbose is the first case of BranchLogLevel and therefore 0, so the value alone
// cannot distinguish "never assigned" from "assigned Verbose". These pin the flag that does.
- (void)testAssigningVerboseMarksLogLevelAsSet {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.logLevel = BranchLogLevelVerbose;
    XCTAssertEqual(config.logLevel, BranchLogLevelVerbose);
    XCTAssertTrue(config.logLevelWasSet, @"Assigning Verbose (== 0) must still count as set");
}

- (void)testAssigningTheDefaultLevelMarksLogLevelAsSet {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.logLevel = BranchLogLevelError;
    XCTAssertTrue(config.logLevelWasSet,
                  @"Deliberately asking for Error must be distinguishable from leaving the default");
}

#pragma mark - initialize: logging

- (void)testInitializeDoesNotEnableLoggingByDefault {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [Branch initialize:config];

    XCTAssertFalse([BranchLogger shared].loggingEnabled,
                   @"initialize: must not enable logging for a caller who never asked for it");
}

- (void)testInitializeEnablesVerboseLoggingForDebugPreset {
    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[BranchConfiguration debug:@"key_test_abc"]];

    XCTAssertTrue([BranchLogger shared].loggingEnabled,
                  @"The debug preset exists to produce verbose output");
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelVerbose);
}

- (void)testInitializeEnablesLoggingAtExplicitDebugLevel {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.logLevel = BranchLogLevelDebug;
    [Branch initialize:config];

    XCTAssertTrue([BranchLogger shared].loggingEnabled);
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelDebug);
}

- (void)testInitializeEnablesLoggingAtExplicitErrorLevel {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.logLevel = BranchLogLevelError;
    [Branch initialize:config];

    XCTAssertTrue([BranchLogger shared].loggingEnabled,
                  @"An explicit Error level must enable logging, even though it equals the default value");
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelError);
}

- (void)testInitializeWithLoggingCallbackEnablesLoggingAtVerbose {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.logLevel = BranchLogLevelVerbose;
    config.loggingCallback = ^(NSString *message, BranchLogLevel logLevel, NSError *error) {};
    [Branch initialize:config];

    XCTAssertTrue([BranchLogger shared].loggingEnabled);
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelVerbose);
    XCTAssertNotNil([BranchLogger shared].logCallback);
}

- (void)testInitializeLeavesAnAlreadyEnabledLoggerAloneWhenLogLevelIsUnset {
    // Mirrors the branch.json enableLogging path, which runs during singleton creation — before
    // applyConfiguration:. A configuration that says nothing about logging must not undo it.
    [Branch resetInitializationGuardForTesting];
    [Branch enableLogging];

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    [Branch initialize:config];

    XCTAssertTrue([BranchLogger shared].loggingEnabled);
    XCTAssertEqual([BranchLogger shared].logLevelThreshold, BranchLogLevelDebug);
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

// Asserts that validation failed and that the out-param carries a Branch-domain
// BNCInvalidConfigurationError whose failure reason names the offending field.
- (void)assertValidationFails:(BranchConfiguration *)config reasonContains:(NSString *)fragment {
    NSError *error = nil;
    XCTAssertFalse([config validate:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, [NSError bncErrorDomain]);
    XCTAssertEqual(error.code, BNCInvalidConfigurationError);
    XCTAssertTrue([error.userInfo[NSLocalizedFailureReasonErrorKey] containsString:fragment],
                  @"Expected failure reason to mention '%@', got '%@'",
                  fragment, error.userInfo[NSLocalizedFailureReasonErrorKey]);
}

- (void)testValidateAcceptsValidConfig {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    NSError *error = nil;
    XCTAssertTrue([config validate:&error]);
    XCTAssertNil(error);
}

- (void)testValidateAcceptsNullErrorOutParam {
    // A caller that does not care about the reason must not crash on the failure path.
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@""];
    XCTAssertFalse([config validate:NULL]);
}

- (void)testValidateRejectsEmptyKey {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@""];
    [self assertValidationFails:config reasonContains:@"Branch key cannot be empty"];
}

- (void)testValidateRejectsZeroTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 0;
    [self assertValidationFails:config reasonContains:@"Network timeout must be a positive number"];
}

- (void)testValidateRejectsExcessiveTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 61;
    [self assertValidationFails:config reasonContains:@"Network timeout cannot exceed 60 seconds"];
}

- (void)testValidateAcceptsBoundaryTimeout {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = 60;
    NSError *error = nil;
    XCTAssertTrue([config validate:&error]);
    XCTAssertNil(error);
}

- (void)testValidateRejectsNegativeRetryCount {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.retryCount = -1;
    [self assertValidationFails:config reasonContains:@"Retry count must be >= 0"];
}

- (void)testValidateRejectsNegativeRetryInterval {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.retryInterval = -1;
    [self assertValidationFails:config reasonContains:@"Retry interval must be >= 0"];
}

- (void)testValidateRejectsZeroThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 0;
    [self assertValidationFails:config reasonContains:@"Third-party APIs wait time"];
}

- (void)testValidateRejectsExcessiveThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 11;
    [self assertValidationFails:config reasonContains:@"Third-party APIs wait time"];
}

- (void)testValidateAcceptsBoundaryThirdPartyAPIsWaitTime {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.thirdPartyAPIsWaitTime = 10;
    NSError *error = nil;
    XCTAssertTrue([config validate:&error]);
    XCTAssertNil(error);
}

- (void)testValidateRejectsNonHTTPAPIUrl {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.apiUrl = @"api.branch.io";
    [self assertValidationFails:config reasonContains:@"custom apiUrl"];
}

- (void)testValidateRejectsNonHTTPSafeTrackAPIUrl {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.safeTrackAPIUrl = @"safetrack.branch.io";
    [self assertValidationFails:config reasonContains:@"custom safeTrackAPIUrl"];
}

#pragma mark - initialize: error reporting

// `configuration` is declared nonnull, so nil arrives through a variable to keep -Wnonnull quiet
// while still covering the runtime guard an Objective-C caller can trip.
- (void)testInitializeWithNilConfigurationReturnsNil {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *nilConfiguration = nil;
    XCTAssertNil([Branch initialize:nilConfiguration]);
}

- (void)testInitializeWithInvalidConfigurationReturnsNil {
    [Branch resetInitializationGuardForTesting];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = -1;
    XCTAssertNil([Branch initialize:config]);
}

// Logging is configured before validation runs, so a configuration that fails validation is still
// reported through the loggingCallback set on that same configuration.
- (void)testInitializeReportsValidationFailureToConfigurationLoggingCallback {
    [Branch resetInitializationGuardForTesting];

    NSMutableString *captured = [NSMutableString string];
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.networkTimeout = -1;
    config.logLevel = BranchLogLevelError;
    config.loggingCallback = ^(NSString *message, BranchLogLevel logLevel, NSError *error) {
        @synchronized (captured) {
            [captured appendString:message];
        }
    };

    XCTAssertNil([Branch initialize:config]);
    @synchronized (captured) {
        XCTAssertTrue([captured containsString:@"Network timeout"]);
        XCTAssertTrue([captured containsString:@"Failed to initialize Branch"]);
    }
}

- (void)testInitializeWithInvalidConfigurationDoesNotConsumeTheGuard {
    // A rejected configuration must leave the singleton uninitialized, so a corrected call still
    // applies its settings rather than hitting the reinitialization warning.
    [Branch resetInitializationGuardForTesting];

    BranchConfiguration *invalid = [[BranchConfiguration alloc] initWithKey:@""];
    XCTAssertNil([Branch initialize:invalid]);

    BranchConfiguration *valid = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    valid.networkTimeout = 12.0;
    XCTAssertNotNil([Branch initialize:valid]);
    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 12.0, 0.001);
}

#pragma mark - initialize: EU endpoint routing

// euEndpoint is assigned rather than only turned on, so all three states are distinguishable:
// unset leaves routing alone, YES turns it on, NO turns it back off.
- (void)testInitializeLeavesEURoutingAloneWhenEuEndpointUnset {
    [Branch resetInitializationGuardForTesting];
    [BNCServerAPI sharedInstance].useEUServers = YES;

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    XCTAssertNotNil([Branch initialize:config]);

    XCTAssertTrue([BNCServerAPI sharedInstance].useEUServers,
                  @"A configuration that never touches euEndpoint must not change EU routing");
}

- (void)testInitializeEnablesEURoutingWhenEuEndpointYES {
    [Branch resetInitializationGuardForTesting];
    [BNCServerAPI sharedInstance].useEUServers = NO;

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.euEndpoint = YES;
    XCTAssertNotNil([Branch initialize:config]);

    XCTAssertTrue([BNCServerAPI sharedInstance].useEUServers);
}

- (void)testInitializeDisablesEURoutingWhenEuEndpointExplicitlyNO {
    [Branch resetInitializationGuardForTesting];
    // Stands in for a prior -[Branch useEUEndpoints] call, which is the only other writer.
    [BNCServerAPI sharedInstance].useEUServers = YES;

    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.euEndpoint = NO;
    XCTAssertTrue(config.euEndpointWasSet, @"Assigning NO must still record the assignment");
    XCTAssertNotNil([Branch initialize:config]);

    XCTAssertFalse([BNCServerAPI sharedInstance].useEUServers,
                   @"An explicit euEndpoint = NO must undo a prior useEUEndpoints call");
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

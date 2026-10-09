//
//  BranchUpdateConfigurationTests.m
//  BranchSDKTests
//
//  Created by Brandon Boothe on 10/8/26.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchConfiguration+Private.h"
#import "BranchLogger.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerAPI.h"
#import "BNCPasteboard.h"
#import "BNCPartnerParameters.h"

@interface Branch (BranchUpdateConfigurationTest)
+ (void)resetInitializationGuardForTesting;
+ (void)resetBranchKey;
+ (void)setUseTestBranchKey:(BOOL)useTestKey;
@end

@interface BranchUpdateConfigurationTests : XCTestCase
@property (nonatomic, strong) NSMutableArray<NSString *> *warnings;
@end

@implementation BranchUpdateConfigurationTests

// +initialize: and +updateConfiguration: write process-wide singletons. Each is reset around every
// test so values set here do not leak into later test classes.
- (void)setUp {
    [super setUp];
    [Branch resetBranchKey];
    [Branch resetInitializationGuardForTesting];
    [self resetSharedState];
    [self captureWarnings];
}

- (void)tearDown {
    [Branch resetBranchKey];
    [Branch setUseTestBranchKey:NO];
    [Branch resetInitializationGuardForTesting];
    [self resetSharedState];
    [super tearDown];
}

- (void)resetSharedState {
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = NO;
    logger.logLevelThreshold = BranchLogLevelDebug;
    logger.logCallback = nil;
    logger.advancedLogCallback = nil;

    [BNCServerAPI sharedInstance].useEUServers = NO;
    [BNCServerAPI sharedInstance].customAPIURL = nil;
    [BNCPasteboard sharedInstance].checkOnInstall = NO;
    [BNCPreferenceHelper sharedInstance].attributionLevel = BranchAttributionLevelFull;
    [[BNCPartnerParameters shared] clearAllParameters];
}

- (void)captureWarnings {
    NSMutableArray<NSString *> *warnings = [NSMutableArray array];
    self.warnings = warnings;
    BranchLogger *logger = [BranchLogger shared];
    logger.loggingEnabled = YES;
    logger.logLevelThreshold = BranchLogLevelWarning;
    logger.logCallback = ^(NSString *message, BranchLogLevel logLevel, NSError *error) {
        @synchronized (warnings) {
            [warnings addObject:message];
        }
    };
}

- (BOOL)warningsContain:(NSString *)fragment {
    @synchronized (self.warnings) {
        for (NSString *message in self.warnings) {
            if ([message containsString:fragment]) {
                return YES;
            }
        }
    }
    return NO;
}

- (Branch *)initializeWith:(void (^)(BranchConfiguration *config))block {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    if (block) {
        block(config);
    }
    Branch *branch = [Branch initialize:config];
    XCTAssertNotNil(branch);
    return branch;
}

- (BranchConfiguration *)updateConfiguration {
    return [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
}

#pragma mark - Assignment tracking

- (void)testFreshConfigurationReportsNoValuesAssigned {
    BranchConfiguration *config = [self updateConfiguration];
    XCTAssertFalse(config.testModeWasSet);
    XCTAssertFalse(config.networkTimeoutWasSet);
    XCTAssertFalse(config.retryCountWasSet);
    XCTAssertFalse(config.retryIntervalWasSet);
    XCTAssertFalse(config.thirdPartyAPIsWaitTimeWasSet);
    XCTAssertFalse(config.limitFacebookAttributionWasSet);
    XCTAssertFalse(config.adNetworkCalloutsDisabledWasSet);
    XCTAssertFalse(config.automaticOpenEventsWasSet);
}

- (void)testAssigningDefaultValuesMarksThemAssigned {
    BranchConfiguration *config = [self updateConfiguration];
    config.testMode = NO;
    config.networkTimeout = config.networkTimeout;
    config.retryCount = config.retryCount;
    config.retryInterval = config.retryInterval;
    config.thirdPartyAPIsWaitTime = config.thirdPartyAPIsWaitTime;
    config.limitFacebookAttribution = NO;
    config.adNetworkCalloutsDisabled = NO;
    config.automaticOpenEvents = YES;

    XCTAssertTrue(config.testModeWasSet);
    XCTAssertTrue(config.networkTimeoutWasSet);
    XCTAssertTrue(config.retryCountWasSet);
    XCTAssertTrue(config.retryIntervalWasSet);
    XCTAssertTrue(config.thirdPartyAPIsWaitTimeWasSet);
    XCTAssertTrue(config.limitFacebookAttributionWasSet);
    XCTAssertTrue(config.adNetworkCalloutsDisabledWasSet);
    XCTAssertTrue(config.automaticOpenEventsWasSet);
}

#pragma mark - Only assigned values are applied

- (void)testUpdateLeavesUnassignedValuesUnchanged {
    Branch *branch = [self initializeWith:^(BranchConfiguration *config) {
        config.networkTimeout = 10.0;
        config.retryCount = 5;
        config.thirdPartyAPIsWaitTime = 2.0;
        config.adNetworkCalloutsDisabled = YES;
        config.limitFacebookAttribution = YES;
        config.automaticOpenEvents = NO;
    }];

    BranchConfiguration *update = [self updateConfiguration];
    update.retryInterval = 2.5;
    [Branch updateConfiguration:update];

    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    XCTAssertEqualWithAccuracy(prefs.retryInterval, 2.5, 0.001);
    XCTAssertEqualWithAccuracy(prefs.timeout, 10.0, 0.001);
    XCTAssertEqual(prefs.retryCount, 5);
    XCTAssertEqualWithAccuracy(prefs.thirdPartyAPIsWaitTime, 2.0, 0.001);
    XCTAssertTrue(prefs.disableAdNetworkCallouts);
    XCTAssertTrue(prefs.limitFacebookTracking);
    XCTAssertFalse([[branch valueForKey:@"automaticOpenEvents"] boolValue]);
}

- (void)testUpdateAppliesAnAssignedDefaultValue {
    [self initializeWith:^(BranchConfiguration *config) {
        config.networkTimeout = 10.0;
        config.adNetworkCalloutsDisabled = YES;
    }];

    BranchConfiguration *update = [self updateConfiguration];
    update.networkTimeout = 5.5;
    update.adNetworkCalloutsDisabled = NO;
    [Branch updateConfiguration:update];

    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 5.5, 0.001);
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].disableAdNetworkCallouts);
}

- (void)testUpdateBeforeInitializeAppliesNothing {
    [BNCPreferenceHelper sharedInstance].timeout = 7.0;

    BranchConfiguration *update = [self updateConfiguration];
    update.networkTimeout = 20.0;
    [Branch updateConfiguration:update];

    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 7.0, 0.001);
}

#pragma mark - Invalid values are skipped

- (void)testUpdateSkipsInvalidValueAndAppliesTheRest {
    [self initializeWith:^(BranchConfiguration *config) {
        config.networkTimeout = 10.0;
        config.retryCount = 1;
    }];

    BranchConfiguration *update = [self updateConfiguration];
    update.networkTimeout = -1;
    update.retryCount = 7;
    [Branch updateConfiguration:update];

    XCTAssertEqualWithAccuracy([BNCPreferenceHelper sharedInstance].timeout, 10.0, 0.001);
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryCount, 7);
    XCTAssertTrue([self warningsContain:@"Network timeout must be a positive number"]);
}

- (void)testUpdateSkipsInvalidApiUrl {
    [self initializeWith:nil];

    BranchConfiguration *update = [self updateConfiguration];
    update.apiUrl = @"api.branch.io";
    [Branch updateConfiguration:update];

    XCTAssertNil([BNCServerAPI sharedInstance].customAPIURL);
    XCTAssertTrue([self warningsContain:@"custom apiUrl"]);
}

- (void)testInitializeStillRejectsInvalidConfiguration {
    BranchConfiguration *config = [[BranchConfiguration alloc] initWithKey:@"key_live_abc"];
    config.retryCount = -1;
    XCTAssertNil([Branch initialize:config]);
}

#pragma mark - Initialization-only fields

- (void)testUpdateWithDifferentBranchKeyWarnsAndAppliesTheRest {
    [self initializeWith:nil];

    BranchConfiguration *update = [[BranchConfiguration alloc] initWithKey:@"key_live_other"];
    update.retryCount = 9;
    [Branch updateConfiguration:update];

    XCTAssertEqualObjects([Branch branchKey], @"key_live_abc");
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryCount, 9);
    XCTAssertTrue([self warningsContain:@"branchKey is set once"]);
}

- (void)testUpdateIgnoresTestMode {
    [self initializeWith:nil];

    BranchConfiguration *update = [self updateConfiguration];
    update.testMode = YES;
    [Branch updateConfiguration:update];

    XCTAssertFalse([Branch useTestBranchKey]);
    XCTAssertTrue([self warningsContain:@"testMode is set once"]);
}

- (void)testUpdateDoesNotWarnAboutUnassignedTestMode {
    XCTAssertNotNil([Branch initialize:[BranchConfiguration debug:@"key_test_abc"]]);
    [self captureWarnings];

    [Branch updateConfiguration:[[BranchConfiguration alloc] initWithKey:@"key_test_abc"]];

    XCTAssertFalse([self warningsContain:@"testMode is set once"]);
}

- (void)testUpdateIgnoresCheckPasteboardOnInstall {
    [self initializeWith:nil];

    BranchConfiguration *update = [self updateConfiguration];
    update.checkPasteboardOnInstall = YES;
    [Branch updateConfiguration:update];

    XCTAssertFalse([BNCPasteboard sharedInstance].checkOnInstall);
    XCTAssertTrue([self warningsContain:@"checkPasteboardOnInstall is set once"]);
}

#pragma mark - Attribution level

- (void)testUpdateChangesAttributionLevel {
    [self initializeWith:^(BranchConfiguration *config) {
        config.attributionLevel = BranchAttributionLevelFull;
    }];

    BranchConfiguration *update = [self updateConfiguration];
    update.attributionLevel = BranchAttributionLevelReduced;
    [Branch updateConfiguration:update];

    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelReduced);
}

- (void)testUpdateWithUnchangedNoneLevelDoesNotClearAgain {
    [self initializeWith:^(BranchConfiguration *config) {
        config.attributionLevel = BranchAttributionLevelNone;
    }];
    [[BNCPartnerParameters shared] addFacebookParameterWithName:@"em" value:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"];

    BranchConfiguration *update = [self updateConfiguration];
    update.attributionLevel = BranchAttributionLevelNone;
    [Branch updateConfiguration:update];

    XCTAssertGreaterThan([[BNCPartnerParameters shared] parameterJson].count, 0,
                         @"Re-sending an unchanged NONE level must not clear partner parameters again");
}

#pragma mark - Open tracking state

- (void)testUpdateDoesNotResetForegroundOpenMarker {
    Branch *branch = [self initializeWith:nil];
    [branch setValue:@YES forKey:@"openSentThisForegroundPeriod"];

    BranchConfiguration *update = [self updateConfiguration];
    update.retryCount = 4;
    [Branch updateConfiguration:update];

    XCTAssertTrue([[branch valueForKey:@"openSentThisForegroundPeriod"] boolValue],
                  @"An update must not let a second automatic open go out in the same foreground period");
}

@end

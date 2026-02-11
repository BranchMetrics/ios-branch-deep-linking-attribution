//
//  BranchClassTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 9/25/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConstants.h"
#import "BNCPasteboard.h"
#import "BNCAppGroupsData.h"
#import "BNCPartnerParameters.h"

@interface BNCPreferenceHelper(Test)
// Expose internal private method to clear EEA data
- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value;
@end

@interface BranchClassTests : XCTestCase
@property (nonatomic, strong) Branch *branch;
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *prefHelper;
@end

@implementation BranchClassTests

- (void)setUp {
    [super setUp];
    self.branch = [Branch getInstance];
    self.prefHelper = [BNCPreferenceHelper sharedInstance];
}

- (void)tearDown {
    self.branch = nil;
    [super tearDown];
}

- (void)testIsUserIdentified {
    [self.branch setIdentity: @"userId"];
    XCTAssertTrue([self.branch isUserIdentified], @"User should be identified");
}

- (void)testDisableAdNetworkCallouts {
    [self.branch disableAdNetworkCallouts:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].disableAdNetworkCallouts, @"AdNetwork callouts should be disabled");
}

- (void)testSetNetworkTimeout {
    [self.branch setNetworkTimeout:5.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].timeout, 5.0, @"Network timeout should be set to 5.0");
}

//- (void)testSetMaxRetries {
//    [self.branch setMaxRetries:3];
//    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryCount, 3, @"Max retries should be set to 3");
//}

- (void)testSetRetryInterval {
    [self.branch setRetryInterval:2.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].retryInterval, 2.0, @"Retry interval should be set to 2.0");
}

- (void)testSetRequestMetadataKeyAndValue {
    [self.branch setRequestMetadataKey:@"key" value:@"value"];
    NSDictionary *metadata = [BNCPreferenceHelper sharedInstance].requestMetadataDictionary;
    XCTAssertEqualObjects(metadata[@"key"], @"value");
}

- (void)testSetTrackingDisabled {
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].trackingDisabled);

    [Branch setTrackingDisabled:YES];
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].trackingDisabled);

    [Branch setTrackingDisabled:NO];
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].trackingDisabled);
}

- (void)testCheckPasteboardOnInstall {
    [self.branch checkPasteboardOnInstall];
    BOOL checkOnInstall = [BNCPasteboard sharedInstance].checkOnInstall;
    XCTAssertTrue(checkOnInstall);
}

- (void)testWillShowPasteboardToast_ShouldReturnYes {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = nil;
    [BNCPasteboard sharedInstance].checkOnInstall = YES;
    UIPasteboard.generalPasteboard.URL = [NSURL URLWithString:@"https://example.com"];

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertTrue(result);
}

- (void)testWillShowPasteboardToast_ShouldReturnNo {
    [BNCPreferenceHelper sharedInstance].randomizedBundleToken = @"some_token";
    [BNCPasteboard sharedInstance].checkOnInstall = NO;

    BOOL result = [self.branch willShowPasteboardToast];
    XCTAssertFalse(result);
}

- (void)testSetAppClipAppGroup {
    NSString *testAppGroup = @"testAppGroup";
    [self.branch setAppClipAppGroup:testAppGroup];
    NSString *actualAppGroup = [BNCAppGroupsData shared].appGroup;

    XCTAssertEqualObjects(testAppGroup, actualAppGroup);
}

- (void)testClearPartnerParameters {
    [self.branch addFacebookPartnerParameterWithName:@"ph" value:@"123456789"];
    [[BNCPartnerParameters shared] clearAllParameters];
       
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson];
    XCTAssertEqual([result count], 0, @"Parameters should be empty after calling clearAllParameters");
}

- (void)testAddFacebookParameterWithName_Value {
    [self.branch addFacebookPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];
    
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"fb"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Facebook");
}

- (void)testAddSnapParameterWithName_Value {
    [self.branch addSnapPartnerParameterWithName:@"name" value:@"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346"];
    
    NSDictionary *result = [[BNCPartnerParameters shared] parameterJson][@"snap"];
    XCTAssertEqualObjects(result[@"name"], @"3D4F2BF07DC1BE38B20C653EE9A7E446158F84E525BBB98FEDF721CB5A40A346", @"Should add parameter for Snap");
}

- (void)testGetFirstReferringBranchUniversalObject_ClickedBranchLink {
    NSString *installParamsString = @"{\"$canonical_identifier\":\"content/12345\",\"$creation_timestamp\":1694557342247,\"$desktop_url\":\"https://example.com/home\",\"$og_description\":\"My Content Description\",\"$og_title\":\"My Content Title\",\"+click_timestamp\":1695749249,\"+clicked_branch_link\":1,\"+is_first_session\":1,\"+match_guaranteed\":1,\"custom\":\"data\",\"key1\":\"value1\",\"~campaign\":\"content 123 launch\",\"~channel\":\"facebook\",\"~creation_source\":3,\"~feature\":\"sharing\",\"~id\":1230269548213984984,\"~referring_link\":\"https://bnctestbed.app.link/uSPHktjO2Cb\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];

    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];\
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Content Title");
    XCTAssertEqualObjects(result.canonicalIdentifier, @"content/12345");
}

- (void)testGetFirstReferringBranchUniversalObject_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams: installParamsString];
        
    BranchUniversalObject *result = [self.branch getFirstReferringBranchUniversalObject];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringBranchLinkProperties_ClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":1,\"~campaign\":\"content 123 launch\"}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"content 123 launch");
}

- (void)testGetFirstReferringBranchLinkProperties_NotClickedBranchLink {
    NSString *installParamsString = @"{\"+clicked_branch_link\":false,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    BranchLinkProperties *result = [self.branch getFirstReferringBranchLinkProperties];
    XCTAssertNil(result);
}

- (void)testGetFirstReferringParams {
    NSString *installParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":true}";
    [[BNCPreferenceHelper sharedInstance] setInstallParams:installParamsString];

    NSDictionary *result = [self.branch getFirstReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

- (void)testGetLatestReferringParams {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    NSDictionary *result = [self.branch getLatestReferringParams];
    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
}

//- (void)testGetLatestReferringParamsSynchronous {
//    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false}";
//    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];
//
//    NSDictionary *result = [self.branch getLatestReferringParamsSynchronous];
//    XCTAssertEqualObjects([result objectForKey:@"+clicked_branch_link"], @true);
//}

- (void)testGetLatestReferringBranchUniversalObject_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":1,\"+is_first_session\":false,\"$og_title\":\"My Latest Content\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchUniversalObject *result = [self.branch getLatestReferringBranchUniversalObject];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.title, @"My Latest Content");
}

- (void)testGetLatestReferringBranchLinkProperties_ClickedBranchLink {
    NSString *sessionParamsString = @"{\"+clicked_branch_link\":true,\"+is_first_session\":false,\"~campaign\":\"latest campaign\"}";
    [[BNCPreferenceHelper sharedInstance] setSessionParams:sessionParamsString];

    BranchLinkProperties *result = [self.branch getLatestReferringBranchLinkProperties];
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result.campaign, @"latest campaign");
}

- (void)testGetShortURL {      
    NSString *shortURL = [self.branch getShortURL];
    XCTAssertNotNil(shortURL, @"URL should not be nil");
    XCTAssertTrue([shortURL hasPrefix:@"https://"], @"URL should start with 'https://'");
}

- (void)testGetLongURLWithParamsAndChannelAndTagsAndFeatureAndStageAndAlias {
    NSDictionary *params = @{@"key": @"value"};
    NSString *channel = @"channel1";
    NSArray *tags = @[@"tag1", @"tag2"];
    NSString *feature = @"feature1";
    NSString *stage = @"stage1";
    NSString *alias = @"alias1";
    
    NSString *generatedURL = [self.branch getLongURLWithParams:params andChannel:channel andTags:tags andFeature:feature andStage:stage andAlias:alias];
    NSString *expectedURL = @"https://bnc.lt/a/key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB?tags=tag1&tags=tag2&alias=alias1&feature=feature1&stage=stage1&source=ios&data=eyJrZXkiOiJ2YWx1ZSJ9";
    
    XCTAssertEqualObjects(generatedURL, expectedURL, @"URL should match the expected format");
}

- (void)testSetDMAParamsForEEA {
    XCTAssertFalse([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);
    
    [Branch setDMAParamsForEEA:FALSE AdPersonalizationConsent:TRUE AdUserDataUsageConsent:TRUE];
    XCTAssertTrue([[BNCPreferenceHelper sharedInstance] eeaRegionInitialized]);
    XCTAssertFalse([BNCPreferenceHelper sharedInstance].eeaRegion);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adPersonalizationConsent);
    XCTAssertTrue([BNCPreferenceHelper sharedInstance].adUserDataUsageConsent);

    // Manually clear values after testing
    // By design, this API is meant to be set once and always set. However, in a test scenario it needs to be cleared.
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_eea" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_personalization" value:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_dma_ad_user_data" value:nil];
}

- (void)testSetConsumerProtectionAttributionLevel {
    // Set to Reduced and check
    Branch *branch = [Branch getInstance];
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelReduced];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelReduced);
    
    // Set to Minimal and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelMinimal];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelMinimal);
    
    // Set to None and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelNone];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelNone);
    
    // Set to Full and check
    [branch setConsumerProtectionAttributionLevel:BranchAttributionLevelFull];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].attributionLevel, BranchAttributionLevelFull);
    
}

- (void)testBranchSetSDKWaitTimeForThirdPartyAPIs {
    // Test Branch instance method for setting timeout
    NSTimeInterval testTimeout = 2.0;
    [Branch setSDKWaitTimeForThirdPartyAPIs:testTimeout];
    
    // Verify it was set in the preference helper
    XCTAssertEqual(self.prefHelper.thirdPartyAPIsWaitTime, testTimeout,
                   @"Branch setSDKWaitTimeForThirdPartyAPIs should update preference helper");
}

- (void)testBranchSetSDKWaitTimeForThirdPartyAPIsMultipleValues {
    // Test setting multiple different values
    NSArray *testValues = @[@0.5, @1.0, @1.5, @3.0, @5.0];
    
    for (NSNumber *timeoutValue in testValues) {
        NSTimeInterval timeout = [timeoutValue doubleValue];
        [Branch setSDKWaitTimeForThirdPartyAPIs:timeout];
        
        XCTAssertEqual(self.prefHelper.thirdPartyAPIsWaitTime, timeout,
                       @"Branch setSDKWaitTimeForThirdPartyAPIs should handle value %.1f", timeout);
    }
}

- (void)testTimeoutIntegrationWithPreferenceHelper {
    // Test that Branch and PreferenceHelper work together correctly
    NSTimeInterval branchTimeout = 1.8;
    NSTimeInterval directTimeout = 2.3;
    
    // Set via Branch
    [Branch setSDKWaitTimeForThirdPartyAPIs:branchTimeout];
    XCTAssertEqual(self.prefHelper.thirdPartyAPIsWaitTime, branchTimeout,
                   @"Wait Time set via Branch should be readable from PreferenceHelper");
    
    // Set directly on PreferenceHelper
    self.prefHelper.thirdPartyAPIsWaitTime = directTimeout;
    XCTAssertEqual(self.prefHelper.thirdPartyAPIsWaitTime, directTimeout,
                   @"Wait time set directly should be readable via Branch");
}

- (void)testTimeoutValueConsistency {
    // Test that the same instance maintains consistent values
    NSTimeInterval testTimeout = 1.25;
    
    [Branch setSDKWaitTimeForThirdPartyAPIs:testTimeout];
    
    // Read multiple times to ensure consistency
    for (int i = 0; i < 5; i++) {
        XCTAssertEqual(self.prefHelper.thirdPartyAPIsWaitTime, testTimeout,
                       @"Timeout value should remain consistent across multiple reads");
    }
}

- (void)testBranchSetSDKWaitTimeForThirdPartyAPIsInvalidLowValues {

    NSArray *invalidLowValues = @[@0.0, @-1.0, @-0.5];
    NSTimeInterval originalTimeout = [BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime;
    
    for (NSNumber *timeoutValue in invalidLowValues) {
        NSTimeInterval timeout = [timeoutValue doubleValue];
        [Branch setSDKWaitTimeForThirdPartyAPIs:timeout];
        XCTAssertEqual([BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime, originalTimeout,
                       @"Branch setSDKWaitTimeForThirdPartyAPIs should reject invalid low value %.3f", timeout);
    }
}

- (void)testBranchsetSDKWaitTimeForThirdPartyAPIsInvalidHighValues {

    NSArray *invalidHighValues = @[@10.1, @15.0, @30.0, @60.0];
    NSTimeInterval originalTimeout = [BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime;
    
    for (NSNumber *timeoutValue in invalidHighValues) {
        NSTimeInterval timeout = [timeoutValue doubleValue];
        [Branch setSDKWaitTimeForThirdPartyAPIs:timeout];
        XCTAssertEqual([BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime, originalTimeout,
                       @"Branch setSDKWaitTimeForThirdPartyAPIs should reject invalid high value %.3f", timeout);
    }
}

- (void)testBranchSetSDKWaitTimeForThirdPartyAPIsBoundaryValues {
    
    // Test exactly 10.0 (should be valid)
    [Branch setSDKWaitTimeForThirdPartyAPIs:10.0];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime, 10.0,
                   @"Timeout of exactly 10.0 seconds should be valid");
    
    // Test just over 10.0 (should be invalid)
    [Branch setSDKWaitTimeForThirdPartyAPIs:10.0001];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime, 10.0,
                   @"Timeout of 10.0001 seconds should be rejected");
    
    // Test very small positive value (should be valid)
    [Branch setSDKWaitTimeForThirdPartyAPIs:0.0001];
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].thirdPartyAPIsWaitTime, 0.0001,
                   @"Very small positive timeout should be valid");
}

- (void)testSetAnonID {
    NSString *expectedAnonID = @"static-test-anon-id-12345";
    
    [Branch setAnonID:expectedAnonID];
    
    NSString *actualAnonID = [BNCPreferenceHelper sharedInstance].anonID;
    XCTAssertEqualObjects(actualAnonID, expectedAnonID, @"setAnonID should set valid string");
}

- (void)testSetAnonID_UpdateExistingValue {
    NSString *initialAnonID = @"initial-anon-id";
    NSString *updatedAnonID = @"updated-anon-id";
    
    [Branch setAnonID:initialAnonID];
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, initialAnonID);
    
    [Branch setAnonID:updatedAnonID];
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, updatedAnonID);
}

- (void)testSetAnonID_NilValue {
    NSString *initialAnonID = @"initial-anon-id";

    [Branch setAnonID:initialAnonID];
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, initialAnonID);
    
    [Branch setAnonID:nil];
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, initialAnonID);
}

- (void)testSetAnonID_EmptyString {
    NSString *emptyAnonID = @"";
    
    [Branch setAnonID:emptyAnonID];
    
    NSString *actualAnonID = [BNCPreferenceHelper sharedInstance].anonID;
    XCTAssertEqualObjects(actualAnonID, emptyAnonID, @"Static setAnonID should accept empty string");
}

- (void)testSetAnonID_NonStringObject {
    NSString *initialAnonID = @"initial-anon-id";
    
    [Branch setAnonID:initialAnonID];
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, initialAnonID);
    
    // Try to set with a non-string object (NSNumber)
    NSNumber *nonStringValue = @123;
    [Branch setAnonID:(NSString *)nonStringValue];
    
    XCTAssertEqualObjects([BNCPreferenceHelper sharedInstance].anonID, initialAnonID);
}

- (void)testSetAnonID_LongString {
    NSString *longAnonID = @"very-long-anon-id-with-many-characters-to-test-string-handling-1234567890-abcdefghijklmnopqrstuvwxyz";
    
    [Branch setAnonID:longAnonID];
    
    NSString *actualAnonID = [BNCPreferenceHelper sharedInstance].anonID;
    XCTAssertEqualObjects(actualAnonID, longAnonID, @"setAnonID should handle long strings");
}

- (void)testSetAnonID_SpecialCharacters {
    NSString *specialCharAnonID = @"static-anon-id-with-special-chars-!@#$%^&*()_+-=[]{}|;:,.<>?";
    
    [Branch setAnonID:specialCharAnonID];
    
    NSString *actualAnonID = [BNCPreferenceHelper sharedInstance].anonID;
    XCTAssertEqualObjects(actualAnonID, specialCharAnonID, @"setAnonID should handle special characters");
}

- (void)testSetAnonID_ThreadSafety {
    NSString *anonID1 = @"thread-test-anon-id-1";
    NSString *anonID2 = @"thread-test-anon-id-2";
    
    // Test that the method is thread-safe by calling it from different queues
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Branch setAnonID:anonID1];
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [Branch setAnonID:anonID2];
        dispatch_group_leave(group);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // Verify that one of the values was set (we can't predict which due to concurrency)
    NSString *finalAnonID = [BNCPreferenceHelper sharedInstance].anonID;
    XCTAssertTrue([finalAnonID isEqualToString:anonID1] || [finalAnonID isEqualToString:anonID2],
                  @"One of the anonID values should be set");
}

@end

//
//  BNCDeviceInfoTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 11/21/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCDeviceInfo.h"
#import "BNCUserAgentCollector.h"
#import "BNCPreferenceHelper.h"

@interface BNCPreferenceHelper(LegacyAnonIDTest)
- (void)writeObjectToDefaults:(NSString *)key value:(NSObject *)value;
@end

// Stand-in for the Meta SDK class. The test target does not link FBSDK, so BNCDeviceInfo's reflection finds this class.
@interface FBSDKBasicUtility : NSObject
+ (void)bnc_setTestAnonymousID:(NSString *)anonymousID;
+ (NSInteger)bnc_callCount;
+ (NSString *)anonymousID;
@end

static NSString *bnc_testFBAnonymousID = nil;
static NSInteger bnc_testFBCallCount = 0;

@implementation FBSDKBasicUtility
+ (void)bnc_setTestAnonymousID:(NSString *)anonymousID {
    bnc_testFBAnonymousID = [anonymousID copy];
    bnc_testFBCallCount = 0;
}
+ (NSInteger)bnc_callCount {
    return bnc_testFBCallCount;
}
+ (NSString *)anonymousID {
    bnc_testFBCallCount++;
    return bnc_testFBAnonymousID;
}
@end

@interface BNCDeviceInfoTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCDeviceInfo *deviceInfo;
@end

@implementation BNCDeviceInfoTests

- (void)setUp {
    [self workaroundUserAgentLazyLoad];
    self.deviceInfo = [BNCDeviceInfo new];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_anon_id" value:nil];
    [BNCPreferenceHelper sharedInstance].fbSdkAnonID = nil;
}

// user agent needs to be loaded
- (void)workaroundUserAgentLazyLoad {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"setup"];
    [[BNCUserAgentCollector instance] loadUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) { }];
}

- (void)tearDown {
    [FBSDKBasicUtility bnc_setTestAnonymousID:nil];
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_anon_id" value:nil];
    [BNCPreferenceHelper sharedInstance].fbSdkAnonID = nil;
}

- (void)testHardwareId {
    XCTAssertNotNil(self.deviceInfo.hardwareId);
    
    // verify hardwareId is a valid UUID
    NSUUID *hardwareId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.hardwareId];
    XCTAssertNotNil(hardwareId);
}

- (void)testHardwareIdType {
    // without ATT, this is the IDFV. Branch servers expect it as vendor_id
    XCTAssert([self.deviceInfo.hardwareIdType isEqualToString:@"vendor_id"]);
}

- (void)testIsRealHardwareId {
    XCTAssert(self.deviceInfo.isRealHardwareId);
}

- (void)testAdvertiserId {
    // the testbed does not show the ATT prompt.
    XCTAssertNil(self.deviceInfo.advertiserId);
}

- (void)testVendorId {
    XCTAssertNotNil(self.deviceInfo.vendorId);
    
    // verify vendorId is a valid UUID
    NSUUID *vendorId = [[NSUUID alloc] initWithUUIDString:self.deviceInfo.vendorId];
    XCTAssertNotNil(vendorId);
}

- (void)testOptedInStatus {
    // the testbed does not show the ATT prompt.
    XCTAssert([self.deviceInfo.optedInStatus isEqualToString:@"not_determined"]);
}

- (void)testIsFirstOptIn {
    // the testbed does not show the ATT prompt.
    XCTAssert(self.deviceInfo.isFirstOptIn == NO);
}

- (void)testLocalIPAddress {
    NSString *address = [self.deviceInfo localIPAddress];
    XCTAssertNotNil(address);
    XCTAssert(address.length > 7);
}

- (void)testConnectionType {
    // simulator is on wifi
    XCTAssert([[self.deviceInfo connectionType] isEqualToString:@"wifi"]);
}

- (void)testBrandName {
    XCTAssert([@"Apple" isEqualToString:self.deviceInfo.brandName]);
}

- (void)testModelName_Simulator {
    // intel processor
    bool x86_64 = [@"x86_64" isEqualToString:self.deviceInfo.modelName];
    
    // apple processor
    bool arm64 = [@"arm64" isEqualToString:self.deviceInfo.modelName];
    
    XCTAssert(x86_64 || arm64);
}

- (void)testOSName {
    XCTAssertNotNil(self.deviceInfo.osName);
    XCTAssert([@"iOS" isEqualToString:self.deviceInfo.osName]);
}

- (void)testOSVersion {
    XCTAssertNotNil(self.deviceInfo.osVersion);
    XCTAssert([self.deviceInfo.osVersion isEqualToString:[UIDevice currentDevice].systemVersion]);
}

- (void)testOSBuildVersion {
    XCTAssertNotNil(self.deviceInfo.osBuildVersion);
}

- (void)testEnvironment {
    // currently not running unit tests on extensions
    XCTAssert([@"FULL_APP" isEqualToString:self.deviceInfo.environment]);
}

- (void)testCpuType_Simulator {
    // intel processors
    bool x86 = [@"7" isEqualToString:self.deviceInfo.cpuType];
    
    // apple processors
    bool arm = [@"16777228" isEqualToString:self.deviceInfo.cpuType];
    
    XCTAssert(x86 || arm);
}

- (void)testScreenWidth {
    XCTAssert(self.deviceInfo.screenWidth.intValue >= 320);
}

- (void)testScreenHeight {
    XCTAssert(self.deviceInfo.screenHeight.intValue >= 320);
}

- (void)testScreenScale {
    XCTAssert(self.deviceInfo.screenScale.intValue >= 1);
}

- (void)testLocale {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale isEqualToString:self.deviceInfo.locale]);
}

- (void)testCountry {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:self.deviceInfo.country]);
}

- (void)testLanguage {
    NSString *locale = [NSLocale currentLocale].localeIdentifier;
    XCTAssertNotNil(locale);
    XCTAssert([locale containsString:self.deviceInfo.language]);
}

- (void)testUserAgentString {
    XCTAssert([self.deviceInfo.userAgentString containsString:@"AppleWebKit"]);
}

- (void)testApplicationVersion_TestBed {
    XCTAssert([@"1.1" isEqualToString:self.deviceInfo.applicationVersion]);
}

- (void)testRegisterPluginNameVersion {
    XCTAssertNil(self.deviceInfo.pluginName);
    XCTAssertNil(self.deviceInfo.pluginVersion);

    NSString *expectedName = @"react native";
    NSString *expectedVersion = @"1.0.0";
    
    [self.deviceInfo registerPluginName:expectedName version:expectedVersion];
    
    XCTAssert([expectedName isEqualToString:self.deviceInfo.pluginName]);
    XCTAssert([expectedVersion isEqualToString:self.deviceInfo.pluginVersion]);
}

- (void)testFbSdkAnonIdValid {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
}

- (void)testFbSdkAnonIdNil {
    [FBSDKBasicUtility bnc_setTestAnonymousID:nil];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
}

- (void)testFbSdkAnonIdEmpty {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@""];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
}

- (void)testFbSdkAnonIdWithoutXZPrefixIsDiscarded {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"AB1234-ABCD"];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);

    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ"];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);

    [FBSDKBasicUtility bnc_setTestAnonymousID:@"xz1234"];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
}

- (void)testFbSdkAnonIdValidValueIsCached {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqual(1, [FBSDKBasicUtility bnc_callCount]);
}

- (void)testFbSdkAnonIdEmptyValueIsNotCached {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@""];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
    XCTAssertEqual(2, [FBSDKBasicUtility bnc_callCount]);

    // Re-read picks up the value once Meta returns one
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ5678-EFGH"];
    XCTAssertEqualObjects(@"XZ5678-EFGH", [self.deviceInfo fbSdkAnonId]);
}

- (void)testFbSdkAnonIdValidValueIsSavedToPreferences {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqualObjects(@"XZ1234-ABCD", [BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

- (void)testFbSdkAnonIdInvalidValueIsNotSavedToPreferences {
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"AB1234-ABCD"];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

- (void)testFbSdkAnonIdSavedValueIsUsedBeforeMetaSDK {
    [BNCPreferenceHelper sharedInstance].fbSdkAnonID = @"XZ9999-SAVED";
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ9999-SAVED", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqual(0, [FBSDKBasicUtility bnc_callCount], @"Meta SDK should not be called when a value is saved");
}

- (void)testFbSdkAnonIdInvalidSavedValueIsReplacedByMetaValue {
    [BNCPreferenceHelper sharedInstance].fbSdkAnonID = @"not-a-meta-id";
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqualObjects(@"XZ1234-ABCD", [BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

// Upgrade from an older Branch SDK that saved its own GUID in bnc_anon_id.
- (void)testUpgradeLegacyGuidIsNeverUsed {
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_anon_id" value:[NSUUID UUID].UUIDString];
    [FBSDKBasicUtility bnc_setTestAnonymousID:nil];
    XCTAssertNil([self.deviceInfo fbSdkAnonId]);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

- (void)testUpgradeLegacyGuidIsIgnoredWhenMetaValueIsAvailable {
    [[BNCPreferenceHelper sharedInstance] writeObjectToDefaults:@"bnc_anon_id" value:[NSUUID UUID].UUIDString];
    [FBSDKBasicUtility bnc_setTestAnonymousID:@"XZ1234-ABCD"];
    XCTAssertEqualObjects(@"XZ1234-ABCD", [self.deviceInfo fbSdkAnonId]);
    XCTAssertEqualObjects(@"XZ1234-ABCD", [BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

@end

//
//  BranchConfigurationControllerTests.m
//  Branch-SDK-Tests
//
//  Created by Nidhi Dixit on 6/12/25.
//


#import <XCTest/XCTest.h>
#import "BranchConfigurationController.h"
#import "BranchConstants.h"
#import "BNCRequestFactory.h"
#import "BNCEncodingUtils.h"

@interface BranchConfigurationControllerTests : XCTestCase
@end

@implementation BranchConfigurationControllerTests

- (void)testSingletonInstance {
    
    BranchConfigurationController *instance1 = [BranchConfigurationController sharedInstance];
    XCTAssertNotNil(instance1);

    BranchConfigurationController *instance2 = [BranchConfigurationController sharedInstance];
    XCTAssertEqual(instance1, instance2);
}

- (void)testPropertySettersAndGetters {
    BranchConfigurationController *configController = [BranchConfigurationController sharedInstance];
    
    NSString *keySource = BRANCH_KEY_SOURCE_GET_INSTANCE_API;
    configController.branchKeySource = keySource;
    XCTAssertTrue([configController.branchKeySource isEqualToString:keySource]);
    
    configController.deferInitForPluginRuntime = YES;
    XCTAssertTrue(configController.deferInitForPluginRuntime);
    configController.deferInitForPluginRuntime = NO;
    XCTAssertFalse(configController.deferInitForPluginRuntime);
    
    configController.checkPasteboardOnInstall = YES;
    XCTAssertTrue(configController.checkPasteboardOnInstall);
    configController.checkPasteboardOnInstall = NO;
    XCTAssertFalse(configController.checkPasteboardOnInstall);
}

- (void)testGetConfiguration {
    BranchConfigurationController *configController = [BranchConfigurationController sharedInstance];
    configController.branchKeySource = BRANCH_KEY_SOURCE_INFO_PLIST;
    configController.deferInitForPluginRuntime = YES;
    configController.checkPasteboardOnInstall = YES;

    NSDictionary *configDict = [configController getConfiguration];
    XCTAssertNotNil(configDict);

    XCTAssertTrue([configDict[BRANCH_REQUEST_KEY_BRANCH_KEY_SOURCE] isEqualToString:BRANCH_KEY_SOURCE_INFO_PLIST]);
    XCTAssertEqualObjects(configDict[BRANCH_REQUEST_KEY_DEFER_INIT_FOR_PLUGIN_RUNTIME], @(YES));
    XCTAssertEqualObjects(configDict[BRANCH_REQUEST_KEY_CHECK_PASTEBOARD_ON_INSTALL], @(YES));
    
    NSDictionary *frameworks = configDict[BRANCH_REQUEST_KEY_LINKED_FRAMEORKS];
    XCTAssertNotNil(frameworks);
    
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_SUPPORT], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_ATT_TRACKING_MANAGER], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_FIREBASE_CRASHLYTICS], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_SAFARI_SERVICES], @(NO));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_APP_ADS_ONDEVICE_CONVERSION], @(NO));
    
}

- (void)testInstallRequestParams {
    BranchConfigurationController *configController = [BranchConfigurationController sharedInstance];
    configController.branchKeySource = BRANCH_KEY_SOURCE_INFO_PLIST;
    configController.deferInitForPluginRuntime = YES;
    configController.checkPasteboardOnInstall = YES;

    NSString* requestUUID = [[NSUUID UUID ] UUIDString];
    NSNumber* requestCreationTimeStamp = BNCWireFormatFromDate([NSDate date]);
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:requestUUID TimeStamp:requestCreationTimeStamp];
    NSDictionary *installDict = [factory dataForInstallWithURLString:@"https://branch.io"];
    
    NSDictionary *configDict = installDict[BRANCH_REQUEST_KEY_OPERATIONAL_METRICS];
    XCTAssertNotNil(configDict);

    XCTAssertTrue([configDict[BRANCH_REQUEST_KEY_BRANCH_KEY_SOURCE] isEqualToString:BRANCH_KEY_SOURCE_INFO_PLIST]);
    XCTAssertEqualObjects(configDict[BRANCH_REQUEST_KEY_DEFER_INIT_FOR_PLUGIN_RUNTIME], @(YES));
    XCTAssertEqualObjects(configDict[BRANCH_REQUEST_KEY_CHECK_PASTEBOARD_ON_INSTALL], @(YES));
    
    NSDictionary *frameworks = configDict[BRANCH_REQUEST_KEY_LINKED_FRAMEORKS];
    XCTAssertNotNil(frameworks);
    
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_SUPPORT], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_ATT_TRACKING_MANAGER], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_FIREBASE_CRASHLYTICS], @(YES));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_SAFARI_SERVICES], @(NO));
    XCTAssertEqualObjects(frameworks[FRAMEWORK_AD_APP_ADS_ONDEVICE_CONVERSION], @(NO));
    
}

@end

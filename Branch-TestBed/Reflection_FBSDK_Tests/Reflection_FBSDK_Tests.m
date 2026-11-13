//
//  Reflection_FBSDK_Tests.m
//  Reflection_FBSDK_Tests
//
//  Integration tests for reading the Meta (FBSDK) anon_id via reflection.
//  This target links the real Meta SDK (FacebookBasics SPM product -> FBSDKCoreKit_Basics),
//  unlike Branch-SDK-Tests, which uses a stand-in FBSDKBasicUtility class.
//
//  Copyright © 2026 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
@import FBSDKCoreKit_Basics;

#import "Branch.h"
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCRequestFactory.h"
#import "BranchConstants.h"

static NSString * const BNCMetaAnonIDFileName = @"com-facebook-sdk-PersistedAnonymousID.json";

@interface Reflection_FBSDK_Tests : XCTestCase
@property (nonatomic, copy) NSString *savedAttributionLevel;
@end

@implementation Reflection_FBSDK_Tests

- (void)setUp {
    // anon_id is omitted at attribution level None, so make sure the level allows it.
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    self.savedAttributionLevel = preferenceHelper.attributionLevel;
    preferenceHelper.attributionLevel = BranchAttributionLevelFull;
}

- (void)tearDown {
    [BNCPreferenceHelper sharedInstance].attributionLevel = self.savedAttributionLevel ?: BranchAttributionLevelFull;
}

// Value as Meta's SDK reports it, called directly (compile-time linked), not via Branch's reflection.
- (NSString *)metaAnonymousID {
    return [FBSDKBasicUtility anonymousID];
}

// Value as Meta persisted it on disk: <Library>/com-facebook-sdk-PersistedAnonymousID.json, key "anon_id".
- (NSString *)metaPersistedAnonymousID {
    NSString *library = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    NSData *data = [NSData dataWithContentsOfFile:[library stringByAppendingPathComponent:BNCMetaAnonIDFileName]];
    if (!data) {
        return nil;
    }
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [json isKindOfClass:[NSDictionary class]] ? json[@"anon_id"] : nil;
}

- (void)testMetaSDKIsLinked {
    Class cls = NSClassFromString(@"FBSDKBasicUtility");
    XCTAssertNotNil(cls, @"FBSDKBasicUtility should be present when FacebookBasics is linked");
    XCTAssertTrue([cls respondsToSelector:NSSelectorFromString(@"anonymousID")]);
}

- (void)testFbSdkAnonIdIsLoadedViaReflection {
    NSString *anonID = [[BNCDeviceInfo getInstance] fbSdkAnonId];

    XCTAssertNotNil(anonID, @"Branch should read the Meta anon_id when the Meta SDK is present");
    XCTAssertTrue([anonID hasPrefix:@"XZ"], @"Meta anon_id must start with XZ, got %@", anonID);
    // "XZ" + UUID string
    XCTAssertNotNil([[NSUUID alloc] initWithUUIDString:[anonID substringFromIndex:2]], @"Expected XZ + UUID, got %@", anonID);
}

- (void)testFbSdkAnonIdMatchesMetaSDK {
    NSString *branchValue = [[BNCDeviceInfo getInstance] fbSdkAnonId];
    XCTAssertEqualObjects(branchValue, [self metaAnonymousID]);
}

- (void)testFbSdkAnonIdMatchesMetaPersistedFile {
    NSString *branchValue = [[BNCDeviceInfo getInstance] fbSdkAnonId];
    XCTAssertNotNil(branchValue);
    // anonymousID creates and persists the file if needed, so it must exist after the read above.
    XCTAssertEqualObjects(branchValue, [self metaPersistedAnonymousID]);
}

- (void)testFbSdkAnonIdIsSavedToPreferences {
    NSString *branchValue = [[BNCDeviceInfo getInstance] fbSdkAnonId];
    XCTAssertNotNil(branchValue);
    XCTAssertEqualObjects(branchValue, [BNCPreferenceHelper sharedInstance].fbSdkAnonID);
}

- (void)testFbSdkAnonIdIsStableAcrossReads {
    NSString *first = [[BNCDeviceInfo getInstance] fbSdkAnonId];
    NSString *second = [[BNCDeviceInfo getInstance] fbSdkAnonId];
    XCTAssertNotNil(first);
    XCTAssertEqualObjects(first, second);
}

- (void)testAnonIdSentOnInstallAndOpen {
    NSString *expected = [self metaAnonymousID];
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:[NSUUID UUID].UUIDString TimeStamp:@(1)];

    NSDictionary *installJSON = [factory dataForInstallWithURLString:@"https://branch.io"];
    XCTAssertEqualObjects(expected, installJSON[BRANCH_REQUEST_KEY_ANON_ID]);

    NSDictionary *openJSON = [factory dataForOpenWithURLString:@"https://branch.io"];
    XCTAssertEqualObjects(expected, openJSON[BRANCH_REQUEST_KEY_ANON_ID]);
}

- (void)testAnonIdSentOnEvent {
    NSString *expected = [self metaAnonymousID];
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:[NSUUID UUID].UUIDString TimeStamp:@(1)];

    NSDictionary *eventJSON = [factory dataForEventWithEventDictionary:[NSMutableDictionary new]];
    XCTAssertEqualObjects(expected, eventJSON[@"user_data"][BRANCH_REQUEST_KEY_ANON_ID]);
}

- (void)testDeprecatedSetAnonIDDoesNotOverrideMetaValue {
    NSString *expected = [self metaAnonymousID];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [Branch setAnonID:@"custom-anon-id"];
#pragma clang diagnostic pop

    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:@"key_abcd" UUID:[NSUUID UUID].UUIDString TimeStamp:@(1)];
    NSDictionary *installJSON = [factory dataForInstallWithURLString:@"https://branch.io"];
    XCTAssertEqualObjects(expected, installJSON[BRANCH_REQUEST_KEY_ANON_ID]);
}

@end

//
//  BNCPreferenceHelperTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/2/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "Branch.h"
#import "BranchPluginSupport.h"
#import "BNCConfig.h"

@interface BNCPreferenceHelper()

// expose private methods for testing
- (NSMutableDictionary *)deserializePrefDictFromData:(NSData *)data;
- (NSData *)serializePrefDict:(NSMutableDictionary *)dict;

@end

@interface BNCPreferenceHelperTests : XCTestCase
@property (nonatomic, strong, readwrite) BNCPreferenceHelper *prefHelper;
@end

@implementation BNCPreferenceHelperTests

- (void)setUp {
    self.prefHelper = [BNCPreferenceHelper new];
}

- (void)tearDown {

}

- (void)testPreferenceDefaults {
    XCTAssertEqual(self.prefHelper.timeout, 5.5);
    XCTAssertEqual(self.prefHelper.retryInterval, 0);
    XCTAssertEqual(self.prefHelper.retryCount, 3);
    XCTAssertFalse(self.prefHelper.disableAdNetworkCallouts);
}

- (void)testPreferenceSets {
    self.prefHelper.retryCount = NSIntegerMax;
    self.prefHelper.retryInterval = NSIntegerMax;
    self.prefHelper.timeout = NSIntegerMax;
    
    XCTAssertEqual(self.prefHelper.retryCount, NSIntegerMax);
    XCTAssertEqual(self.prefHelper.retryInterval, NSIntegerMax);
    XCTAssertEqual(self.prefHelper.timeout, NSIntegerMax);
}

/*
 // This test is not reliable when run concurrently with other tests that set the patterListURL
- (void)testURLFilter {
    XCTAssertTrue([@"https://cdn.branch.io" isEqualToString:self.prefHelper.patternListURL]);
    
    NSString *customURL = @"https://banned.branch.io";
    self.prefHelper.patternListURL = customURL;
    XCTAssertTrue([customURL isEqualToString:self.prefHelper.patternListURL]);
}
 */

- (void)testSerializeDict_Nil {
    NSMutableDictionary *dict = nil;
    NSData *data = [self.prefHelper serializePrefDict:dict];    
    XCTAssert(data == nil);
}

- (void)testSerializeDict_Empty {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 0);
}

- (void)testSerializeDict_String {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *value = @"the quick brown fox jumps over the lazy dog";
    NSString *key = @"test";
    [dict setObject:value forKey:key];
    
    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 1);
    
    XCTAssert([[tmp objectForKey:key] isEqualToString:value]);
}

- (void)testSerializeDict_Date {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSDate *value = [NSDate date];
    NSString *key = @"test";
    [dict setObject:value forKey:key];
    
    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 1);
    
    XCTAssert([[tmp objectForKey:key] isEqual:value]);
}

- (void)testSerializeDict_Bool {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    bool value = YES;
    NSString *key = @"test";
    [dict setObject:@(value) forKey:key];
    
    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 1);
    
    XCTAssert([[tmp objectForKey:key] isEqual:@(value)]);
}

- (void)testSerializeDict_Integer {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSInteger value = 1234;
    NSString *key = @"test";
    [dict setObject:@(value) forKey:key];
    
    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 1);
    
    XCTAssert([[tmp objectForKey:key] isEqual:@(value)]);
}

- (void)testSerializeDict_All {
    NSMutableDictionary *dict = [NSMutableDictionary new];

    NSString *value1 = @"the quick brown fox jumps over the lazy dog";
    NSString *key1 = @"test1";
    [dict setObject:value1 forKey:key1];
    
    NSDate *value2 = [NSDate date];
    NSString *key2 = @"test2";
    [dict setObject:value2 forKey:key2];
    
    bool value3 = YES;
    NSString *key3 = @"test3";
    [dict setObject:@(value3) forKey:key3];
    
    NSInteger value4 = 1234;
    NSString *key4 = @"test4";
    [dict setObject:@(value4) forKey:key4];

    NSData *data = [self.prefHelper serializePrefDict:dict];
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    XCTAssert(tmp.count == 4);
    
    XCTAssert([[tmp objectForKey:key1] isEqualToString:value1]);
    XCTAssert([[tmp objectForKey:key2] isEqual:value2]);
    XCTAssert([[tmp objectForKey:key3] isEqual:@(value3)]);
    XCTAssert([[tmp objectForKey:key4] isEqual:@(value4)]);
}

- (void)testURLSkipList {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSString *key = @"test";
    NSArray<NSString *> *value = @[
        @"^fb\\d+:",
        @"^li\\d+:",
        @"^pdk\\d+:",
        @"^twitterkit-.*:",
        @"^com\\.googleusercontent\\.apps\\.\\d+-.*:\\/oauth",
        @"^(?i)(?!(http|https):).*(:|:.*\\b)(password|o?auth|o?auth.?token|access|access.?token)\\b",
        @"^(?i)((http|https):\\/\\/).*[\\/|?|#].*\\b(password|o?auth|o?auth.?token|access|access.?token)\\b",
    ];
    [dict setObject:value forKey:key];
    NSData *data = [self.prefHelper serializePrefDict:dict];
    
    NSMutableDictionary *tmp = [self.prefHelper deserializePrefDictFromData:data];
    
    XCTAssert(tmp != nil);
    XCTAssert([tmp isKindOfClass:NSMutableDictionary.class]);
    
    NSArray *filter = [tmp objectForKey:key];
    
    NSString *filterDesc = filter.description;
    NSString *valueDesc = value.description;
    XCTAssert([filterDesc isEqualToString:valueDesc]);
}

/*
- (void)testSetAPIURL_Example {
    
    NSString *url = @"https://www.example.com/";
    [BranchPluginSupport setAPIUrl:url] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].branchAPIURL ;
    XCTAssert([url isEqualToString:urlStored]);
}

- (void)testSetAPIURL_InvalidHttp {
    
    NSString *url = @"Invalid://www.example.com/";
    [BranchPluginSupport setAPIUrl:url] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].branchAPIURL ;
    XCTAssert(![url isEqualToString:urlStored]);
    XCTAssert([urlStored isEqualToString:BNC_API_BASE_URL]);
}

- (void)testSetAPIURL_InvalidEmpty {
    
    [BranchPluginSupport setAPIUrl:@""] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].branchAPIURL ;
    XCTAssert(![urlStored isEqualToString:@""]);
    XCTAssert([urlStored isEqualToString:BNC_API_BASE_URL]);
}

- (void)testSetCDNBaseURL_Example {
    
    NSString *url = @"https://www.example.com/";
    [BranchPluginSupport setCDNBaseUrl:url] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].patternListURL ;
    XCTAssert([url isEqualToString:urlStored]);
}

- (void)testSetCDNBaseURL_InvalidHttp {
    
    NSString *url = @"Invalid://www.example.com/";
    [BranchPluginSupport setCDNBaseUrl:url] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].patternListURL ;
    XCTAssert(![url isEqualToString:urlStored]);
    XCTAssert([urlStored isEqualToString:BNC_CDN_URL]);
}

- (void)testSetCDNBaseURL_InvalidEmpty {
    
    [BranchPluginSupport setCDNBaseUrl:@""] ;
    
    NSString *urlStored = [BNCPreferenceHelper sharedInstance].patternListURL ;
    XCTAssert(![urlStored isEqualToString:@""]);
    XCTAssert([urlStored isEqualToString:BNC_CDN_URL]);
}
 */

- (void)testSetPatternListURL {
    NSString *expectedURL = @"https://example.com";
    [[BNCPreferenceHelper sharedInstance] setPatternListURL: expectedURL];
    
    NSString *patternListURL = [BNCPreferenceHelper sharedInstance].patternListURL;
    XCTAssert([patternListURL isEqualToString: expectedURL]);
}

- (void)testSetLastStrongMatchDate {
    NSDate *expectedDate = [NSDate date];
    [[BNCPreferenceHelper sharedInstance] setLastStrongMatchDate: expectedDate];
    
    NSDate *actualDate = [[BNCPreferenceHelper sharedInstance] lastStrongMatchDate];
    XCTAssertEqualObjects(expectedDate, actualDate);
}

- (void)testSetAppVersion {
    NSString *expectedVersion = @"1.0.0";
    [[BNCPreferenceHelper sharedInstance] setAppVersion: expectedVersion];
    
    NSString *actualVersion = [[BNCPreferenceHelper sharedInstance] appVersion];
    XCTAssertEqualObjects(expectedVersion, actualVersion);
}

- (void)testSetLocalUrl {
    NSString *expectedLocalURL = @"https://local.example.com";
    [[BNCPreferenceHelper sharedInstance] setLocalUrl:expectedLocalURL];
    
    NSString *localURL = [[BNCPreferenceHelper sharedInstance] localUrl];
    XCTAssertEqualObjects(localURL, expectedLocalURL);
}

- (void)testSetInitialReferrer {
    NSString *expectedReferrer = @"referrer.example.com";
    [[BNCPreferenceHelper sharedInstance] setInitialReferrer:expectedReferrer];
    
    NSString *actualReferrer = [[BNCPreferenceHelper sharedInstance] initialReferrer];
    XCTAssertEqualObjects(actualReferrer, expectedReferrer);
}

- (void)testSetAppleAttributionTokenChecked {
    BOOL expectedValue = YES;
    [[BNCPreferenceHelper sharedInstance] setAppleAttributionTokenChecked:expectedValue];
    
    BOOL actualValue = [[BNCPreferenceHelper sharedInstance] appleAttributionTokenChecked];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetHasOptedInBefore {
    BOOL expectedValue = YES;
    [[BNCPreferenceHelper sharedInstance] setHasOptedInBefore:expectedValue];
    
    BOOL actualValue = [[BNCPreferenceHelper sharedInstance] hasOptedInBefore];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetHasCalledHandleATTAuthorizationStatus {
    BOOL expectedValue = YES;
    [[BNCPreferenceHelper sharedInstance] setHasCalledHandleATTAuthorizationStatus:expectedValue];
    
    BOOL actualValue = [[BNCPreferenceHelper sharedInstance] hasCalledHandleATTAuthorizationStatus];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetRequestMetadataKeyValidKeyValue {
    NSString *key = @"testKey";
    NSString *value = @"testValue";
    
    [[BNCPreferenceHelper sharedInstance] setRequestMetadataKey:key value:value];
    
    NSObject *retrievedValue = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary objectForKey:key];
    XCTAssertEqualObjects(retrievedValue, value);
}

- (void)testSetRequestMetadataKeyValidKeyNilValue {
    NSString *key = @"testKey";
    NSString *value = @"testValue";
    
    [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary setObject:value forKey:key];
    
    [[BNCPreferenceHelper sharedInstance] setRequestMetadataKey:key value:nil];
    
    NSObject *retrievedValue = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary objectForKey:key];
    XCTAssertNil(retrievedValue);
}

- (void)testSetRequestMetadataKeyValidKeyNilValueKeyNotExists {
    NSString *key = @"testKeyNotExists";
    
    NSUInteger initialDictCount = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary count];
    
    [[BNCPreferenceHelper sharedInstance] setRequestMetadataKey:key value:nil];
    
    NSUInteger postActionDictCount = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary count];
    XCTAssertEqual(initialDictCount, postActionDictCount);
}

- (void)testSetRequestMetadataKeyNilKey {
    NSString *value = @"testValue";
    NSUInteger initialDictCount = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary count];
    
    [[BNCPreferenceHelper sharedInstance] setRequestMetadataKey:nil value:value];
    
    NSUInteger postActionDictCount = [[BNCPreferenceHelper sharedInstance].requestMetadataDictionary count];
    XCTAssertEqual(initialDictCount, postActionDictCount);
}

- (void)testSetLimitFacebookTracking {
    BOOL expectedValue = YES;
    
    [[BNCPreferenceHelper sharedInstance] setLimitFacebookTracking:expectedValue];
    
    BOOL storedValue = [[BNCPreferenceHelper sharedInstance] limitFacebookTracking];
    
    XCTAssertEqual(expectedValue, storedValue);
}

- (void)testSetTrackingDisabled_YES {
    [[BNCPreferenceHelper sharedInstance] setTrackingDisabled:YES];

    BOOL storedValue = [[BNCPreferenceHelper sharedInstance] trackingDisabled];
    XCTAssertTrue(storedValue);
}

- (void)testSetTrackingDisabled_NO {
    [[BNCPreferenceHelper sharedInstance] setTrackingDisabled:NO];
    
    BOOL storedValue = [[BNCPreferenceHelper sharedInstance] trackingDisabled];
    XCTAssertFalse(storedValue);
}

- (void)testClearTrackingInformation {
    [[BNCPreferenceHelper sharedInstance] clearTrackingInformation];
    
    XCTAssertNil([BNCPreferenceHelper sharedInstance].sessionID);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].linkClickIdentifier);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].spotlightIdentifier);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].referringURL);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].universalLinkUrl);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].initialReferrer);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].installParams);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].sessionParams);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].externalIntentURI);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].savedAnalyticsData);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].previousAppBuildDate);
    XCTAssertEqual([BNCPreferenceHelper sharedInstance].requestMetadataDictionary.count, 0);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].lastStrongMatchDate);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].userIdentity);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].referringURLQueryParameters);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].anonID);
}

- (void)testSaveBranchAnalyticsData {
    NSString *dummySessionID = @"testSession123";
    NSDictionary *dummyAnalyticsData = @{ @"key1": @"value1", @"key2": @"value2" };
    
    // Assuming there's a method or property to set the sessionID
    [BNCPreferenceHelper sharedInstance].sessionID = dummySessionID;
    
    [[BNCPreferenceHelper sharedInstance] saveBranchAnalyticsData:dummyAnalyticsData];
    
    NSMutableDictionary *retrievedData = [[BNCPreferenceHelper sharedInstance] getBranchAnalyticsData];
    
    NSArray *viewDataArray = [retrievedData objectForKey:dummySessionID];
    XCTAssertNotNil(viewDataArray);
    XCTAssertEqual(viewDataArray.count, 1);
    XCTAssertEqualObjects(viewDataArray.firstObject, dummyAnalyticsData);
}

- (void)testClearBranchAnalyticsData {
    [[BNCPreferenceHelper sharedInstance] clearBranchAnalyticsData];
    
    NSMutableDictionary *retrievedData = [[BNCPreferenceHelper sharedInstance] getBranchAnalyticsData];
    XCTAssertEqual(retrievedData.count, 0);
}

- (void)testSaveContentAnalyticsManifest {
    NSDictionary *dummyManifest = @{ @"manifestKey1": @"manifestValue1", @"manifestKey2": @"manifestValue2" };
    
    [[BNCPreferenceHelper sharedInstance] saveContentAnalyticsManifest:dummyManifest];
    
    NSDictionary *retrievedManifest = [[BNCPreferenceHelper sharedInstance] getContentAnalyticsManifest];
    
    XCTAssertEqualObjects(retrievedManifest, dummyManifest);
}



@end

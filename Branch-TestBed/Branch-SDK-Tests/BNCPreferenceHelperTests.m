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

// This test is not reliable when run concurrently with other tests that set the patterListURL
- (void)testURLFilter {
    XCTAssertTrue([@"https://cdn.branch.io" isEqualToString:self.prefHelper.patternListURL]);
    
    NSString *customURL = @"https://banned.branch.io";
    self.prefHelper.patternListURL = customURL;
    XCTAssertTrue([customURL isEqualToString:self.prefHelper.patternListURL]);
}

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

- (void)testSetCDNBaseURL_Example {
    
    NSString *url = @"https://www.example.com/";
    [self.prefHelper setPatternListURL:url];
    
    NSString *urlStored = self.prefHelper.patternListURL ;
    XCTAssert([url isEqualToString:urlStored]);
}

- (void)testSetCDNBaseURL_InvalidHttp {
    
    NSString *url = @"Invalid://www.example.com/";
    [self.prefHelper setPatternListURL:url] ;
    
    NSString *urlStored = self.prefHelper.patternListURL ;
    XCTAssert(![url isEqualToString:urlStored]);
    XCTAssert([urlStored isEqualToString:BNC_CDN_URL]);
}

- (void)testSetCDNBaseURL_InvalidEmpty {
    
    [self.prefHelper setPatternListURL:@""] ;
    
    NSString *urlStored = self.prefHelper.patternListURL ;
    XCTAssert(![urlStored isEqualToString:@""]);
    XCTAssert([urlStored isEqualToString:BNC_CDN_URL]);
}

- (void)testSetPatternListURL {
    NSString *expectedURL = @"https://example.com";
    [self.prefHelper setPatternListURL:expectedURL];
    
    NSString *patternListURL = self.prefHelper.patternListURL;
    XCTAssert([patternListURL isEqualToString: expectedURL]);
}

- (void)testSetLastStrongMatchDate {
    NSDate *expectedDate = [NSDate date];
    [self.prefHelper setLastStrongMatchDate: expectedDate];
    
    NSDate *actualDate = [self.prefHelper lastStrongMatchDate];
    XCTAssertEqualObjects(expectedDate, actualDate);
}


- (void)testSetLocalUrl {
    NSString *expectedLocalURL = @"https://local.example.com";
    [self.prefHelper setLocalUrl:expectedLocalURL];
    
    NSString *localURL = [self.prefHelper localUrl];
    XCTAssertEqualObjects(localURL, expectedLocalURL);
}

- (void)testSetInitialReferrer {
    NSString *expectedReferrer = @"referrer.example.com";
    [self.prefHelper setInitialReferrer:expectedReferrer];
    
    NSString *actualReferrer = [self.prefHelper initialReferrer];
    XCTAssertEqualObjects(actualReferrer, expectedReferrer);
}

- (void)testSetAppleAttributionTokenChecked {
    BOOL expectedValue = YES;
    [self.prefHelper setAppleAttributionTokenChecked:expectedValue];
    
    BOOL actualValue = [self.prefHelper appleAttributionTokenChecked];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetHasOptedInBefore {
    BOOL expectedValue = YES;
    [self.prefHelper setHasOptedInBefore:expectedValue];
    
    BOOL actualValue = [self.prefHelper hasOptedInBefore];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetHasCalledHandleATTAuthorizationStatus {
    BOOL expectedValue = YES;
    [self.prefHelper setHasCalledHandleATTAuthorizationStatus:expectedValue];
    
    BOOL actualValue = [self.prefHelper hasCalledHandleATTAuthorizationStatus];
    XCTAssertEqual(expectedValue, actualValue);
}

- (void)testSetRequestMetadataKeyValidKeyValue {
    NSString *key = @"testKey";
    NSString *value = @"testValue";
    
    [self.prefHelper setRequestMetadataKey:key value:value];
    
    NSObject *retrievedValue = [self.prefHelper.requestMetadataDictionary objectForKey:key];
    XCTAssertEqualObjects(retrievedValue, value);
}

- (void)testSetRequestMetadataKeyValidKeyNilValue {
    NSString *key = @"testKey";
    NSString *value = @"testValue";
    
    [self.prefHelper.requestMetadataDictionary setObject:value forKey:key];
    
    [self.prefHelper setRequestMetadataKey:key value:nil];
    
    NSObject *retrievedValue = [self.prefHelper.requestMetadataDictionary objectForKey:key];
    XCTAssertNil(retrievedValue);
}

- (void)testSetRequestMetadataKeyValidKeyNilValueKeyNotExists {
    NSString *key = @"testKeyNotExists";
    
    NSUInteger initialDictCount = [self.prefHelper.requestMetadataDictionary count];
    
    [self.prefHelper setRequestMetadataKey:key value:nil];
    
    NSUInteger postActionDictCount = [self.prefHelper.requestMetadataDictionary count];
    XCTAssertEqual(initialDictCount, postActionDictCount);
}

- (void)testSetRequestMetadataKeyNilKey {
    NSString *value = @"testValue";
    NSUInteger initialDictCount = [self.prefHelper.requestMetadataDictionary count];
    
    [self.prefHelper setRequestMetadataKey:nil value:value];
    
    NSUInteger postActionDictCount = [self.prefHelper.requestMetadataDictionary count];
    XCTAssertEqual(initialDictCount, postActionDictCount);
}

- (void)testSetLimitFacebookTracking {
    BOOL expectedValue = YES;
    
    [self.prefHelper setLimitFacebookTracking:expectedValue];
    
    BOOL storedValue = [self.prefHelper limitFacebookTracking];
    
    XCTAssertEqual(expectedValue, storedValue);
}

- (void)testSetTrackingDisabled_YES {
    [self.prefHelper setTrackingDisabled:YES];

    BOOL storedValue = [self.prefHelper trackingDisabled];
    XCTAssertTrue(storedValue);
    [self.prefHelper setTrackingDisabled:NO];
}

- (void)testSetTrackingDisabled_NO {
    [self.prefHelper setTrackingDisabled:NO];
    
    BOOL storedValue = [self.prefHelper trackingDisabled];
    XCTAssertFalse(storedValue);
}

// TODO: rethink this test as these values are not set in a freshly instantiated prefHelper
- (void)testClearTrackingInformation {
    [self.prefHelper clearTrackingInformation];
    
    XCTAssertNil(self.prefHelper.sessionID);
    XCTAssertNil(self.prefHelper.installParams);
    XCTAssertNil(self.prefHelper.sessionParams);
    XCTAssertNil(self.prefHelper.savedAnalyticsData);
    XCTAssertNil(self.prefHelper.previousAppBuildDate);
    XCTAssertEqual(self.prefHelper.requestMetadataDictionary.count, 0);
    XCTAssertNil(self.prefHelper.lastStrongMatchDate);
    XCTAssertNil(self.prefHelper.userIdentity);
    XCTAssertNil(self.prefHelper.referringURLQueryParameters);
    XCTAssertNil(self.prefHelper.anonID);
}

- (void)testSaveBranchAnalyticsData {
    NSString *dummySessionID = @"testSession123";
    NSDictionary *dummyAnalyticsData = @{ @"key1": @"value1", @"key2": @"value2" };
    
    self.prefHelper.sessionID = dummySessionID;
    
    [self.prefHelper saveBranchAnalyticsData:dummyAnalyticsData];
    
    NSMutableDictionary *retrievedData = [self.prefHelper getBranchAnalyticsData];
    
    NSArray *viewDataArray = [retrievedData objectForKey:dummySessionID];
    XCTAssertNotNil(viewDataArray);
    XCTAssertEqual(viewDataArray.count, 1);
    XCTAssertEqualObjects(viewDataArray.firstObject, dummyAnalyticsData);
}

- (void)testClearBranchAnalyticsData {
    [self.prefHelper clearBranchAnalyticsData];
    
    NSMutableDictionary *retrievedData = [self.prefHelper getBranchAnalyticsData];
    XCTAssertEqual(retrievedData.count, 0);
}

- (void)testSaveContentAnalyticsManifest {
    NSDictionary *dummyManifest = @{ @"manifestKey1": @"manifestValue1", @"manifestKey2": @"manifestValue2" };
    
    [self.prefHelper saveContentAnalyticsManifest:dummyManifest];
    
    NSDictionary *retrievedManifest = [self.prefHelper getContentAnalyticsManifest];
    
    XCTAssertEqualObjects(retrievedManifest, dummyManifest);
}

@end

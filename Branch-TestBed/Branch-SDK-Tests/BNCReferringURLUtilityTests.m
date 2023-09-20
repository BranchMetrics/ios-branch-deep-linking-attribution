//
//  BNCReferringURLUtilityTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 3/9/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCReferringURLUtility.h"
#import "BNCUrlQueryParameter.h"
#import "BNCPreferenceHelper.h"

@interface BNCReferringURLUtility(Test)
// expose the private data structure so tests can clear it
@property (strong, readwrite, nonatomic) NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *urlQueryParameters;

// expose private methods to test data migration
- (void)checkForAndMigrateOldGbraid;
@end

@interface BNCReferringURLUtilityTests : XCTestCase

@end

@implementation BNCReferringURLUtilityTests

// test constants
static NSString *openEndpoint = @"/v1/open";
static NSString *eventEndpoint = @"/v2/event";

+ (void)tearDown {
    // clear test data from global storage
    [BNCPreferenceHelper sharedInstance].referringURLQueryParameters = nil;
    [BNCPreferenceHelper sharedInstance].referrerGBRAID = nil;
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDValidityWindow = 0;
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate = nil;
}

// workaround for BNCPreferenceHelper being persistent across tests and not currently mockable
- (BNCReferringURLUtility *)referringUtilityForTests {
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    utility.urlQueryParameters = [NSMutableDictionary new];
    return utility;
}

// make gbraid equality check simpler by excluding timestamp
- (NSDictionary *)removeTimestampFromParams:(NSDictionary *)params {
    NSMutableDictionary *paramsWithoutTimestamp = [params mutableCopy];
    paramsWithoutTimestamp[@"gbraid_timestamp"] = nil;
    return paramsWithoutTimestamp;
}

// gbraid timestamp is a string representing time in millis
- (void)validateGbraidTimestampInReferringParameters:(NSDictionary *)params {
    id timestamp = params[@"gbraid_timestamp"];
    XCTAssert(timestamp != nil);
    XCTAssert([timestamp isKindOfClass:NSString.class]);
}

- (void)expireValidityWindowsInUtility:(BNCReferringURLUtility *)utility {
    for (NSString *paramName in utility.urlQueryParameters.allKeys) {
        BNCUrlQueryParameter *param = utility.urlQueryParameters[paramName];
        
        // currently the longest validity window is 30 days
        NSTimeInterval sixtyDaysAgo = -1 * 60 * 24 * 60 * 60;
        param.timestamp = [NSDate dateWithTimeIntervalSinceNow:sixtyDaysAgo];
    }
}

- (void)testReferringURLWithNoParams {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link"];
    NSDictionary *expected = @{};
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?other=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

// NSURL treats URI schemes in a consistent manner with Universal Links
- (void)testReferringURLWithURISchemeSanityCheck{
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidCapitalized {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?GCLID=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidMixedCase {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?GcLiD=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidNoValue {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid="];
    NSDictionary *expected = @{
        @"gclid": @""
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidValueCasePreserved {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=aAbBcC"];
    NSDictionary *expected = @{
        @"gclid": @"aAbBcC"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345&other=abcde"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345#header"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidAsFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?other=abcde#gclid=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGclidOverwritesValue {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    NSURL *url2 = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=abcde"];
    NSDictionary *expected2 = @{
        @"gclid": @"abcde"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    XCTAssert([expected isEqualToDictionary:params]);
    
    [utility parseReferringURL:url2];
    NSDictionary *params2 = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected2 isEqualToDictionary:params2]);
}

- (void)testReferringURLWithMetaCampaignIds {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{
        @"meta_campaign_ids": @"ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithMetaCampaignIdsExpired {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    [self expireValidityWindowsInUtility:utility];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithMetaNoCampaignIds {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithGbraid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gbraid=abcde"];
    NSDictionary *expected = @{
        @"gbraid": @"abcde",
        @"is_deeplink_gbraid": @(true)
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    [self validateGbraidTimestampInReferringParameters:params];
    NSDictionary *paramsWithoutTimestamp = [self removeTimestampFromParams:params];
    XCTAssert([expected isEqualToDictionary:paramsWithoutTimestamp]);
}

- (void)testReferringURLWithGbraidOnEvent {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gbraid=abcde"];
    NSDictionary *expected = @{
        @"gbraid": @"abcde"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:eventEndpoint];
    
    [self validateGbraidTimestampInReferringParameters:params];
    NSDictionary *paramsWithoutTimestamp = [self removeTimestampFromParams:params];
    XCTAssert([expected isEqualToDictionary:paramsWithoutTimestamp]);
}

- (void)testReferringURLWithGbraidExpired {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gbraid=abcde"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    [self expireValidityWindowsInUtility:utility];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLPreservesNonZeroValidityWindowForGbraid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gbraid=12345"];

    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    
    // pretend this object was loaded from disk
    // this simulates setting a custom non-zero validity window, only supported for gbraid
    BNCUrlQueryParameter *existingParam = [BNCUrlQueryParameter new];
    existingParam.name = @"gbraid";
    existingParam.value = @"";
    existingParam.timestamp = [NSDate date];
    existingParam.validityWindow = 5; // not the default gbraid window
    utility.urlQueryParameters[@"gbraid"] = existingParam;
    
    [utility parseReferringURL:url];
        
    // verify validity window was not changed
    XCTAssert(utility.urlQueryParameters[@"gbraid"].validityWindow == 5);
}

- (void)testReferringURLOverwritesZeroValidityWindowForGbraid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gbraid=12345"];

    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    
    // pretend this object was loaded from disk
    // for gbraid, or any param, we overwrite the 0 validity windows with the default
    BNCUrlQueryParameter *existingParam = [BNCUrlQueryParameter new];
    existingParam.name = @"gbraid";
    existingParam.value = @"";
    existingParam.timestamp = [NSDate date];
    existingParam.validityWindow = 0;
    utility.urlQueryParameters[@"gbraid"] = existingParam;
    
    [utility parseReferringURL:url];
    
    // verify validity window was changed
    XCTAssert(utility.urlQueryParameters[@"gbraid"].validityWindow != 0);
}

- (void)testReferringURLWithGclidGbraid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345&gbraid=abcde"];
    NSDictionary *expected = @{
        @"gclid": @"12345",
        @"gbraid": @"abcde",
        @"is_deeplink_gbraid": @(true)
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    [self validateGbraidTimestampInReferringParameters:params];
    NSDictionary *paramsWithoutTimestamp = [self removeTimestampFromParams:params];
    XCTAssert([expected isEqualToDictionary:paramsWithoutTimestamp]);
}

- (void)testGbraidDataMigration {
    // Manipulates the global BNCPreferenceHelper.
    // This is not safe for concurrent unit tests, so only the happy path is tested.
    [self clearCurrentQueryParameters];
    [self addOldGbraidData];
    
    NSDictionary *expected = @{
        @"gbraid": @"abcde",
        @"is_deeplink_gbraid": @(false)
    };
    
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    [self validateGbraidTimestampInReferringParameters:params];
    NSDictionary *paramsWithoutTimestamp = [self removeTimestampFromParams:params];
    XCTAssert([expected isEqualToDictionary:paramsWithoutTimestamp]);
    
    [self verifyOldGbraidDataIsCleared];
}

- (void)clearCurrentQueryParameters {
    [BNCPreferenceHelper sharedInstance].referringURLQueryParameters = nil;
}

- (void)addOldGbraidData {
    [BNCPreferenceHelper sharedInstance].referrerGBRAID = @"abcde";
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDValidityWindow = 2592000;
    [BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate = [NSDate date];
}

- (void)verifyOldGbraidDataIsCleared {
    XCTAssertNil([BNCPreferenceHelper sharedInstance].referrerGBRAID);
    XCTAssert([BNCPreferenceHelper sharedInstance].referrerGBRAIDValidityWindow == 0);
    XCTAssertNil([BNCPreferenceHelper sharedInstance].referrerGBRAIDInitDate);
}

- (void)testReferringURLWithSccid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=12345"];
    NSDictionary *expected = @{
        @"sccid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidMixedCase {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?ScCiD=12345"];
    NSDictionary *expected = @{
        @"sccid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidNoValue {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid="];
    NSDictionary *expected = @{
        @"sccid": @""
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidValueCasePreserved {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=aAbBcC"];
    NSDictionary *expected = @{
        @"sccid": @"aAbBcC"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=12345&other=abcde"];
    NSDictionary *expected = @{
        @"sccid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=12345#header"];
    NSDictionary *expected = @{
        @"sccid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidAsFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?other=abcde#sccid=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLWithSccidOverwritesValue {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=12345"];
    NSDictionary *expected = @{
        @"sccid": @"12345"
    };
    
    NSURL *url2 = [NSURL URLWithString:@"https://bnctestbed.app.link?sccid=abcde"];
    NSDictionary *expected2 = @{
        @"sccid": @"abcde"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    XCTAssert([expected isEqualToDictionary:params]);
    
    [utility parseReferringURL:url2];
    NSDictionary *params2 = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected2 isEqualToDictionary:params2]);
}


@end

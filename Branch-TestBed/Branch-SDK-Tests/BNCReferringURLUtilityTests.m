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

// workaround for BNCPreferenceHelper being persistent across tests and not currently mockable
- (BNCReferringURLUtility *)referringUtilityForTests {
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    utility.urlQueryParameters = [NSMutableDictionary new];
    return utility;
}

- (void)testReferringURLUniversalLinkWithNoParams {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link"];
    NSDictionary *expected = @{};

    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithNoParams {
    NSURL *url = [NSURL URLWithString:@"branchtest://"];
    NSDictionary *expected = @{};

    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?other=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"branchtest://?other=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclid {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclid {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidCapitalizedConvertedToLowerCase {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?GCLID=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidCapitalizedConvertedToLowerCase {
    NSURL *url = [NSURL URLWithString:@"branchtest://?GCLID=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidMixedCaseConvertedToLowerCase {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?GcLiD=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidMixedCaseConvertedToLowerCase {
    NSURL *url = [NSURL URLWithString:@"branchtest://?GcLiD=12345"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidNoValue {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid="];
    NSDictionary *expected = @{
        @"gclid": @""
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidNoValue {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid="];
    NSDictionary *expected = @{
        @"gclid": @""
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidValueCasePreserved {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=aAbBcC"];
    NSDictionary *expected = @{
        @"gclid": @"aAbBcC"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidValueCasePreserved {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=aAbBcC"];
    NSDictionary *expected = @{
        @"gclid": @"aAbBcC"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345&other=abcde"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidIgnoredParam {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=12345&other=abcde"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?gclid=12345#header"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidFragment {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=12345#header"];
    NSDictionary *expected = @{
        @"gclid": @"12345"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithGclidAsFragment{
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?other=abcde#gclid=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithGclidAsFragment {
    NSURL *url = [NSURL URLWithString:@"branchtest://?other=abcde#gclid=12345"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithMetaCampaignIds {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{
        @"meta_campaign_ids": @"ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithMetaCampaignIds {
    NSURL *url = [NSURL URLWithString:@"branchtest://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22campaign_ids%22%3A%22ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{
        @"meta_campaign_ids": @"ARFUlbyOurYrHT2DsknR7VksCSgN4tiH8TzG8RIvVoUQoYog5bVCvADGJil5kFQC6tQm-fFJQH0w8wCi3NbOmEHHrtgCNglkXNY-bECEL0aUhj908hIxnBB0tchJCqwxHjorOUqyk2v4bTF75PyWvxOksZ6uTzBmr7wJq8XnOav0bA"
    };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLUniversalLinkWithMetaNoCampaignIds {
    NSURL *url = [NSURL URLWithString:@"https://bnctestbed.app.link?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

- (void)testReferringURLSchemeWithMetaNoCampaignIds {
    NSURL *url = [NSURL URLWithString:@"branchtest://products/next?al_applink_data=%7B%22target_url%22%3A%22http%3A%5C%2F%5C%2Fitunes.apple.com%5C%2Fapp%5C%2Fid880047117%22%2C%22extras%22%3A%7B%22fb_app_id%22%3A2020399148181142%7D%2C%22referer_app_link%22%3A%7B%22url%22%3A%22fb%3A%5C%2F%5C%2F%5C%2F%3Fapp_id%3D2020399148181142%22%2C%22app_name%22%3A%22Facebook%22%7D%2C%22acs_token%22%3A%22debuggingtoken%22%2C%22test_deeplink%22%3A1%7D"];
    NSDictionary *expected = @{ };
    
    BNCReferringURLUtility *utility = [self referringUtilityForTests];
    [utility parseReferringURL:url];
    NSDictionary *params = [utility referringURLQueryParamsForEndpoint:openEndpoint];
    
    XCTAssert([expected isEqualToDictionary:params]);
}

// gbraid timestamp is a string representing time in millis
- (void)validateGbraidTimestampInReferringParameters:(NSDictionary *)params {
    id timestamp = params[@"gbraid_timestamp"];
    XCTAssert(timestamp != nil);
    XCTAssert([timestamp isKindOfClass:NSString.class]);
}

// make gbraid equality check simpler by excluding timestamp
- (NSDictionary *)removeTimestampFromParams:(NSDictionary *)params {
    NSMutableDictionary *paramsWithoutTimestamp = [params mutableCopy];
    paramsWithoutTimestamp[@"gbraid_timestamp"] = nil;
    return paramsWithoutTimestamp;
}

- (void)testReferringURLUniversalLinkWithGbraid {
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

- (void)testReferringURLSchemeWithGbraid {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gbraid=abcde"];
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

- (void)testReferringURLUniversalLinkWithGclidGbraid {
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

- (void)testReferringURLSchemeWithGclidGbraid {
    NSURL *url = [NSURL URLWithString:@"branchtest://?gclid=12345&gbraid=abcde"];
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

@end

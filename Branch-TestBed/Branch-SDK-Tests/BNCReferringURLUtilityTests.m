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

- (NSString *)addGclidValueFor:(NSString *)endpoint;
- (NSDictionary *)addGbraidValuesFor:(NSString *)endpoint;
- (BOOL)isSupportedQueryParameter:(NSString *)param;
- (BNCUrlQueryParameter *)findUrlQueryParam:(NSString *)paramName;
- (NSTimeInterval)defaultValidityWindowForParam:(NSString *)paramName;
- (NSMutableDictionary *)serializeToJson:(NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)urlQueryParameters;
- (NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)deserializeFromJson:(NSDictionary *)json;
- (void)checkForAndMigrateOldGbraid;

@end

@interface BNCReferringURLUtilityTests : XCTestCase

@end

@implementation BNCReferringURLUtilityTests

BNCPreferenceHelper *prefHelper;
BNCReferringURLUtility *utility;
NSString *gbraidValue;
NSString *gclidValue;

NSString *eventEndpoint;
NSString *openEndpoint;

- (void)setUp {
    prefHelper = [BNCPreferenceHelper sharedInstance];
    prefHelper.referringURLQueryParameters = nil;
    
    eventEndpoint = @"/v2/event";
    openEndpoint = @"/v1/open";
    
    gclidValue = @"gclid123";
    gbraidValue = @"gbraid456";
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.branch.io?test=456&gbraid=%@&gclid=%@", gbraidValue, gclidValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];
}

- (void)testParseURL {
    NSMutableDictionary *savedParams = prefHelper.referringURLQueryParameters;
    
    // Remove the timestamp keys from savedParams for compare
    [savedParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *paramDict = (NSMutableDictionary *)obj;
        [paramDict removeObjectForKey:@"timestamp"];
    }];
    
    NSMutableDictionary *gbraidDict = [NSMutableDictionary dictionary];
    gbraidDict[@"isDeepLink"] = @(1);
    gbraidDict[@"name"] = @"gbraid";
    gbraidDict[@"validityWindow"] = @(2592000);
    gbraidDict[@"value"] = gbraidValue;

    NSMutableDictionary *gclidDict = [NSMutableDictionary dictionary];
    gclidDict[@"isDeepLink"] = @(1);
    gclidDict[@"name"] = @"gclid";
    gclidDict[@"validityWindow"] = @(0);
    gclidDict[@"value"] = gclidValue;

    NSMutableDictionary *expectedParams = [NSMutableDictionary dictionary];
    expectedParams[@"gbraid"] = gbraidDict;
    expectedParams[@"gclid"] = gclidDict;
    
    XCTAssertEqualObjects(savedParams, expectedParams);
}

- (void)testGetEventURLQueryParams {

    NSDictionary *params = [utility getURLQueryParamsForRequest:eventEndpoint];
    NSDictionary *expectedParams = @{@"gbraid": gbraidValue,
                                       @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                       @"gclid": gclidValue};

    XCTAssertEqualObjects(params, expectedParams);
}

- (void)testGetOpenURLQueryParams {
    
    NSDictionary *params = [utility getURLQueryParamsForRequest:openEndpoint];
    NSDictionary *expectedParams = @{@"gbraid": gbraidValue,
                                     @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                     @"is_deeplink_gbraid": @YES,
                                     @"gclid": gclidValue};
    
    XCTAssertEqualObjects(params, expectedParams);
}

- (void)testAddGclidValueFor {
    NSString *eventGclidValue = [utility addGclidValueFor:eventEndpoint];
    XCTAssertEqualObjects(eventGclidValue, gclidValue);
    
    NSString *openGclidValue = [utility addGclidValueFor:openEndpoint];
    XCTAssertEqualObjects(openGclidValue, gclidValue);
}

- (void)testAddGbraidValuesFor {
    NSDictionary *eventGbraidValue = [utility addGbraidValuesFor:eventEndpoint];
    
    NSDictionary *expectedEventGraidValue = @{
        @"gbraid": gbraidValue,
        @"gbraid_timestamp": eventGbraidValue[@"gbraid_timestamp"]
    };
    
    XCTAssertEqualObjects(eventGbraidValue, expectedEventGraidValue);
    
    NSDictionary *expectedOpenGraidValue = @{
        @"gbraid": gbraidValue,
        @"gbraid_timestamp": eventGbraidValue[@"gbraid_timestamp"],
        @"is_deeplink_gbraid": @(1)
    };
    
    NSDictionary *openGbraidValue = [utility addGbraidValuesFor:openEndpoint];
    XCTAssertEqualObjects(openGbraidValue, expectedOpenGraidValue);
}

- (void)testIsSupportedQueryParameter {
    NSArray *validURLQueryParameters = @[@"gbraid", @"gclid"];
    
    for (NSString *param in validURLQueryParameters) {
        XCTAssertTrue([utility isSupportedQueryParameter:param]);
    }
    
}

- (void)testFindUrlQueryParam {
    BNCUrlQueryParameter *gbraid = [utility findUrlQueryParam:@"gbraid"];
    
    BNCUrlQueryParameter *expectedGbraid = [BNCUrlQueryParameter new];
    expectedGbraid.name = @"gbraid";
    expectedGbraid.value = gbraidValue;
    expectedGbraid.timestamp = gbraid.timestamp;
    expectedGbraid.validityWindow = gbraid.validityWindow;
    expectedGbraid.isDeepLink = @(1);
    
    XCTAssertEqualObjects(gbraid, expectedGbraid);
    
    BNCUrlQueryParameter *gclid = [utility findUrlQueryParam:@"gclid"];
    
    BNCUrlQueryParameter *expectedGclid = [BNCUrlQueryParameter new];
    expectedGclid.name = @"gclid";
    expectedGclid.value = gclidValue;
    expectedGclid.timestamp = gclid.timestamp;
    expectedGclid.validityWindow = gclid.validityWindow;
    expectedGclid.isDeepLink = @(1);
    
    XCTAssertEqualObjects(gclid, expectedGclid);
}

- (void)testDefaultValidityWindowForParam {

    XCTAssertEqual(2592000, [utility defaultValidityWindowForParam:@"gbraid"]);
    XCTAssertEqual(0, [utility defaultValidityWindowForParam:@"gclid"]);
}

- (void)testSerializeToJson {
    
    NSDate *currentDate = [NSDate date];
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * params = [NSMutableDictionary new];
    
    BNCUrlQueryParameter *gbraidObj = [BNCUrlQueryParameter new];
    gbraidObj.name = @"gbraid";
    gbraidObj.value = gbraidValue;
    gbraidObj.timestamp = currentDate;
    gbraidObj.validityWindow = 2592000;
    gbraidObj.isDeepLink = @(1);
    params[@"gbraid"] = gbraidObj;
    
    BNCUrlQueryParameter *gclidObj = [BNCUrlQueryParameter new];
    gclidObj.name = @"gclid";
    gclidObj.value = gclidValue;
    gclidObj.timestamp = currentDate;
    gclidObj.validityWindow = 0;
    gclidObj.isDeepLink = @(1);
    params[@"gclid"] = gclidObj;
     
    NSMutableDictionary *json = [utility serializeToJson:params];
        
    NSDictionary *expectedJSON = @{
        @"gbraid": @{
            @"isDeepLink": @(1),
            @"name": @"gbraid",
            @"timestamp": currentDate,
            @"validityWindow": @(2592000),
            @"value": @"gbraid456"
        },
        @"gclid": @{
            @"isDeepLink": @(1),
            @"name": @"gclid",
            @"timestamp": currentDate,
            @"validityWindow": @(0),
            @"value": @"gclid123"
        }
    };
    
    XCTAssertEqualObjects(expectedJSON, json);
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * deserializedParams = [utility deserializeFromJson:json];
    XCTAssertEqualObjects(params, deserializedParams);
}

- (void)testDeserializeFromJson {
    NSDate *currentDate = [NSDate date];
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * params = [NSMutableDictionary new];
    
    BNCUrlQueryParameter *gbraidObj = [BNCUrlQueryParameter new];
    gbraidObj.name = @"gbraid";
    gbraidObj.value = gbraidValue;
    gbraidObj.timestamp = currentDate;
    gbraidObj.validityWindow = 2592000;
    gbraidObj.isDeepLink = @(1);
    params[@"gbraid"] = gbraidObj;
    
    BNCUrlQueryParameter *gclidObj = [BNCUrlQueryParameter new];
    gclidObj.name = @"gclid";
    gclidObj.value = gclidValue;
    gclidObj.timestamp = currentDate;
    gclidObj.validityWindow = 0;
    gclidObj.isDeepLink = @(1);
    params[@"gclid"] = gclidObj;

    NSDictionary *json = @{
        @"gbraid": @{
            @"isDeepLink": @(1),
            @"name": @"gbraid",
            @"timestamp": currentDate,
            @"validityWindow": @(2592000),
            @"value": @"gbraid456"
        },
        @"gclid": @{
            @"isDeepLink": @(1),
            @"name": @"gclid",
            @"timestamp": currentDate,
            @"validityWindow": @(0),
            @"value": @"gclid123"
        }
    };
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * deserializedParams = [utility deserializeFromJson:json];
    
    XCTAssertEqualObjects(deserializedParams, params);
}

@end

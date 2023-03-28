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

@property (nonatomic, strong, readwrite) BNCPreferenceHelper *prefHelper;
@property (nonatomic, strong, readwrite) BNCReferringURLUtility *utility;

@property (nonatomic, copy) NSString *gbraidValue;
@property (nonatomic, copy) NSString *gclidValue;

@property (nonatomic, copy) NSString *eventEndpoint;
@property (nonatomic, copy) NSString *openEndpoint;

@end

@implementation BNCReferringURLUtilityTests

- (void)setUp {
    self.prefHelper = [BNCPreferenceHelper sharedInstance];
    self.prefHelper.referringURLQueryParameters = nil;
    
    self.eventEndpoint = @"/v2/event";
    self.openEndpoint = @"/v1/open";
    
    self.gclidValue = @"gclid123";
    self.gbraidValue = @"gbraid456";
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.branch.io?test=456&gbraid=%@&gclid=%@", self.gbraidValue, self.gclidValue];
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.utility = [BNCReferringURLUtility new];
    [self.utility parseReferringURL:url];
}

- (NSMutableDictionary *)defaultGbraidDictionary {
    NSMutableDictionary *gbraidDict = [NSMutableDictionary dictionary];
    gbraidDict[@"isDeepLink"] = @(1);
    gbraidDict[@"name"] = @"gbraid";
    gbraidDict[@"validityWindow"] = @(2592000);
    gbraidDict[@"value"] = self.gbraidValue;
    return gbraidDict;
}

- (NSMutableDictionary *)defaultGclidDictionary {
    NSMutableDictionary *gclidDict = [NSMutableDictionary dictionary];
    gclidDict[@"isDeepLink"] = @(1);
    gclidDict[@"name"] = @"gclid";
    gclidDict[@"validityWindow"] = @(0);
    gclidDict[@"value"] = self.gclidValue;
    return gclidDict;
}

- (BNCUrlQueryParameter *)defaultGbraid {
    BNCUrlQueryParameter *expectedGbraid = [BNCUrlQueryParameter new];
    expectedGbraid.name = @"gbraid";
    expectedGbraid.value = self.gbraidValue;
    expectedGbraid.validityWindow = 2592000;
    expectedGbraid.isDeepLink = @(1);
    return expectedGbraid;
}

- (BNCUrlQueryParameter *)defaultGclid {
    BNCUrlQueryParameter *expectedGclid = [BNCUrlQueryParameter new];
    expectedGclid.name = @"gclid";
    expectedGclid.value = self.gclidValue;
    expectedGclid.validityWindow = 0;
    expectedGclid.isDeepLink = @(1);
    return expectedGclid;
}

- (void)testParseURL {
    NSMutableDictionary *savedParams = self.prefHelper.referringURLQueryParameters;
    
    // Remove the timestamp keys from savedParams for compare
    [savedParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *paramDict = (NSMutableDictionary *)obj;
        [paramDict removeObjectForKey:@"timestamp"];
    }];
    
    NSMutableDictionary *expectedParams = [NSMutableDictionary dictionary];
    expectedParams[@"gbraid"] = self.defaultGbraidDictionary;
    expectedParams[@"gclid"] = self.defaultGclidDictionary;
    
    XCTAssertEqualObjects(savedParams, expectedParams);
}

- (void)testGetEventURLQueryParams {

    NSDictionary *params = [self.utility getURLQueryParamsForRequest:self.eventEndpoint];
    NSDictionary *expectedParams = @{@"gbraid": self.gbraidValue,
                                       @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                       @"gclid": self.gclidValue};

    XCTAssertEqualObjects(params, expectedParams);
}

- (void)testGetOpenURLQueryParams {
    
    NSDictionary *params = [self.utility getURLQueryParamsForRequest:self.openEndpoint];
    NSDictionary *expectedParams = @{@"gbraid": self.gbraidValue,
                                     @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                     @"is_deeplink_gbraid": @YES,
                                     @"gclid": self.gclidValue};
    
    XCTAssertEqualObjects(params, expectedParams);
}

- (void)testAddGclidValueFor {
    NSString *eventGclidValue = [self.utility addGclidValueFor:self.eventEndpoint];
    XCTAssertEqualObjects(eventGclidValue, self.gclidValue);
    
    NSString *openGclidValue = [self.utility addGclidValueFor:self.openEndpoint];
    XCTAssertEqualObjects(openGclidValue, self.gclidValue);
}

- (void)testAddGbraidValuesFor {
    NSDictionary *eventGbraidValue = [self.utility addGbraidValuesFor:self.eventEndpoint];
    
    NSDictionary *expectedEventGraidValue = @{
        @"gbraid": self.gbraidValue,
        @"gbraid_timestamp": eventGbraidValue[@"gbraid_timestamp"]
    };
    
    XCTAssertEqualObjects(eventGbraidValue, expectedEventGraidValue);
    
    NSDictionary *expectedOpenGraidValue = @{
        @"gbraid": self.gbraidValue,
        @"gbraid_timestamp": eventGbraidValue[@"gbraid_timestamp"],
        @"is_deeplink_gbraid": @(1)
    };
    
    NSDictionary *openGbraidValue = [self.utility addGbraidValuesFor:self.openEndpoint];
    XCTAssertEqualObjects(openGbraidValue, expectedOpenGraidValue);
}

- (void)testIsSupportedQueryParameterForGbraid {
    NSString *gbraidParam = @"gbraid";
    XCTAssertTrue([self.utility isSupportedQueryParameter:gbraidParam]);
}

- (void)testIsSupportedQueryParameterForGclid {
    NSString *gclidParam = @"gclid";
    XCTAssertTrue([self.utility isSupportedQueryParameter:gclidParam]);
}

- (void)testIsSupportedQueryParameterForEmptyString {
    NSString *emptyStringParam = @"";
    XCTAssertFalse([self.utility isSupportedQueryParameter:emptyStringParam]);
}

- (void)testIsSupportedQueryParameterForSpecialCharacters {
    NSString *specialCharsParam = @"g!b@r#a$i^d&";
    XCTAssertFalse([self.utility isSupportedQueryParameter:specialCharsParam]);
}

- (void)testIsSupportedQueryParameterForSpaces {
    NSString *spacesParam = @" gclid ";
    XCTAssertFalse([self.utility isSupportedQueryParameter:spacesParam]);
}

- (void)testIsSupportedQueryParameterForMixedCase {
    NSString *mixedCaseParam = @"GcLiD";
    XCTAssertTrue([self.utility isSupportedQueryParameter:mixedCaseParam]);
}

- (void)testFindUrlQueryParam {
    BNCUrlQueryParameter *gbraid = [self.utility findUrlQueryParam:@"gbraid"];
    
    BNCUrlQueryParameter *expectedGbraid = self.defaultGbraid;
    expectedGbraid.timestamp = gbraid.timestamp;
    
    XCTAssertEqualObjects(gbraid, expectedGbraid);
    
    BNCUrlQueryParameter *gclid = [self.utility findUrlQueryParam:@"gclid"];
    
    BNCUrlQueryParameter *expectedGclid = self.defaultGclid;
    expectedGclid.timestamp = gclid.timestamp;
    
    XCTAssertEqualObjects(gclid, expectedGclid);
}

- (void)testFindUrlQueryParamForUnsupported {
    BNCUrlQueryParameter *unsupported = [self.utility findUrlQueryParam:@"unsupported"];
    XCTAssertNotNil(unsupported);
    XCTAssertEqualObjects(unsupported.name, @"unsupported");
    XCTAssertNil(unsupported.value);
    XCTAssertNil(unsupported.timestamp);
    XCTAssertEqual(unsupported.isDeepLink, 0);
    XCTAssertEqual(unsupported.validityWindow, 0);
}

- (void)testFindUrlQueryParamForSpecialCharacters {
    BNCUrlQueryParameter *specialChars = [self.utility findUrlQueryParam:@"g!b@r#a$i^d&"];
    XCTAssertNotNil(specialChars);
    XCTAssertEqualObjects(specialChars.name, @"g!b@r#a$i^d&");
    XCTAssertNil(specialChars.value);
    XCTAssertNil(specialChars.timestamp);
    XCTAssertEqual(specialChars.isDeepLink, 0);
    XCTAssertEqual(specialChars.validityWindow, 0);
}

- (void)testFindUrlQueryParamForSpaces {
    BNCUrlQueryParameter *spaces = [self.utility findUrlQueryParam:@" gbraid "];
    XCTAssertNotNil(spaces);
    XCTAssertEqualObjects(spaces.name, @" gbraid ");
    XCTAssertNil(spaces.value);
    XCTAssertNil(spaces.timestamp);
    XCTAssertEqual(spaces.isDeepLink, 0);
    XCTAssertEqual(spaces.validityWindow, 0);
}

- (void)testFindUrlQueryParamForNil {
    BNCUrlQueryParameter *nilParam = [self.utility findUrlQueryParam:nil];
    XCTAssertNotNil(nilParam);
    XCTAssertNil(nilParam.name);
    XCTAssertNil(nilParam.value);
    XCTAssertNil(nilParam.timestamp);
    XCTAssertEqual(nilParam.isDeepLink, 0);
    XCTAssertEqual(nilParam.validityWindow, 0);
}

- (void)testDefaultValidityWindowForParam {
    XCTAssertEqual(2592000, [self.utility defaultValidityWindowForParam:@"gbraid"]);
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:@"gclid"]);
}

- (void)testDefaultValidityWindowForParamForUnsupported {
    NSString *unsupportedParam = @"unsupported";
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:unsupportedParam]);
}

- (void)testDefaultValidityWindowForParamForSpecialCharacters {
    NSString *specialCharsParam = @"g!b@r#a$i^d&";
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:specialCharsParam]);
}

- (void)testDefaultValidityWindowForParamForSpaces {
    NSString *spacesParam = @" gbraid ";
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:spacesParam]);
}

- (void)testDefaultValidityWindowForParamForMixedCase {
    NSString *mixedCaseParam = @"GcLiD";
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:mixedCaseParam]);
}

- (void)testDefaultValidityWindowForParamForNil {
    XCTAssertEqual(0, [self.utility defaultValidityWindowForParam:nil]);
}

- (void)testSerializeToJson {
    
    NSDate *currentDate = [NSDate date];
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * params = [NSMutableDictionary new];
    
    BNCUrlQueryParameter *gbraidObj = self.defaultGbraid;
    gbraidObj.timestamp = currentDate;
    params[@"gbraid"] = gbraidObj;
    
    BNCUrlQueryParameter *gclidObj = self.defaultGclid;
    gclidObj.timestamp = currentDate;
    params[@"gclid"] = gclidObj;
     
    NSMutableDictionary *json = [self.utility serializeToJson:params];
        
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
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * deserializedParams = [self.utility deserializeFromJson:json];
    XCTAssertEqualObjects(params, deserializedParams);
}

- (void)testSerializeToJsonWithEmptyDictionary {
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *emptyParams = [NSMutableDictionary new];
    NSMutableDictionary *json = [self.utility serializeToJson:emptyParams];
    NSDictionary *expectedJSON = @{};
    XCTAssertEqualObjects(expectedJSON, json);
}

- (void)testDeserializeToEmptyDictionaryFromJson {
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *emptyParams = [NSMutableDictionary new];
    NSDictionary *json = @{};

    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *deserializedParams = [self.utility deserializeFromJson:json];
    XCTAssertEqualObjects(emptyParams, deserializedParams);
}

- (void)testSerializeToJsonWithSpecialCharactersAndNilValue {
    NSDate *currentDate = [NSDate date];
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *params = [NSMutableDictionary new];
    
    BNCUrlQueryParameter *specialCharsObj = [BNCUrlQueryParameter new];
    specialCharsObj.name = @"g!b@r#a$i^d&";
    specialCharsObj.timestamp = currentDate;
    specialCharsObj.validityWindow = 0;
    specialCharsObj.isDeepLink = NO;
    specialCharsObj.value = @"";
    params[@"g!b@r#a$i^d&"] = specialCharsObj;

    NSMutableDictionary *json = [self.utility serializeToJson:params];
    
    NSDictionary *expectedJSON = @{
        @"g!b@r#a$i^d&": @{
            @"isDeepLink": @(0),
            @"name": @"g!b@r#a$i^d&",
            @"timestamp": currentDate,
            @"validityWindow": @(0),
            @"value": @""
        }
    };
    
    XCTAssertEqualObjects(expectedJSON, json);
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *deserializedParams = [self.utility deserializeFromJson:json];
    XCTAssertEqualObjects(params, deserializedParams);
}

- (void)testDeserializeFromJson {
    NSDate *currentDate = [NSDate date];
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * params = [NSMutableDictionary new];
    
    BNCUrlQueryParameter *gbraidObj = self.defaultGbraid;
    gbraidObj.timestamp = currentDate;
    params[@"gbraid"] = gbraidObj;
    
    BNCUrlQueryParameter *gclidObj = self.defaultGclid;
    gclidObj.timestamp = currentDate;
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
    
    NSMutableDictionary<NSString *, BNCUrlQueryParameter *> * deserializedParams = [self.utility deserializeFromJson:json];
    
    XCTAssertEqualObjects(deserializedParams, params);
}

@end

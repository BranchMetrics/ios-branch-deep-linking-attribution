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

@interface BNCReferringURLUtility(Test)

- (NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)deserializeFromJson:(NSDictionary *)json;
- (NSMutableDictionary *)serializeToJson:(NSMutableDictionary<NSString *, BNCUrlQueryParameter *> *)urlQueryParameters;
- (NSTimeInterval)defaultValidityWindowForParam:(NSString *)paramName;
- (BNCUrlQueryParameter *)findUrlQueryParam:(NSString *)paramName;
- (BOOL)isSupportedQueryParameter:(NSString *)param;
- (NSDictionary *)addGbraidValuesFor:(NSString *)endpoint
- (NSString *)addGclidValueFor:(NSString *)endpoint

@end

@interface BNCReferringURLUtilityTests : XCTestCase

@end

@implementation BNCReferringURLUtilityTests

//- (void)setUp {
//    // Put setup code here. This method is called before the invocation of each test method in the class.
//}
//
//- (void)tearDown {
//    // Put teardown code here. This method is called after the invocation of each test method in the class.
//}

- (void)testParseURL {
    NSURL *url = [NSURL URLWithString:@"https://www.branch.io?gbraid=abc123&test=456&gclid=123456789abc"];
    
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];
    
    //TODO: Check that gbraid and gclid exist
    
}

-(void)testGetEventURLQueryParams {
    NSString *endpoint = @"/v2/event";
    NSURL *url = [NSURL URLWithString:@"https://www.branch.io?gbraid=abc123&test=456&gclid=123456789abc"];
    
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];
    
    NSDictionary *params = [utility getURLQueryParamsForRequest:endpoint];
    NSDictionary *expectedParams = @{@"gbraid": @"abc123",
                                       @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                       @"gclid": @"123456789abc"};
    NSLog(@"Event Params: %@", params);
    NSLog(@"Expected Params: %@", expectedParams);

    XCTAssertEqualObjects(params, expectedParams);
}

-(void)testGetOpenURLQueryParams {
    NSString *endpoint = @"/v1/open";
    
    NSURL *url = [NSURL URLWithString:@"https://www.branch.io?gbraid=abc123&test=456&gclid=123456789abc"];
    
    BNCReferringURLUtility *utility = [BNCReferringURLUtility new];
    [utility parseReferringURL:url];
    
    NSDictionary *params = [utility getURLQueryParamsForRequest:endpoint];
    NSDictionary *expectedParams = @{@"gbraid": @"abc123",
                                     @"gbraid_timestamp": params[@"gbraid_timestamp"],
                                     @"is_deeplink_gbraid": @YES,
                                     @"gclid": @"123456789abc"};
    
    NSLog(@"Open Params: %@", params);
    NSLog(@"Expected Params: %@", expectedParams);

    XCTAssertEqualObjects(params, expectedParams);
}

@end

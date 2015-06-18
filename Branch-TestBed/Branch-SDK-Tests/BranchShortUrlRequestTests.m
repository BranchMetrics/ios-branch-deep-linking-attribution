//
//  BranchShortUrlRequestTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/12/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//
#import "BranchTest.h"
#import "BranchShortUrlRequest.h"
#import "BranchConstants.h"
#import "BNCPreferenceHelper.h"
#import <OCMock/OCMock.h>

@interface BranchShortUrlRequestTests : BranchTest

@end

@implementation BranchShortUrlRequestTests

- (void)testRequestBody {
    NSArray * const TAGS = @[];
    NSString * const ALIAS = @"foo-alias";
    BranchLinkType const LINK_TYPE = BranchLinkTypeOneTimeUse;
    NSInteger const DURATION = 1;
    NSString * const CHANNEL = @"foo-channel";
    NSString * const FEATURE = @"foo-feature";
    NSString * const STAGE = @"foo-stage";
    NSDictionary * const PARAMS = @{};
    BNCLinkData * const LINK_DATA = [[BNCLinkData alloc] init];
    BNCLinkCache * const LINK_CACHE = [[BNCLinkCache alloc] init];

    [LINK_DATA setupType:LINK_TYPE];
    [LINK_DATA setupTags:TAGS];
    [LINK_DATA setupChannel:CHANNEL];
    [LINK_DATA setupFeature:FEATURE];
    [LINK_DATA setupStage:STAGE];
    [LINK_DATA setupAlias:ALIAS];
    [LINK_DATA setupMatchDuration:DURATION];
    [LINK_DATA setupParams:PARAMS];
    
    NSDictionary * const expectedParams = @{
        BRANCH_REQUEST_KEY_SESSION_ID: [BNCPreferenceHelper getSessionID],
        BRANCH_REQUEST_KEY_BRANCH_IDENTITY: [BNCPreferenceHelper getIdentityID],
        BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID: [BNCPreferenceHelper getDeviceFingerprintID],
        BRANCH_REQUEST_KEY_URL_ALIAS: ALIAS,
        BRANCH_REQUEST_KEY_URL_CHANNEL: CHANNEL,
        BRANCH_REQUEST_KEY_URL_DATA: PARAMS,
        BRANCH_REQUEST_KEY_URL_DURATION: @(DURATION),
        BRANCH_REQUEST_KEY_URL_FEATURE: FEATURE,
        BRANCH_REQUEST_KEY_URL_LINK_TYPE: @(LINK_TYPE),
        BRANCH_REQUEST_KEY_URL_SOURCE: @"ios",
        BRANCH_REQUEST_KEY_URL_STAGE: STAGE,
        BRANCH_REQUEST_KEY_URL_TAGS: TAGS
    };
    
    BranchShortUrlRequest *request = [[BranchShortUrlRequest alloc] initWithTags:TAGS alias:ALIAS type:LINK_TYPE matchDuration:DURATION channel:CHANNEL feature:FEATURE stage:STAGE params:PARAMS linkData:LINK_DATA linkCache:LINK_CACHE callback:NULL];
    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect] postRequest:expectedParams url:[OCMArg any] key:[OCMArg any] callback:[OCMArg any]];
    
    [request makeRequest:serverInterfaceMock key:nil callback:NULL];
    
    [serverInterfaceMock verify];
}

- (void)testBasicSuccess {
}

@end

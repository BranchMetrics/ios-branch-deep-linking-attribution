//
//  BNCLinkDataTests.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/15/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCLinkData.h"

@interface BNCLinkDataTests : BNCTestCase
@end

@implementation BNCLinkDataTests

- (void)testBasicObjectHash {
    BNCLinkData *a = [[BNCLinkData alloc] init];
    BNCLinkData *b = [[BNCLinkData alloc] init];
    
    XCTAssertEqual([a hash], [b hash]);
}

- (void)testObjectHashWithSameValuesForKeys {
    NSArray * const TAGS = @[ @"foo-tag" ];
    NSString * const ALIAS = @"foo-alias";
    BranchLinkType const LINK_TYPE = BranchLinkTypeOneTimeUse;
    NSString * const CHANNEL = @"foo-channel";
    NSString * const FEATURE = @"foo-feature";
    NSString * const STAGE = @"foo-stage";
    NSDictionary * const PARAMS = @{ @"foo-key": @"foo-value" };
    NSInteger const DURATION = 1;
    NSString * const IGNORE_UA = @"foo-ua";

    BNCLinkData *a = [[BNCLinkData alloc] init];
    [a setupTags:TAGS];
    [a setupAlias:ALIAS];
    [a setupType:LINK_TYPE];
    [a setupChannel:CHANNEL];
    [a setupFeature:FEATURE];
    [a setupStage:STAGE];
    [a setupParams:PARAMS];
    [a setupMatchDuration:DURATION];
    [a setupIgnoreUAString:IGNORE_UA];

    BNCLinkData *b = [[BNCLinkData alloc] init];
    [b setupTags:TAGS];
    [b setupAlias:ALIAS];
    [b setupType:LINK_TYPE];
    [b setupChannel:CHANNEL];
    [b setupFeature:FEATURE];
    [b setupStage:STAGE];
    [b setupParams:PARAMS];
    [b setupMatchDuration:DURATION];
    [b setupIgnoreUAString:IGNORE_UA];

    XCTAssertEqual([a hash], [b hash]);
}

- (void)testObjectHashWithDifferentValuesForSameKeys {
    BNCLinkData *a = [[BNCLinkData alloc] init];
    [a setupTags:@[ @"foo-tags" ]];
    [a setupAlias:@"foo-alias"];
    [a setupType:BranchLinkTypeOneTimeUse];
    [a setupChannel:@"foo-channel"];
    [a setupFeature:@"foo-feature"];
    [a setupStage:@"foo-stage"];
    [a setupParams:@{ @"foo-key": @"foo-value" }];
    [a setupMatchDuration:1];
    [a setupIgnoreUAString:@"foo-ua"];
    
    BNCLinkData *b = [[BNCLinkData alloc] init];
    [b setupTags:@[ @"bar-tag" ]];
    [b setupAlias:@"bar-alias"];
    [b setupType:BranchLinkTypeUnlimitedUse];
    [b setupChannel:@"bar-channel"];
    [b setupFeature:@"bar-feature"];
    [b setupStage:@"bar-stage"];
    [b setupParams:@{ @"bar-key": @"bar-value" }];
    [b setupMatchDuration:2];
    [b setupIgnoreUAString:@"bar-ua"];
    
    XCTAssertNotEqual([a hash], [b hash]);
}

- (void)testObjectHashWithDifferentCasedValues {
    BNCLinkData *a = [[BNCLinkData alloc] init];
    [a setupAlias:@"foo-alias"];
    BNCLinkData *b = [[BNCLinkData alloc] init];
    [b setupAlias:@"FOO-ALIAS"];
    
    XCTAssertNotEqual([a hash], [b hash]);
}

@end

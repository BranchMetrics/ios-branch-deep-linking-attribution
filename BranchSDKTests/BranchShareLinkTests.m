//
//  BranchShareLinkTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 5/5/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BranchShareLink.h"
#import "BranchLinkProperties.h"
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BNCPreferenceHelper.h"

static NSString * const kTestBranchKey = @"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB";

@interface Branch (BranchShareLinkTest)
+ (void)resetInitializationGuardForTesting;
@end

@interface BranchShareLinkTests : XCTestCase
@property (nonatomic, copy) NSString *savedUserUrl;
@end

@implementation BranchShareLinkTests

- (void)setUp {
    [super setUp];
    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[[BranchConfiguration alloc] initWithKey:kTestBranchKey]];
    self.savedUserUrl = [BNCPreferenceHelper sharedInstance].userUrl;
    // The placeholder is an app.link long URL, whose base depends on userUrl. Pin the no-userUrl
    // branch so these assertions do not depend on whether an earlier test class saw an open response.
    [BNCPreferenceHelper sharedInstance].userUrl = nil;
}

- (void)tearDown {
    [BNCPreferenceHelper sharedInstance].userUrl = self.savedUserUrl;
    [super tearDown];
}

#pragma mark - Placeholder long URL

// -activityItems builds the placeholder share URL offline, through -buildLongURL. This is the one
// user-visible consequence of the Decision-2 fix: -getLongAppLinkURLWithParams:andChannel:… took a
// channel and dropped it before assembling the URL, so this placeholder never carried one. It does
// now.
- (void)testPlaceholderURLNowCarriesTheChannel {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    lp.channel = @"sms";
    lp.feature = @"share";
    lp.stage = @"stage1";
    lp.tags = @[@"tag1"];
    lp.alias = @"alias1";

    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    [bsl activityItems];

    // The trailing data= is a base64 blob of the BUO's server parameters, so pin everything up to it
    // rather than the whole string: base URL, parameter order, and the presence of channel=.
    NSString *expectedPrefix = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&alias=alias1&channel=sms&feature=share&stage=stage1"
        @"&source=ios&data=", kTestBranchKey];

    XCTAssertTrue([bsl.shareURL.absoluteString hasPrefix:expectedPrefix],
                  @"expected prefix %@, got %@", expectedPrefix, bsl.shareURL.absoluteString);
}

// A default builder emits neither type= nor matchDuration=, and a long URL never carries a campaign.
- (void)testPlaceholderURLOmitsTypeMatchDurationAndCampaign {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    lp.campaign = @"campaign1";

    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    [bsl activityItems];

    NSString *url = bsl.shareURL.absoluteString;
    XCTAssertFalse([url containsString:@"campaign"]);
    XCTAssertFalse([url containsString:@"type="]);
    XCTAssertFalse([url containsString:@"matchDuration="]);
}

// An explicit placeholderURL short-circuits link generation entirely.
- (void)testExplicitPlaceholderURLIsUsedVerbatim {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    lp.channel = @"sms";

    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    bsl.placeholderURL = [NSURL URLWithString:@"https://example.com/placeholder"];
    [bsl activityItems];

    XCTAssertEqualObjects(bsl.shareURL.absoluteString, @"https://example.com/placeholder");
}

- (void)testAddLPLinkMetadata {
    BranchUniversalObject *buo = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:@"test/001"];
    BranchLinkProperties *lp = [[BranchLinkProperties alloc] init];
    
    BranchShareLink *bsl = [[BranchShareLink alloc] initWithUniversalObject:buo linkProperties:lp];
    
    if (@available(iOS 13.0, macCatalyst 13.1, *)) {
        NSURL *imageURL = [NSURL URLWithString:@"https://cdn.branch.io/branch-assets/1598575682753-og_image.png"];
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
        UIImage *iconImage = [UIImage imageWithData:imageData];
        
        [bsl addLPLinkMetadata:@"Test Preview Title" icon:iconImage];
        XCTAssertNotNil([bsl lpMetaData]);
    } else {
        XCTAssertTrue(true);
    }
}

@end

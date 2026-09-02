//
//  BranchActivityItemTests.m
//  Branch-SDK-Tests
//
//  Created by Nipun Singh on 9/21/23.
//  Copyright © 2023 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BranchActivityItemProvider.h"
#import "BranchLinkBuilder.h"
#import "BranchLinkBuilder+Private.h"
#import "BNCLinkCache.h"
#import "BNCPreferenceHelper.h"
// Exposes the shared instance's linkCache, which is the seam these tests use to observe the options
// BranchActivityItemProvider hands the builder without reaching the network.
#import "Branch+LinkGeneration.h"

#if !TARGET_OS_TV

static NSString * const kTestBranchKey = @"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB";

// Base64 of the JSON for @{@"key": @"value"}.
static NSString * const kEncodedKeyValueParams = @"eyJrZXkiOiJ2YWx1ZSJ9";

@interface Branch (BranchActivityItemTest)
+ (void)resetInitializationGuardForTesting;
@end

// Overrides every per-channel hook, so a test can prove the provider reads them rather than its own
// stored properties.
@interface BNCOverridingActivityItemDelegate : NSObject <BranchActivityItemProviderDelegate>
@end

@implementation BNCOverridingActivityItemDelegate

- (NSDictionary *)activityItemParamsForChannel:(NSString *)channel { return @{@"key": @"value"}; }
- (NSArray *)activityItemTagsForChannel:(NSString *)channel { return @[@"delegateTag"]; }
- (NSString *)activityItemFeatureForChannel:(NSString *)channel { return @"delegateFeature"; }
- (NSString *)activityItemStageForChannel:(NSString *)channel { return @"delegateStage"; }
- (NSString *)activityItemCampaignForChannel:(NSString *)channel { return @"delegateCampaign"; }
- (NSString *)activityItemAliasForChannel:(NSString *)channel { return @"delegateAlias"; }
- (NSString *)activityItemOverrideChannelForChannel:(NSString *)channel { return @"delegateChannel"; }

@end

@interface BranchActivityItemTests: XCTestCase
@property (nonatomic, copy) NSString *savedUserUrl;
@end

@implementation BranchActivityItemTests

- (void)setUp {
    [super setUp];
    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[[BranchConfiguration alloc] initWithKey:kTestBranchKey]];
    self.savedUserUrl = [BNCPreferenceHelper sharedInstance].userUrl;
    // The long-URL assertions below pin the default domain, which userUrl does not affect, but the
    // app-link path shares this helper -- snapshot it so nothing leaks between test classes.
    [BNCPreferenceHelper sharedInstance].userUrl = nil;
}

- (void)tearDown {
    [BNCPreferenceHelper sharedInstance].userUrl = self.savedUserUrl;
    [super tearDown];
}

#pragma mark - Placeholder long URL

// The placeholder URL is built offline in -initWithParams:… , so this asserts the exact string. It
// is the one long-URL call site in the SDK that passes no channel, which is why it is the only one
// whose output is unchanged by the builder's channel= fix.
- (void)testPlaceholderIsTheExactLongURLAndCarriesNoChannel {
    BranchActivityItemProvider *provider =
        [[BranchActivityItemProvider alloc] initWithParams:@{@"key": @"value"}
                                                      tags:@[@"tag1", @"tag2"]
                                                   feature:@"feature1"
                                                     stage:@"stage1"
                                                  campaign:@"campaign1"
                                                     alias:@"alias1"
                                                  delegate:nil];

    NSString *expected = [NSString stringWithFormat:
        @"https://bnc.lt/a/%@?tags=tag1&tags=tag2&alias=alias1&feature=feature1&stage=stage1"
        @"&source=ios&data=%@", kTestBranchKey, kEncodedKeyValueParams];

    NSURL *placeholder = (NSURL *)[provider placeholderItem];
    XCTAssertEqualObjects(placeholder.absoluteString, expected);
    XCTAssertFalse([placeholder.absoluteString containsString:@"channel="],
                   @"this call site passes no channel, so its output must not change under the "
                   @"builder's channel= fix");
}

// A long URL has no campaign parameter. The provider stores campaign for the short-link paths, so
// pin that it does not leak into the placeholder.
- (void)testPlaceholderOmitsCampaign {
    BranchActivityItemProvider *provider =
        [[BranchActivityItemProvider alloc] initWithParams:@{@"key": @"value"}
                                                      tags:nil
                                                   feature:nil
                                                     stage:nil
                                                  campaign:@"campaign1"
                                                     alias:nil
                                                  delegate:nil];

    XCTAssertFalse([((NSURL *)[provider placeholderItem]).absoluteString containsString:@"campaign"]);
}

#pragma mark - Short link option assembly

// Seeds the shared link cache with `url` under exactly the options the provider is expected to hand
// the builder. -fetchShortURL reads that cache before going to the network, so a subsequent -item
// returning `url` proves the provider assembled those options and no others: BNCLinkCache keys on
// -[BNCLinkData hash], so one wrong option is a different key and a miss.
- (void)seedSharedLinkCacheWithURL:(NSString *)url
                            params:(NSDictionary *)params
                              tags:(NSArray *)tags
                             alias:(NSString *)alias
                           channel:(NSString *)channel
                           feature:(NSString *)feature
                             stage:(NSString *)stage
                          campaign:(NSString *)campaign {

    BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
    builder.params = params;
    builder.tags = tags;
    builder.alias = alias;
    builder.channel = channel;
    builder.feature = feature;
    builder.stage = stage;
    builder.campaign = campaign;

    [[Branch sharedInstance].linkCache setObject:url
                                          forKey:[builder linkDataWithIgnoreUAString:nil]];
}

// With no activityType set, -humanReadableChannelWithActivityType: yields a nil channel, so -item
// takes neither the scraper nor the mail branch and falls through to the plain short-link path.
- (void)testItemUsesTheProvidersOwnOptions {
    NSString *alias = [[NSUUID UUID] UUIDString];
    NSString *cached = @"https://example.app.link/from-cache";

    [self seedSharedLinkCacheWithURL:cached
                              params:@{@"key": @"value"}
                                tags:@[@"tag1"]
                               alias:alias
                             channel:nil
                             feature:@"feature1"
                               stage:@"stage1"
                            campaign:@"campaign1"];

    BranchActivityItemProvider *provider =
        [[BranchActivityItemProvider alloc] initWithParams:@{@"key": @"value"}
                                                      tags:@[@"tag1"]
                                                   feature:@"feature1"
                                                     stage:@"stage1"
                                                  campaign:@"campaign1"
                                                     alias:alias
                                                  delegate:nil];

    NSURL *item = (NSURL *)[provider item];
    XCTAssertEqualObjects(item.absoluteString, cached,
                          @"a cache miss here means the provider handed the builder different "
                          @"options than the ones it was constructed with");
}

// Every option is read through a -somethingForChannel: hook that consults the delegate first, and
// the channel itself can be overridden after the fact. Pin that the builder gets the delegate's
// values, not the provider's stored ones.
- (void)testItemUsesDelegateOverridesForEveryOption {
    NSString *cached = @"https://example.app.link/from-delegate";

    [self seedSharedLinkCacheWithURL:cached
                              params:@{@"key": @"value"}
                                tags:@[@"delegateTag"]
                               alias:@"delegateAlias"
                             channel:@"delegateChannel"
                             feature:@"delegateFeature"
                               stage:@"delegateStage"
                            campaign:@"delegateCampaign"];

    // BranchActivityItemProvider holds its delegate weakly, so it must outlive the -item call --
    // passing the alloc/init inline lets ARC release it first and the provider silently falls back
    // to its own stored options.
    BNCOverridingActivityItemDelegate *delegate = [[BNCOverridingActivityItemDelegate alloc] init];

    BranchActivityItemProvider *provider =
        [[BranchActivityItemProvider alloc] initWithParams:@{@"ignored": @"by-delegate"}
                                                      tags:@[@"providerTag"]
                                                   feature:@"providerFeature"
                                                     stage:@"providerStage"
                                                  campaign:@"providerCampaign"
                                                     alias:@"providerAlias"
                                                  delegate:delegate];

    XCTAssertEqualObjects(((NSURL *)[provider item]).absoluteString, cached);
    XCTAssertNotNil(delegate, @"keep the delegate alive across -item");
}

@end

#endif

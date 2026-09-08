//
//  BranchLinkBuilder.m
//  BranchSDK
//
//  Created by Brandon Boothe on 8/31/26.
//

#import "BranchLinkBuilder.h"
#import "BranchLinkBuilder+Private.h"
#import "Branch+LinkGeneration.h"
#import "BNCConfig.h"
#import "BNCEncodingUtils.h"
#import "BNCLinkCache.h"
#import "BNCPreferenceHelper.h"
#import "BNCServerResponse.h"
#import "BranchLogger.h"
#import "BranchShortUrlRequest.h"
#import "BranchShortUrlSyncRequest.h"
#import "BranchSpotlightUrlRequest.h"

@interface BranchLinkBuilder ()

// nil means "resolve +[Branch sharedInstance] on each read of self.branch". See
// BranchLinkBuilder+Private.h for why this is not resolved in -init.
@property (nonatomic, strong, nullable) Branch *injectedBranch;

@end

@implementation BranchLinkBuilder

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithBranch:nil];
}

- (instancetype)initWithBranch:(Branch *)branch {
    self = [super init];
    if (!self) return self;

    _injectedBranch = branch;

    // Link content
    _params = nil;
    _tags = nil;
    _alias = nil;
    _channel = nil;
    _feature = nil;
    _stage = nil;
    _campaign = nil;

    // Link behavior
    _matchDuration = 0;
    _linkType = BranchLinkTypeUnlimitedUse;

    // Terminal-specific options
    _ignoreUAString = nil;
    _useAppLinkDomain = NO;

    return self;
}

- (Branch *)branch {
    return self.injectedBranch ?: [Branch sharedInstance];
}

#pragma mark - Terminals

- (NSString *)fetchShortURL {
    [self warnAboutOptionsUnusedBy:@"fetchShortURL" ignoreUAString:NO useAppLinkDomain:YES];

    Branch *branch = self.branch;
    BNCLinkData *linkData = [self linkDataWithIgnoreUAString:self.ignoreUAString];

    // An ignoreUAString means the caller wants a link that will not be counted as clicked by a
    // preview scrape, so we always go to the server for a fresh one rather than serving a cached
    // ordinary link.
    if (!self.ignoreUAString && [branch.linkCache objectForKey:linkData]) {
        [[BranchLogger shared] logVerbose:@"Returning cached Branch Link" error:nil];
        return [branch.linkCache objectForKey:linkData];
    }

    BranchShortUrlSyncRequest *req =
        [[BranchShortUrlSyncRequest alloc] initWithTags:self.tags
                                                  alias:self.alias
                                                   type:self.linkType
                                          matchDuration:self.matchDuration
                                                channel:self.channel
                                                feature:self.feature
                                                  stage:self.stage
                                               campaign:self.campaign
                                                 params:self.params
                                               linkData:linkData
                                              linkCache:branch.linkCache];

    [[BranchLogger shared] logVerbose:@"Requesting Branch Link synchronously" error:nil];
    BNCServerResponse *serverResponse = [req makeRequest:branch.serverInterface key:[Branch branchKey]];

    // -processResponse: caches on a 200. Nothing is cached here, so the long-URL fallback it
    // returns on a non-200 does not displace the short link a later call can still fetch.
    return [req processResponse:serverResponse];
}

- (void)fetchShortURLWithCallback:(callbackWithUrl)callback {
    [self warnAboutOptionsUnusedBy:@"fetchShortURLWithCallback:" ignoreUAString:YES useAppLinkDomain:YES];

    Branch *branch = self.branch;

    // Snapshot every option *before* dispatching.
    //
    // The async path has no ignoreUAString option: the funnel hardcoded nil here, and a link whose
    // click should not be counted is only ever requested through the blocking terminal.
    BNCLinkData *linkData = [self linkDataWithIgnoreUAString:nil];
    NSArray *tags = self.tags;
    NSString *alias = self.alias;
    BranchLinkType linkType = self.linkType;
    NSUInteger matchDuration = self.matchDuration;
    NSString *channel = self.channel;
    NSString *feature = self.feature;
    NSString *stage = self.stage;
    NSString *campaign = self.campaign;
    NSDictionary *params = self.params;

    // The body runs on the isolation queue, as the funnel did -- reading and writing the link cache
    // off the caller's thread.
    dispatch_async(branch.isolationQueue, ^{
        NSString *cachedURL = [branch.linkCache objectForKey:linkData];
        if (cachedURL) {
            if (callback) {
                // Hop to main explicitly. On a cache miss this is BranchShortUrlRequest's job, but
                // on a hit nothing else would, and callers expect one consistent queue.
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(cachedURL, nil);
                });
            }
            return;
        }

        BranchShortUrlRequest *req =
            [[BranchShortUrlRequest alloc] initWithTags:tags
                                                  alias:alias
                                                   type:linkType
                                          matchDuration:matchDuration
                                                channel:channel
                                                feature:feature
                                                  stage:stage
                                               campaign:campaign
                                                 params:params
                                               linkData:linkData
                                              linkCache:branch.linkCache
                                               callback:callback];
        [branch.requestQueue enqueue:req];
    });
}

- (NSString *)buildLongURL {
    [self warnAboutOptionsUnusedBy:@"buildLongURL" ignoreUAString:YES useAppLinkDomain:NO];

    NSString *branchKey = [Branch branchKey];
    if (!branchKey) {
        [[BranchLogger shared] logError:@"Cannot build a long URL without a Branch key." error:nil];
        return nil;
    }

    return [self longUrlWithBaseUrl:[self longUrlBaseUrlWithBranchKey:branchKey]];
}

- (void)fetchSpotlightURLWithCallback:(callbackWithParams)callback {
    [self warnAboutOptionsUnusedBy:@"fetchSpotlightURLWithCallback:" ignoreUAString:YES useAppLinkDomain:YES];
    [self warnAboutLinkContentUnusedBySpotlight];

    Branch *branch = self.branch;

    NSDictionary *params = self.params;

    dispatch_async(branch.isolationQueue, ^{
        BranchSpotlightUrlRequest *req = [[BranchSpotlightUrlRequest alloc] initWithParams:params
                                                                                  callback:callback];
        [branch.requestQueue enqueue:req];
    });
}

#pragma mark - Link data

// Ports -prepareLinkDataFor:… . BNCLinkData's -isEqual:/-hash derive from the dictionary these ten
// calls build, and that dictionary is the BNCLinkCache key, so the set of calls must stay exactly
// as it is or previously cached links stop being found.

- (BNCLinkData *)linkDataWithIgnoreUAString:(NSString *)ignoreUAString {
    BNCLinkData *post = [[BNCLinkData alloc] init];

    [post setupType:self.linkType];
    [post setupTags:self.tags];
    [post setupChannel:self.channel];
    [post setupFeature:self.feature];
    [post setupStage:self.stage];
    [post setupCampaign:self.campaign];
    [post setupAlias:self.alias];
    [post setupMatchDuration:self.matchDuration];
    [post setupIgnoreUAString:ignoreUAString];
    [post setupParams:self.params];

    return post;
}

#pragma mark - Long URL assembly

- (NSString *)longUrlBaseUrlWithBranchKey:(NSString *)branchKey {
    if (!self.useAppLinkDomain) {
        return [NSString stringWithFormat:@"%@/a/%@", BNC_LINK_URL, branchKey];
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    if (preferenceHelper.userUrl) {
        NSString *fullUserUrl = [preferenceHelper sanitizedMutableBaseURL:preferenceHelper.userUrl];
        return [fullUserUrl componentsSeparatedByString:@"?"].firstObject;
    }
    return [NSString stringWithFormat:@"%@/a/%@?", BNC_LINK_URL, branchKey];
}

// Query-parameter order is fixed and pinned by tests: tags (repeated) -> alias -> channel ->
// feature -> stage -> type -> matchDuration -> source=ios&data=<base64>.
- (NSString *)longUrlWithBaseUrl:(NSString *)baseUrl {
    NSMutableString *longUrl = [[BNCPreferenceHelper sharedInstance] sanitizedMutableBaseURL:baseUrl];

    for (NSString *tag in self.tags) {
        [longUrl appendFormat:@"tags=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:tag]];
    }

    if ([self.alias length]) {
        [longUrl appendFormat:@"alias=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:self.alias]];
    }

    if ([self.channel length]) {
        [longUrl appendFormat:@"channel=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:self.channel]];
    }

    if ([self.feature length]) {
        [longUrl appendFormat:@"feature=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:self.feature]];
    }

    if ([self.stage length]) {
        [longUrl appendFormat:@"stage=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:self.stage]];
    }

    // Truthiness guards, not nil checks: BranchLinkTypeUnlimitedUse is 0 and a matchDuration of 0
    // means "server default", so a default builder emits neither parameter.
    if (self.linkType) {
        [longUrl appendFormat:@"type=%ld&", (long)self.linkType];
    }
    if (self.matchDuration) {
        [longUrl appendFormat:@"matchDuration=%ld&", (long)self.matchDuration];
    }

    // The base64 alphabet includes "+", which a server decodes as a space, so the encoded params
    // have to be percent-encoded before they go into the query.
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:self.params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", [BNCEncodingUtils urlEncodedString:base64EncodedParams]];

    return longUrl;
}

#pragma mark - Terminal-specific option warnings

- (void)warnAboutOptionsUnusedBy:(NSString *)terminal
                  ignoreUAString:(BOOL)ignoreUAStringIsUnused
                useAppLinkDomain:(BOOL)useAppLinkDomainIsUnused {

    if (ignoreUAStringIsUnused && self.ignoreUAString) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:
            @"ignoreUAString is set but does not apply to -%@; it is ignored. It applies to "
            @"-fetchShortURL only.", terminal] error:nil];
    }

    if (useAppLinkDomainIsUnused && self.useAppLinkDomain) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:
            @"useAppLinkDomain is set but does not apply to -%@; it is ignored. It applies to "
            @"-buildLongURL only.", terminal] error:nil];
    }
}

- (void)warnAboutLinkContentUnusedBySpotlight {
    NSMutableArray<NSString *> *ignored = [NSMutableArray array];

    if (self.tags.count) [ignored addObject:@"tags"];
    if (self.alias.length) [ignored addObject:@"alias"];
    if (self.channel.length) [ignored addObject:@"channel"];
    if (self.feature.length) [ignored addObject:@"feature"];
    if (self.stage.length) [ignored addObject:@"stage"];
    if (self.campaign.length) [ignored addObject:@"campaign"];
    if (self.linkType) [ignored addObject:@"linkType"];
    if (self.matchDuration) [ignored addObject:@"matchDuration"];

    if (!ignored.count) return;

    [[BranchLogger shared] logWarning:[NSString stringWithFormat:
        @"-fetchSpotlightURLWithCallback: reads params only; %@ %@ set but ignored. A Spotlight link "
        @"is always created with a channel of \"spotlight\".",
        [ignored componentsJoinedByString:@", "],
        ignored.count == 1 ? @"is" : @"are"] error:nil];
}

@end

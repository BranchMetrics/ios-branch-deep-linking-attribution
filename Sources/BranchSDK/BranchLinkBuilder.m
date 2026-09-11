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
#import "NSError+Branch.h"
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

    return self;
}

- (Branch *)branch {
    return self.injectedBranch ?: [Branch sharedInstance];
}

// Resolves the Branch instance the terminals send through, logging a BNCInitError when the SDK has
// not been initialized. Terminals call this rather than reading self.branch, which is nil until
// +[Branch initialize:] has run and is not safe to pass to dispatch_async.
//
// @param terminal Name of the calling terminal, used in the logged message.
// @param error On return, the BNCInitError to hand to the caller's callback. May be NULL.
// @return The Branch instance, or nil if the SDK has not been initialized.
- (Branch *)resolvedBranchForTerminal:(NSString *)terminal error:(NSError **)error {
    Branch *branch = self.branch;
    if (branch) {
        return branch;
    }

    NSString *message = [NSString stringWithFormat:
        @"-[BranchLinkBuilder %@] requires +[Branch initialize:] to have run. Dropping the request.",
        terminal];
    NSError *initError = [NSError branchErrorWithCode:BNCInitError localizedMessage:message];
    [[BranchLogger shared] logError:message error:initError];
    if (error) {
        *error = initError;
    }
    return nil;
}

#pragma mark - Terminals

- (NSString *)getShortURLWithLinkProperties:(BranchLinkProperties *)linkProperties {
    return [self getShortURLWithLinkProperties:linkProperties ignoreUAString:nil];
}

- (NSString *)getShortURLWithLinkProperties:(BranchLinkProperties *)linkProperties
                             ignoreUAString:(NSString *)ignoreUAString {

    Branch *branch = [self resolvedBranchForTerminal:@"getShortURLWithLinkProperties:ignoreUAString:"
                                               error:NULL];
    if (!branch) {
        return nil;
    }

    BNCLinkData *linkData = [self linkDataWithLinkProperties:linkProperties
                                             ignoreUAString:ignoreUAString];

    // An ignoreUAString means the caller wants a link that will not be counted as clicked by a
    // preview scrape, so we always go to the server for a fresh one rather than serving a cached
    // ordinary link.
    if (!ignoreUAString && [branch.linkCache objectForKey:linkData]) {
        [[BranchLogger shared] logVerbose:@"Returning cached Branch Link" error:nil];
        return [branch.linkCache objectForKey:linkData];
    }

    BranchShortUrlSyncRequest *req =
        [[BranchShortUrlSyncRequest alloc] initWithTags:linkProperties.tags
                                                  alias:linkProperties.alias
                                                   type:linkProperties.linkType
                                          matchDuration:linkProperties.matchDuration
                                                channel:linkProperties.channel
                                                feature:linkProperties.feature
                                                  stage:linkProperties.stage
                                               campaign:linkProperties.campaign
                                                 params:[self paramsFromLinkProperties:linkProperties]
                                               linkData:linkData
                                              linkCache:branch.linkCache];

    [[BranchLogger shared] logVerbose:@"Requesting Branch Link synchronously" error:nil];
    BNCServerResponse *serverResponse = [req makeRequest:branch.serverInterface key:[Branch branchKey]];

    // -processResponse: caches on a 200. Nothing is cached here, so the long-URL fallback it
    // returns on a non-200 does not displace the short link a later call can still fetch.
    return [req processResponse:serverResponse];
}

- (void)getShortURLWithParamsWithLinkProperties:(BranchLinkProperties *)linkProperties
                                       callback:(callbackWithUrl)callback {

    NSError *initError = nil;
    Branch *branch = [self resolvedBranchForTerminal:@"getShortURLWithParamsWithLinkProperties:callback:"
                                               error:&initError];
    if (!branch) {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil, initError);
            });
        }
        return;
    }

    // Snapshot every option *before* dispatching.
    //
    // The async path has no ignoreUAString option: the funnel hardcoded nil here, and a link whose
    // click should not be counted is only ever requested through the blocking terminal.
    BNCLinkData *linkData = [self linkDataWithLinkProperties:linkProperties ignoreUAString:nil];
    NSArray *tags = linkProperties.tags;
    NSString *alias = linkProperties.alias;
    BranchLinkType linkType = linkProperties.linkType;
    NSUInteger matchDuration = linkProperties.matchDuration;
    NSString *channel = linkProperties.channel;
    NSString *feature = linkProperties.feature;
    NSString *stage = linkProperties.stage;
    NSString *campaign = linkProperties.campaign;
    NSDictionary *params = [self paramsFromLinkProperties:linkProperties];

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

- (NSString *)getLongURLWithLinkProperties:(BranchLinkProperties *)linkProperties
                          useAppLinkDomain:(BOOL)useAppLinkDomain {

    NSString *branchKey = [Branch branchKey];
    if (!branchKey) {
        [[BranchLogger shared] logError:@"Cannot build a long URL without a Branch key." error:nil];
        return nil;
    }

    NSString *baseUrl = [self longUrlBaseUrlWithBranchKey:branchKey
                                        useAppLinkDomain:useAppLinkDomain];
    return [self longUrlWithBaseUrl:baseUrl linkProperties:linkProperties];
}

- (void)getSpotlightURLWithParams:(NSDictionary *)params callback:(callbackWithParams)callback {
    NSError *initError = nil;
    Branch *branch = [self resolvedBranchForTerminal:@"getSpotlightURLWithParams:callback:"
                                               error:&initError];
    if (!branch) {
        if (callback) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(@{}, initError);
            });
        }
        return;
    }

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

// The link's data payload. BranchLinkProperties returns an empty dictionary rather than nil for
// unset control params, and -[BNCLinkData setupParams:] only skips a nil one -- so without this an
// optionless link would start sending "data": {} where it used to send no data key at all.
//
// @param linkProperties The link properties to read. May be nil.
// @return The control params, or nil when there are none.
- (NSDictionary *)paramsFromLinkProperties:(BranchLinkProperties *)linkProperties {
    NSDictionary *controlParams = linkProperties.controlParams;
    return controlParams.count ? controlParams : nil;
}

- (BNCLinkData *)linkDataWithLinkProperties:(BranchLinkProperties *)linkProperties
                             ignoreUAString:(NSString *)ignoreUAString {
    BNCLinkData *post = [[BNCLinkData alloc] init];

    [post setupType:linkProperties.linkType];
    [post setupTags:linkProperties.tags];
    [post setupChannel:linkProperties.channel];
    [post setupFeature:linkProperties.feature];
    [post setupStage:linkProperties.stage];
    [post setupCampaign:linkProperties.campaign];
    [post setupAlias:linkProperties.alias];
    [post setupMatchDuration:linkProperties.matchDuration];
    [post setupIgnoreUAString:ignoreUAString];
    [post setupParams:[self paramsFromLinkProperties:linkProperties]];

    return post;
}

#pragma mark - Long URL assembly

- (NSString *)longUrlBaseUrlWithBranchKey:(NSString *)branchKey
                         useAppLinkDomain:(BOOL)useAppLinkDomain {
    if (!useAppLinkDomain) {
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
// feature -> stage -> campaign -> type -> duration -> source=ios&data=<base64>.
- (NSString *)longUrlWithBaseUrl:(NSString *)baseUrl
                  linkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableString *longUrl = [[BNCPreferenceHelper sharedInstance] sanitizedMutableBaseURL:baseUrl];

    for (NSString *tag in linkProperties.tags) {
        [longUrl appendFormat:@"tags=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:tag]];
    }

    if ([linkProperties.alias length]) {
        [longUrl appendFormat:@"alias=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:linkProperties.alias]];
    }

    if ([linkProperties.channel length]) {
        [longUrl appendFormat:@"channel=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:linkProperties.channel]];
    }

    if ([linkProperties.feature length]) {
        [longUrl appendFormat:@"feature=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:linkProperties.feature]];
    }

    if ([linkProperties.stage length]) {
        [longUrl appendFormat:@"stage=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:linkProperties.stage]];
    }

    if ([linkProperties.campaign length]) {
        [longUrl appendFormat:@"campaign=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:linkProperties.campaign]];
    }

    // Truthiness guards, not nil checks: BranchLinkTypeUnlimitedUse is 0 and a matchDuration of 0
    // means "server default", so default link properties emit neither parameter.
    if (linkProperties.linkType) {
        [longUrl appendFormat:@"type=%ld&", (long)linkProperties.linkType];
    }
    if (linkProperties.matchDuration) {
        [longUrl appendFormat:@"duration=%ld&", (long)linkProperties.matchDuration];
    }

    // The base64 alphabet includes "+", which a server decodes as a space, so the encoded params
    // have to be percent-encoded before they go into the query.
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:linkProperties.controlParams];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", [BNCEncodingUtils urlEncodedString:base64EncodedParams]];

    return longUrl;
}

@end

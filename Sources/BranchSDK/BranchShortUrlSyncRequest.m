//
//  BranchShortUrlSyncRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchShortUrlSyncRequest.h"
#import "BNCPreferenceHelper.h"
#import "BNCEncodingUtils.h"
#import "BranchConstants.h"
#import "BNCConfig.h"
#import "BranchLogger.h"
#import "BNCRequestFactory.h"
#import "BNCServerAPI.h"

@interface BranchShortUrlSyncRequest ()

@property (strong, nonatomic) NSArray *tags;
@property (copy, nonatomic) NSString *alias;
@property (assign, nonatomic) BranchLinkType type;
@property (assign, nonatomic) NSInteger matchDuration;
@property (copy, nonatomic) NSString *channel;
@property (copy, nonatomic) NSString *feature;
@property (copy, nonatomic) NSString *stage;
@property (copy, nonatomic) NSString *campaign;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) BNCLinkCache *linkCache;
@property (strong, nonatomic) BNCLinkData *linkData;
@property (nonatomic, copy, readwrite) NSString *requestUUID;
@property (nonatomic, copy, readwrite) NSNumber *requestCreationTimeStamp;
@end

@implementation BranchShortUrlSyncRequest

- (id)initWithTags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage campaign:(NSString *)campaign params:(NSDictionary *)params linkData:(BNCLinkData *)linkData linkCache:(BNCLinkCache *)linkCache {
    if ((self = [super init])) {
        _tags = tags;
        _alias = alias;
        _type = type;
        _matchDuration = duration;
        _channel = channel;
        _feature = feature;
        _stage = stage;
        _campaign = campaign;
        _params = params;
        _linkCache = linkCache;
        _linkData = linkData;
        _requestUUID = [[NSUUID UUID ] UUIDString];
        _requestCreationTimeStamp = BNCWireFormatFromDate([NSDate date]);
    }
    
    return self;
}

- (BNCServerResponse *)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key {
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *json = [factory dataForShortURLWithLinkDataDictionary:[self.linkData.data mutableCopy] isSpotlightRequest:NO];

    return [serverInterface postRequestSynchronous:json
		url:[[BNCServerAPI sharedInstance] linkServiceURL]
		key:key];
}

- (NSString *)processResponse:(BNCServerResponse *)response {
    if (![response.statusCode isEqualToNumber:@200]) {
        [[BranchLogger shared] logWarning:[NSString stringWithFormat:@"Short link creation received HTTP status code %@. Using long link instead.",
                                           response.statusCode] error:nil];
        NSString *failedUrl = nil;
        NSString *userUrl = [BNCPreferenceHelper sharedInstance].userUrl;
        if (userUrl) {
            failedUrl = [self createLongUrlForUserUrl:userUrl];
        }
        
        return failedUrl;
    }
    
    NSString *url = response.data[BRANCH_RESPONSE_KEY_URL];
    
    // cache the link
    if (url) {
        [self.linkCache setObject:url forKey:self.linkData];
    }
    
    return url;
}

- (NSString *)createLongUrlForUserUrl:(NSString *)userUrl {
    NSMutableString *baseUrl = [[NSMutableString alloc] initWithFormat:@"%@?", userUrl];
    return [BranchShortUrlSyncRequest createLongUrlWithBaseUrl:baseUrl tags:self.tags alias:self.alias type:self.type matchDuration:self.matchDuration channel:self.channel feature:self.feature stage:self.stage params:self.params];
}

+ (NSString *)createLinkFromBranchKey:(NSString *)branchKey tags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params {
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper sharedInstance];
    NSMutableString *baseUrl;
    
    if (preferenceHelper.userUrl)
        baseUrl = [preferenceHelper sanitizedMutableBaseURL:preferenceHelper.userUrl];
    else
        baseUrl = [[NSMutableString alloc] initWithFormat:@"%@/a/%@?", BNC_LINK_URL, branchKey];

    return [BranchShortUrlSyncRequest createLongUrlWithBaseUrl:baseUrl tags:tags alias:alias type:type matchDuration:duration channel:channel feature:feature stage:stage params:params];
}

+ (NSString *)createLongUrlWithBaseUrl:(NSMutableString *)baseUrl
                                  tags:(NSArray *)tags
                                 alias:(NSString *)alias
                                  type:(BranchLinkType)type
                         matchDuration:(NSInteger)duration
                               channel:(NSString *)channel
                               feature:(NSString *)feature
                                 stage:(NSString *)stage
                                params:(NSDictionary *)params {

    baseUrl = [[BNCPreferenceHelper sharedInstance] sanitizedMutableBaseURL:baseUrl];
    for (NSString *tag in tags) {
        [baseUrl appendFormat:@"tags=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:tag]];
    }
    
    if ([alias length]) {
        [baseUrl appendFormat:@"alias=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:alias]];
    }
    
    if ([channel length]) {
        [baseUrl appendFormat:@"channel=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:channel]];
    }
    
    if ([feature length]) {
        [baseUrl appendFormat:@"feature=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:feature]];
    }
    
    if ([stage length]) {
        [baseUrl appendFormat:@"stage=%@&", [BNCEncodingUtils stringByPercentEncodingStringForQuery:stage]];
    }
    
    [baseUrl appendFormat:@"type=%ld&", (long)type];
    [baseUrl appendFormat:@"duration=%ld&", (long)duration];
    
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    NSString *urlEncodedBase64EncodedParams = [BNCEncodingUtils urlEncodedString:base64EncodedParams];
    [baseUrl appendFormat:@"source=ios&data=%@", urlEncodedBase64EncodedParams];

    return baseUrl;
}

@end

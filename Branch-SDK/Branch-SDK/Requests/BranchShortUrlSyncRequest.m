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

@interface BranchShortUrlSyncRequest ()

@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *alias;
@property (assign, nonatomic) BranchLinkType type;
@property (assign, nonatomic) NSInteger matchDuration;
@property (strong, nonatomic) NSString *channel;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) BNCLinkCache *linkCache;
@property (strong, nonatomic) BNCLinkData *linkData;

@end

@implementation BranchShortUrlSyncRequest

- (id)initWithTags:(NSArray *)tags alias:(NSString *)alias type:(BranchLinkType)type matchDuration:(NSInteger)duration channel:(NSString *)channel feature:(NSString *)feature stage:(NSString *)stage params:(NSDictionary *)params linkData:(BNCLinkData *)linkData linkCache:(BNCLinkCache *)linkCache {
    if (self = [super init]) {
        _tags = tags;
        _alias = alias;
        _type = type;
        _matchDuration = duration;
        _channel = channel;
        _feature = feature;
        _stage = stage;
        _params = params;
        _linkCache = linkCache;
        _linkData = linkData;
    }
    
    return self;
}

- (BNCServerResponse *)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:self.linkData.data];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    params[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    params[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    params[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

    return [serverInterface postRequest:params url:[preferenceHelper getAPIURL:BRANCH_REQUEST_ENDPOINT_GET_SHORT_URL] key:key log:YES];
}

- (NSString *)processResponse:(BNCServerResponse *)response {
    if (![response.statusCode isEqualToNumber:@200]) {
        NSString *failedUrl = nil;
        NSString *userUrl = [BNCPreferenceHelper preferenceHelper].userUrl;
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
    NSMutableString *longUrl = [[NSMutableString alloc] initWithFormat:@"%@?", userUrl];
    
    for (NSString *tag in self.tags) {
        [longUrl appendFormat:@"tags=%@&", tag];
    }
    
    if ([self.alias length]) {
        [longUrl appendFormat:@"alias=%@&", self.alias];
    }
    
    if ([self.channel length]) {
        [longUrl appendFormat:@"channel=%@&", self.channel];
    }
    
    if ([self.feature length]) {
        [longUrl appendFormat:@"feature=%@&", self.feature];
    }
    
    if ([self.stage length]) {
        [longUrl appendFormat:@"stage=%@&", self.stage];
    }
    
    [longUrl appendFormat:@"type=%ld&", (long)self.type];
    [longUrl appendFormat:@"matchDuration=%ld&", (long)self.matchDuration];
    
    NSData *jsonData = [BNCEncodingUtils encodeDictionaryToJsonData:self.params];
    NSString *base64EncodedParams = [BNCEncodingUtils base64EncodeData:jsonData];
    [longUrl appendFormat:@"source=ios&data=%@", base64EncodedParams];
    
    return longUrl;
}

@end

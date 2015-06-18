//
//  BNCLinkData.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCLinkData.h"
#import "BNCEncodingUtils.h"

NSString * const BNC_LINK_DATA_TAGS = @"tags";
NSString * const BNC_LINK_DATA_LINK_TYPE = @"type";
NSString * const BNC_LINK_DATA_ALIAS = @"alias";
NSString * const BNC_LINK_DATA_CHANNEL = @"channel";
NSString * const BNC_LINK_DATA_FEATURE = @"feature";
NSString * const BNC_LINK_DATA_STAGE = @"stage";
NSString * const BNC_LINK_DATA_DURATION = @"duration";
NSString * const BNC_LINK_DATA_DATA = @"data";
NSString * const BNC_LINK_DATA_IGNORE_UA_STRING = @"ignore_ua_string";

@interface BNCLinkData ()

@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) NSString *channel;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSString *ignoreUAString;
@property (assign, nonatomic) BranchLinkType type;
@property (assign, nonatomic) NSUInteger duration;

@end

@implementation BNCLinkData

- (id)init {
    if (self = [super init]) {
        self.data = [[NSMutableDictionary alloc] init];
        self.data[@"source"] = @"ios";
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    BNCLinkData *copy = [[BNCLinkData alloc] init];
    copy.data = [_data copyWithZone:zone];
    copy.tags = [_tags copyWithZone:zone];
    copy.alias = [_alias copyWithZone:zone];
    copy.channel = [_channel copyWithZone:zone];
    copy.feature = [_feature copyWithZone:zone];
    copy.stage = [_stage copyWithZone:zone];
    copy.params = [_params copyWithZone:zone];
    copy.ignoreUAString = [_ignoreUAString copyWithZone:zone];
    copy.type = _type;
    copy.duration = _duration;

    return copy;
}

- (void)setupTags:(NSArray *)tags {
    if (tags) {
        _tags = tags;

        self.data[BNC_LINK_DATA_TAGS] = tags;
    }
}

- (void)setupAlias:(NSString *)alias {
    if (alias) {
        _alias = alias;

        self.data[BNC_LINK_DATA_ALIAS] = alias;
    }
}

- (void)setupType:(BranchLinkType)type {
    if (type) {
        _type = type;

        self.data[BNC_LINK_DATA_LINK_TYPE] = @(type);
    }
}

- (void)setupMatchDuration:(NSUInteger)duration {
    if (duration > 0) {
        _duration = duration;

        self.data[BNC_LINK_DATA_DURATION] = @(duration);
    }
}

- (void)setupChannel:(NSString *)channel {
    if (channel) {
        _channel = channel;

        self.data[BNC_LINK_DATA_CHANNEL] = channel;
    }
}

- (void)setupFeature:(NSString *)feature {
    if (feature) {
        _feature = feature;

        self.data[BNC_LINK_DATA_FEATURE] = feature;
    }
}

- (void)setupStage:(NSString *)stage {
    if (stage) {
        _stage = stage;

        self.data[BNC_LINK_DATA_STAGE] = stage;
    }
}

- (void)setupIgnoreUAString:(NSString *)ignoreUAString {
    if (ignoreUAString) {
        _ignoreUAString = ignoreUAString;
        
        self.data[BNC_LINK_DATA_IGNORE_UA_STRING] = ignoreUAString;
    }
}

- (void)setupParams:(NSDictionary *)params {
    if (params) {
        _params = params;

        self.data[BNC_LINK_DATA_DATA] = params;
    }
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    if (anObject) {
        self.data[aKey] = anObject;
    }
}

- (id)objectForKey:(id)aKey {
    return self.data[aKey];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 19;

    NSString *encodedParams = [BNCEncodingUtils encodeDictionaryToJsonString:self.params];
    result = prime * result + self.type;
    result = prime * result + [[BNCEncodingUtils md5Encode:self.alias] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:self.channel] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:self.feature] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:self.stage] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:encodedParams] hash];
    result = prime * result + self.duration;
    
    for (NSString *tag in self.tags) {
        result = prime * result + [[BNCEncodingUtils md5Encode:tag] hash];
    }
    
    return result;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.tags) {
        [coder encodeObject:self.tags forKey:BNC_LINK_DATA_TAGS];
    }
    if (self.alias) {
        [coder encodeObject:self.alias forKey:BNC_LINK_DATA_ALIAS];
    }
    if (self.type) {
        [coder encodeObject:[NSNumber numberWithInteger:self.type] forKey:BNC_LINK_DATA_LINK_TYPE];
    }
    if (self.channel) {
        [coder encodeObject:self.channel forKey:BNC_LINK_DATA_CHANNEL];
    }
    if (self.feature) {
        [coder encodeObject:self.feature forKey:BNC_LINK_DATA_FEATURE];
    }
    if (self.stage) {
        [coder encodeObject:self.stage forKey:BNC_LINK_DATA_STAGE];
    }
    if (self.params) {
        NSString *encodedParams = [BNCEncodingUtils encodeDictionaryToJsonString:self.params];
        [coder encodeObject:encodedParams forKey:BNC_LINK_DATA_DATA];
    }
    if (self.duration > 0) {
        [coder encodeObject:[NSNumber numberWithInteger:self.duration] forKey:BNC_LINK_DATA_DURATION];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.tags = [coder decodeObjectForKey:BNC_LINK_DATA_TAGS];
        self.alias = [coder decodeObjectForKey:BNC_LINK_DATA_ALIAS];
        self.type = [[coder decodeObjectForKey:BNC_LINK_DATA_LINK_TYPE] intValue];
        self.channel = [coder decodeObjectForKey:BNC_LINK_DATA_CHANNEL];
        self.feature = [coder decodeObjectForKey:BNC_LINK_DATA_FEATURE];
        self.stage = [coder decodeObjectForKey:BNC_LINK_DATA_STAGE];
        self.duration = [[coder decodeObjectForKey:BNC_LINK_DATA_DURATION] intValue];
        
        NSString *encodedParams = [coder decodeObjectForKey:BNC_LINK_DATA_DATA];
        self.params = [BNCEncodingUtils decodeJsonStringToDictionary:encodedParams];
    }

    return self;
}

@end

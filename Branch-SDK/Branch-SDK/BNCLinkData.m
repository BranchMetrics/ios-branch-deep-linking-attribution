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

@implementation BNCLinkData

- (id)init {
    self = [super init];
    if (self) {
        self.data = [[NSMutableDictionary alloc] init];
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
        [self.data setObject:tags forKey:BNC_LINK_DATA_TAGS];
    }
}

- (void)setupAlias:(NSString *)alias {
    if (alias) {
        _alias = alias;
        [self.data setObject:alias forKey:BNC_LINK_DATA_ALIAS];
    }
}

- (void)setupType:(BranchLinkType)type {
    if (type) {
        _type = type;
        [self.data setObject:[NSNumber numberWithInt:type] forKey:BNC_LINK_DATA_LINK_TYPE];
    }
}

- (void)setupMatchDuration:(NSUInteger)duration {
    if (duration > 0) {
        _duration = duration;
        [self.data setObject:[NSNumber numberWithInteger:duration] forKey:BNC_LINK_DATA_DURATION];
    }
}

- (void)setupChannel:(NSString *)channel {
    if (channel) {
        _channel = channel;
        [self.data setObject:channel forKey:BNC_LINK_DATA_CHANNEL];
    }
}

- (void)setupFeature:(NSString *)feature {
    if (feature) {
        _feature = feature;
        [self.data setObject:feature forKey:BNC_LINK_DATA_FEATURE];
    }
}

- (void)setupStage:(NSString *)stage {
    if (stage) {
        _stage = stage;
        [self.data setObject:stage forKey:BNC_LINK_DATA_STAGE];
    }
}

- (void)setupIgnoreUAString:(NSString *)ignoreUAString {
    if (ignoreUAString) {
        _ignoreUAString = ignoreUAString;
        [self.data setObject:ignoreUAString forKey:BNC_LINK_DATA_IGNORE_UA_STRING];
    }
}

- (void)setupParams:(NSString *)params {
    _params = params;
    [self.data setObject:params forKey:BNC_LINK_DATA_DATA];
}


- (NSArray *)allKeys {
    return self.data.allKeys;
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    [self.data setObject:anObject forKey:aKey];
}

- (id)objectForKey:(id)aKey {
    return [self.data objectForKey:aKey];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 19;

    result = prime * result + self.type;
    result = prime * result + [[BNCEncodingUtils md5Encode:[self.alias lowercaseString]] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:[self.channel lowercaseString]] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:[self.feature lowercaseString]] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:[self.stage lowercaseString]] hash];
    result = prime * result + [[BNCEncodingUtils md5Encode:[self.params lowercaseString]] hash];
    result = prime * result + self.duration;
    
    for (NSString *tag in self.tags) {
        result = prime * result + [[BNCEncodingUtils md5Encode:[tag lowercaseString]] hash];
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
        [coder encodeObject:self.params forKey:BNC_LINK_DATA_DATA];
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
        self.params = [coder decodeObjectForKey:BNC_LINK_DATA_DATA];
        self.duration = [[coder decodeObjectForKey:BNC_LINK_DATA_DURATION] intValue];
    }
    return self;
}


@end

//
//  BNCLinkData.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 1/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCLinkData.h"

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
    copy.type = _type;
    copy.duration = _duration;

    return copy;
}

- (void)setupTags:(NSArray *)tags {
    if (tags) {
        _tags = tags;
        [self.data setObject:tags forKey:TAGS];
    }
}

- (void)setupAlias:(NSString *)alias {
    if (alias) {
        _alias = alias;
        [self.data setObject:alias forKey:ALIAS];
    }
}

- (void)setupType:(BranchLinkType)type {
    if (type) {
        _type = type;
        [self.data setObject:[NSNumber numberWithInt:type] forKey:LINK_TYPE];
    }
}

- (void)setupMatchDuration:(NSUInteger)duration {
    if (duration > 0) {
        _duration = duration;
        [self.data setObject:[NSNumber numberWithInteger:duration] forKey:DURATION];
    }
}

- (void)setupChannel:(NSString *)channel {
    if (channel) {
        _channel = channel;
        [self.data setObject:channel forKey:CHANNEL];
    }
}

- (void)setupFeature:(NSString *)feature {
    if (feature) {
        _feature = feature;
        [self.data setObject:feature forKey:FEATURE];
    }
}

- (void)setupStage:(NSString *)stage {
    if (stage) {
        _stage = stage;
        [self.data setObject:stage forKey:STAGE];
    }
}

- (void)setupParams:(NSString *)params {
    _params = params;
    [self.data setObject:params forKey:DATA];
}


- (NSArray *)allKeys {
    return self.data.allKeys;
}

- (void)setObject:(id)anObject forKey:(id <NSCopying>)aKey {
    [self.data setObject:anObject forKey:aKey];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key NS_AVAILABLE(10_8, 6_0) {
    [self.data setObject:obj forKeyedSubscript:key];
}

- (id)objectForKey:(id)aKey {
    return [self.data objectForKey:aKey];
}

- (NSUInteger)hash {
    NSUInteger result = 1;
    NSUInteger prime = 19;
    
    result = prime * result + self.type;
    result = prime * result + [[self.alias lowercaseString] hash];
    result = prime * result + [[self.channel lowercaseString] hash];
    result = prime * result + [[self.feature lowercaseString] hash];
    result = prime * result + [[self.stage lowercaseString] hash];
    result = prime * result + [[self.params lowercaseString] hash];
    result = prime * result + self.duration;
    
    for (NSString *tag in self.tags) {
        result = prime * result + [[tag lowercaseString] hash];
    }
    
    return result;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.tags) {
        [coder encodeObject:self.tags forKey:TAGS];
    }
    if (self.alias) {
        [coder encodeObject:self.alias forKey:ALIAS];
    }
    if (self.type) {
        [coder encodeObject:[NSNumber numberWithInteger:self.type] forKey:LINK_TYPE];
    }
    if (self.channel) {
        [coder encodeObject:self.channel forKey:CHANNEL];
    }
    if (self.feature) {
        [coder encodeObject:self.feature forKey:FEATURE];
    }
    if (self.stage) {
        [coder encodeObject:self.stage forKey:STAGE];
    }
    if (self.params) {
        [coder encodeObject:self.params forKey:DATA];
    }
    if (self.duration > 0) {
        [coder encodeObject:[NSNumber numberWithInteger:self.duration] forKey:DURATION];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.tags = [coder decodeObjectForKey:TAGS];
        self.alias = [coder decodeObjectForKey:ALIAS];
        self.type = [[coder decodeObjectForKey:LINK_TYPE] intValue];
        self.channel = [coder decodeObjectForKey:CHANNEL];
        self.feature = [coder decodeObjectForKey:FEATURE];
        self.stage = [coder decodeObjectForKey:STAGE];
        self.params = [coder decodeObjectForKey:DATA];
        self.duration = [[coder decodeObjectForKey:DURATION] intValue];
    }
    return self;
}


@end

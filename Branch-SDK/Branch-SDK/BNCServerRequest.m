//
//  BNCServerRequest.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BNCPreferenceHelper.h"

#define TAG         @"TAG"
#define DATA        @"POSTDATA"

@interface BNCServerRequest() <NSCoding>

@end


@implementation BNCServerRequest

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.tag) {
        [coder encodeObject:self.tag forKey:TAG];
    }
    if (self.postData) {
        [coder encodeObject:self.postData forKey:DATA];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.tag = [coder decodeObjectForKey:TAG];
        self.postData = [coder decodeObjectForKey:DATA];
    }
    return self;
}

- (id)initWithTag:(NSString *)tag {
    return [self initWithTag:tag andData:nil];
}

- (id)initWithTag:(NSString *)tag andData:(NSMutableDictionary *)postData {
    if (!tag) {
        [BNCPreferenceHelper log:FILE_NAME line:LINE_NUM message:@"Invalid: server request missing tag!"];
        return nil;
    }
    
    if (self = [super init]) {
        self.tag = tag;
        self.postData = postData;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Tag: %@; Data: %@", self.tag, self.postData];
}

@end

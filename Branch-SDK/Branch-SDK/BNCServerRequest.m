//
//  BNCServerRequest.m
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BNCConfig.h"

#define TAG         @"TAG"
#define DATA        @"POSTDATA"

@interface BNCServerRequest() <NSCoding>

@end


@implementation BNCServerRequest

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.tag forKey:TAG];
    [coder encodeObject:self.postData forKey:DATA];
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

- (id)initWithTag:(NSString *)tag andData:(NSDictionary *)postData {
    if (!tag) {
        Debug(@"Invalid: server request missing tag!");
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

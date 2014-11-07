//
//  BNCServerResponse.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/10/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerResponse.h"

@implementation BNCServerResponse

- (id)initWithTag:(NSString *)tag andStatusCode:(NSNumber *)code {
    if (!tag || !code) {
        return nil;
    }
    
    if (self = [super init]) {
        self.tag = tag;
        self.statusCode = code;
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Tag: %@; Status: %@; Data: %@", self.tag, self.statusCode, self.data];
}

@end

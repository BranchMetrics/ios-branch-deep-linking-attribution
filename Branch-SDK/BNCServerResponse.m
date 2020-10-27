//
//  BNCServerResponse.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/10/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCServerResponse.h"

@implementation BNCServerResponse

- (NSString *)description {
    if (self.requestId) {
        return [NSString stringWithFormat:@"[%@] Status: %@; Data: %@", self.requestId, self.statusCode, self.data];
    }
    else {
        return [NSString stringWithFormat:@"Status: %@; Data: %@", self.statusCode, self.data];
    }
}

@end

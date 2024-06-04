//
//  BNCServerRequest.m
//  Branch-SDK
//
//  Created by Graham Mueller on 5/22/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCServerRequest.h"
#import "BranchLogger.h"

@implementation BNCServerRequest

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    [[BranchLogger shared] logError:@"BNCServerRequest subclasses must implement makeRequest:key:callback:." error:nil];
}

- (void)processResponse:(BNCServerResponse *)response error:(NSError *)error {
    [[BranchLogger shared] logError:@"BNCServerRequest subclasses must implement processResponse:error:." error:nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return self = [super init];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    // Nothing going on here
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

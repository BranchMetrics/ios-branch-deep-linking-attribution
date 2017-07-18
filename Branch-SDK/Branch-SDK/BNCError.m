//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCError.h"

NSString * const BNCErrorDomain = @"io.branch";

@implementation BNCError

+ (NSError*) branchErrorWithCode:(BNCErrorCode)errorCode reason:(NSString*_Nullable)reason {
    NSString* reasonStr = BNCLocalizedString(reason);
    NSError *error = [NSError errorWithDomain:BNCErrorDomain code:errorCode userInfo:
                      reasonStr == nil? nil:@{ NSLocalizedDescriptionKey: BNCLocalizedString(reason)}];
    return error;
}

@end

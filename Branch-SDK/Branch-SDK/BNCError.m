//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCError.h"


NSString * const BNCErrorDomain = @"io.branch.error";


NSError *_Nonnull BNCErrorWithCode(BNCErrorCode errorCode) {
    return BNCErrorWithCodeAndReason(errorCode, nil);
}

NSError *_Nonnull BNCErrorWithCodeAndReason(BNCErrorCode errorCode, NSString* reason) {

    NSString * description = nil;

    switch (errorCode) {
    case BNCErrorADClientNotAvailable:
        description = @"ADClient is not available.";
        break;
    default:
        description = nil;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (description)
        userInfo[NSLocalizedDescriptionKey] = description;
    if (reason)
        userInfo[NSLocalizedFailureReasonErrorKey] = reason;

    NSError *error =
        [NSError errorWithDomain:BNCErrorDomain
                            code:errorCode
                        userInfo:userInfo];
    return error;
}

//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import "BNCError.h"


NSString * const BNCErrorDomain = @"io.branch.error";


#define _countof(arr) (sizeof(arr) / sizeof(arr[0]))


NSError *_Nonnull BNCErrorWithCode(BNCErrorCode errorCode) {
    return BNCErrorWithCodeAndReason(errorCode, nil);
}


NSError *_Nonnull BNCErrorWithCodeAndReason(BNCErrorCode errorCode, NSString* reason) {

    NSString *const localizedDescriptions[] =
        {
         nil    //  0
        ,nil
        ,nil
        ,nil
        ,nil
        ,nil    //  5
        ,nil
        ,@"ADClient is not available."
        ,@"No results where found."
        };

    NSString * description = nil;
    NSInteger index = errorCode - BNCInitError;
    if (index >= 0 && index < _countof(localizedDescriptions))
        description = localizedDescriptions[index];

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

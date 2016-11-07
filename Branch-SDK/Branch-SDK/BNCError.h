//
//  BNCError.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>


FOUNDATION_EXPORT NSString *_Nonnull const BNCErrorDomain;

enum {
    BNCInitError = 1000,
    BNCDuplicateResourceError,
    BNCRedeemCreditsError,
    BNCBadRequestError,
    BNCServerProblemError,
    BNCNilLogError,
    BNCVersionError
};

@interface BNCError : NSObject

@end

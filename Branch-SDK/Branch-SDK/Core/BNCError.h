//
//  BNCError.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const BNCErrorDomain;

enum {
    BNCInitError = 1000,
    BNCDuplicateResourceError,
    BNCInvalidPromoCodeError,
    BNCRedeemCreditsError,
    BNCBadRequestError,
    BNCServerProblemError,
    BNCNilLogError,
    BNCVersionError
};

@interface BNCError : NSObject

@end
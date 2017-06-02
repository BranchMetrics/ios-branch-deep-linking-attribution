//
//  BNCError.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *_Nonnull const BNCErrorDomain;

typedef NS_ENUM(NSInteger, BNCErrorCode) {
    BNCInitError                = 1000,
    BNCDuplicateResourceError   = 1001,
    BNCRedeemCreditsError       = 1002,
    BNCBadRequestError          = 1003,
    BNCServerProblemError       = 1004,
    BNCNilLogError              = 1005,
    BNCVersionError             = 1006,
};

@interface BNCError : NSObject
@end

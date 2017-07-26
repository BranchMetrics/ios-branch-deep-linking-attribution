//
//  BNCError.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCLocalization.h"

FOUNDATION_EXPORT NSString *_Nonnull const BNCErrorDomain;

typedef NS_ENUM(NSInteger, BNCErrorCode) {
    BNCInitError                    = 1000,
    BNCDuplicateResourceError       = 1001,
    BNCRedeemCreditsError           = 1002,
    BNCBadRequestError              = 1003,
    BNCServerProblemError           = 1004,
    BNCNilLogError                  = 1005,
    BNCVersionError                 = 1006,
    BNCNetworkServiceInterfaceError = 1007,
    BNCInvalidPublicKeyError        = 1008,
    BNCContentIdentifierError       = 1009,
    BNCSpotlightNotAvailableError   = 1010,
    BNCSpotlightTitleError          = 1011,
    BNCRedeemZeroCreditsError       = 1012,
};

@interface NSError (Branch)
+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode;
+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode error:(NSError*_Nullable)error;
+ (NSError*_Nonnull) branchErrorWithCode:(BNCErrorCode)errorCode message:(NSString*_Nullable)message;
@end

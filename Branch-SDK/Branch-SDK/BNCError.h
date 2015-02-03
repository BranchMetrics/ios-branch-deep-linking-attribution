//
//  BNCError.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const BNCErrorDomain;

enum {
    BNCInitError = 1000,
    BNCCloseError,
    BNCEventError,
    BNCGetReferralsError,
    BNCGetCreditsError,
    BNCGetCreditHistoryError,
    BNCRedeemCreditsError,
    BNCCreateURLError,
    BNCIdentifyError,
    BNCLogoutError,
    BNCGetReferralCodeError,
    BNCDuplicateReferralCodeError,
    BNCValidateReferralCodeError,
    BNCInvalidReferralCodeError,
    BNCApplyReferralCodeError,
    BNCCreateURLDuplicateAliasError,
    BNCNotInitError
};

@interface BNCError : NSObject

+ (NSDictionary *)getUserInfoDictForDomain:(NSInteger)code;

@end
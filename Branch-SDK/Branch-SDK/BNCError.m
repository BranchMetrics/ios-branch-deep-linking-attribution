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

+ (NSDictionary *)getUserInfoDictForDomain:(NSInteger)code {
    switch (code) {
        case BNCInitError:
            return @{ NSLocalizedDescriptionKey: @"Failed to initialize" };
        case BNCCloseError:
            return @{ NSLocalizedDescriptionKey: @"Trouble closing the session" };
        case BNCEventError:
            return @{ NSLocalizedDescriptionKey: @"Trouble registering the event" };
        case BNCGetReferralsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble getting the referral counts" };
        case BNCGetCreditsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble getting the credits" };
        case BNCGetCreditHistoryError:
            return @{ NSLocalizedDescriptionKey: @"Trouble retrieving the credit history" };
        case BNCRedeemCreditsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble redeeming the credits" };
        case BNCCreateURLError:
            return @{ NSLocalizedDescriptionKey: @"Trouble creating the URL" };
        case BNCIdentifyError:
            return @{ NSLocalizedDescriptionKey: @"Trouble assigning alias to user" };
        case BNCLogoutError:
            return @{ NSLocalizedDescriptionKey: @"Trouble logging out" };
        case BNCGetReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Trouble creating that referral code" };
        case BNCDuplicateReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"That referral code is already taken for a different user and parameter set" };
        case BNCValidateReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Trouble validating referral code" };
        case BNCInvalidReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Referral code is invalid - has it already been used or the code might not exist" };
        case BNCApplyReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Troubling applying referral code" };
        case BNCCreateURLDuplicateAliasError:
            return @{ NSLocalizedDescriptionKey: @"That link alias is already taken for your domain - please try a different one or adjust the parameters to retrieve on that's already been created" };
    }
    return @{ NSLocalizedDescriptionKey: @"Trouble reaching server. Please try again in a few minutes" };
}

@end

//
//  BNCError.m
//  Branch-SDK
//
//  Created by Qinwei Gong on 11/17/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "BNCError.h"

NSString *const BNCErrorDomain = @"io.branch";

@implementation BNCError

+ (NSDictionary *)getUserInfoDictForDomain:(NSInteger)code {
    switch (code) {
        case BNCInitError:
            return @{ NSLocalizedDescriptionKey: @"Failed to initialize - are you using the right Branch key?" };
        case BNCCloseError:
            return @{ NSLocalizedDescriptionKey: @"Trouble closing the session - check network connectivity?" };
        case BNCEventError:
            return @{ NSLocalizedDescriptionKey: @"Trouble registering the event - check network connectivity?" };
        case BNCGetReferralsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble getting the referral counts - check network connectivity?" };
        case BNCGetCreditsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble getting the credits - check network connectivity?" };
        case BNCGetCreditHistoryError:
            return @{ NSLocalizedDescriptionKey: @"Trouble retrieving the credit history - check network connectivity?" };
        case BNCRedeemCreditsError:
            return @{ NSLocalizedDescriptionKey: @"Trouble redeeming the credits - check network connectivity?" };
        case BNCCreateURLError:
            return @{ NSLocalizedDescriptionKey: @"Trouble creating the URL - check network connectivity?" };
        case BNCIdentifyError:
            return @{ NSLocalizedDescriptionKey: @"Trouble assigning alias to user - check network connectivity?" };
        case BNCLogoutError:
            return @{ NSLocalizedDescriptionKey: @"Trouble logging out - check network connectivity?" };
        case BNCGetReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Trouble creating that referral code - check network connectivity?" };
        case BNCDuplicateReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"That referral code is already taken for a different user and parameter set" };
        case BNCValidateReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Trouble validating referral code - check network connectivity?" };
        case BNCInvalidReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Referral code is invalid - has it already been used or the code might not exist" };
        case BNCApplyReferralCodeError:
            return @{ NSLocalizedDescriptionKey: @"Troubling applying referral code - check network connectivity?" };
        case BNCCreateURLDuplicateAliasError:
            return @{ NSLocalizedDescriptionKey: @"That link alias is already taken for your domain - please try a different one or adjust the parameters to retrieve on that's already been created" };
        case BNCNotInitError:
            return @{ NSLocalizedDescriptionKey: @"You can't make a Branch call without first initializing the session. Did you add the initSession call to the AppDelegate?" };
    }
    return @{ NSLocalizedDescriptionKey: @"Trouble reaching server. Please try again in a few minutes" };
}

@end

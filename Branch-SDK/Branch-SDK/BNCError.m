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
            return [NSDictionary dictionaryWithObject:@[@"Failed to initialize - are you using the right API key?"] forKey:NSLocalizedDescriptionKey];
        case BNCCloseError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble closing the session - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCEventError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble registering the event - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCGetReferralsError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble getting the referral counts - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCGetCreditsError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble getting the credits - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCGetCreditHistoryError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble retrieving the credit history - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCRedeemCreditsError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble redeeming the credits - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCCreateURLError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble creating the URL - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCIdentifyError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble assigning alias to user - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCLogoutError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble logging out - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCGetReferralCodeError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble creating that referral code - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCDuplicateReferralCodeError:
            return [NSDictionary dictionaryWithObject:@[@"That referral code is already taken for a different user and parameter set"] forKey:NSLocalizedDescriptionKey];
        case BNCValidateReferralCodeError:
            return [NSDictionary dictionaryWithObject:@[@"Trouble validating referral code - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCInvalidReferralCodeError:
            return [NSDictionary dictionaryWithObject:@[@"Referral code is invalid - has it already been used or the code might not exist"] forKey:NSLocalizedDescriptionKey];
        case BNCApplyReferralCodeError:
            return [NSDictionary dictionaryWithObject:@[@"Troubling applying referral code - check network connectivity?"] forKey:NSLocalizedDescriptionKey];
        case BNCCreateURLDuplicateAliasError:
            return [NSDictionary dictionaryWithObject:@[@"That link alias is already taken for your domain - please try a different one or adjust the parameters to retrieve on that's already been created"] forKey:NSLocalizedDescriptionKey];
        case BNCNotInitError:
            return [NSDictionary dictionaryWithObject:@[@"You can't make a Branch call without first initializing the session. Did you add the initSession call to the AppDelegate?"] forKey:NSLocalizedDescriptionKey];
    }
    return [NSDictionary dictionaryWithObject:@[@"Trouble reaching server. Please try again in a few minutes"] forKey:NSLocalizedDescriptionKey];
}

@end

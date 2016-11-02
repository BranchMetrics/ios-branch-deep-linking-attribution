//
//  BNCSearchAdAttribution.m
//  Branch
//
//  Created by Edward Smith on 11/1/16.
//


#import "BNCSearchAdAttribution.h"
#import <iAD/iAD.h>
#import "BNCError.h"
#import "BNCEncodingUtils.h"
#import "BNCPreferenceHelper.h"


/*
    Flow:
    
    If the user has set 'checkAppleSearchAdInstall = YES' then Branch should instantiate this class
    to check the value at start up.

    Details:

    1)  If it's been called before, the result is in preferences, and that value is returned.

    2)  If hasn't been checked before, calls
        
        '[[ADClientClass sharedClient] requestAttributionDetailsWithBlock:]'

        to get the result.  The result is saved in preferences.
        
- (void) setAppleSearchAdDetails:(NSDictionary*)details
{
    [self writeObjectToDefaults:@"appleSearchAdDetails" value:details];
}

- (NSDictionary*) appleSearchAdDetails
{
    return [self readObjectFromDefaults:@"appleSearchAdDetails"];
}
        
*/


const NSInteger BNCErrorADClientNotAvailable = 1007;
const NSString* BNCErrorADClientNotAvailableDescription = @"ADClient is not available on this device.";


@interface BNCSearchAdAttribution ()
@end


@implementation BNCSearchAdAttribution

+ (NSDictionary* _Nullable) lastAttribution
{
    return [BNCPreferenceHelper preferenceHelper].appleSearchAdDetails;
    return nil;
}

+ (NSString*_Nonnull) lastAttributionWireFormatString
{
    NSDictionary *dictionary = [self lastAttribution];
    if (!dictionary) dictionary = [NSDictionary new];
    NSString* string = dictionary.description;
    if (!string) string = @"";
    string = [BNCEncodingUtils base64EncodeStringToString:string];
    return string;
}

+ (void) _checkAttributionWithCompletion:
        (void (^)(NSDictionary *attributionDetails, NSError *error))completion
{
    Class ADClientClass = NSClassFromString(@"ADClient");
    if (ADClientClass &&
        [[ADClientClass sharedClient] respondsToSelector:@selector(requestAttributionDetailsWithBlock:)]) {

        [[ADClientClass sharedClient]
            requestAttributionDetailsWithBlock:
            ^ (NSDictionary *details, NSError *error) {
                if (completion) completion(details, error);
            }];

    } else {

        NSError *error =
            [NSError errorWithDomain:BNCErrorDomain
                                code:BNCErrorADClientNotAvailable
                            userInfo:@{ NSLocalizedDescriptionKey: BNCErrorADClientNotAvailableDescription }];
        if (completion)
            completion(nil, error);
    }
}

+ (void) checkAttributionWithCompletion:(void (^)(NSDictionary*result))completion
{
    NSDictionary *dictionary = [self.class lastAttribution];
    if (/* DISABLES CODE */ (NO) /*dictionary*/) {
        if (completion) completion(dictionary);
        return;
    }

    [self _checkAttributionWithCompletion:^ void (NSDictionary *dictionary, NSError*error) {
        NSMutableDictionary *result = nil;
        if ([dictionary isKindOfClass:[NSDictionary class]])
            result = [dictionary mutableCopy];
        else
            result = [NSMutableDictionary new];

        if (error)
            result[@"Error"] = error.description;

        [BNCPreferenceHelper preferenceHelper].appleSearchAdDetails = result;

        NSLog(@"iAd Attribution result:\n%@.", result);
        if (completion)
            completion(result);
    }];
}

@end

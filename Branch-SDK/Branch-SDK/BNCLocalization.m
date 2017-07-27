//
//  BNCLocalization.m
//  Branch-SDK
//
//  Created by Parth Kalavadia on 7/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCLocalization.h"
#import "BNCLog.h"

#pragma mark BNCLocalization

@interface BNCLocalization : NSObject
@end

@implementation BNCLocalization

+(NSDictionary*) supportedLanguages {
    NSDictionary* languages = @{
        @"en":  [BNCLocalization en_localized],
        @"es":  [BNCLocalization es_localized]
    };
    return languages;
}

+ (NSDictionary*) en_localized {
    NSDictionary* en_dict = @{

    // BNCInitError
    @"The Branch user session has not been initialized.":
    @"The Branch user session has not been initialized.",

    // BNCDuplicateResourceError
    @"A resource with this identifier already exists.":
    @"A resource with this identifier already exists.",

    // BNCRedeemCreditsError
    @"You're trying to redeem more credits than are available. Have you loaded rewards?":
    @"You're trying to redeem more credits than are available. Have you loaded rewards?",

    // BNCBadRequestError
    @"The network request was invalid.":
    @"The network request was invalid.",

    // BNCServerProblemError
    @"Trouble reaching the Branch servers, please try again shortly.":
    @"Trouble reaching the Branch servers, please try again shortly.",

    // BNCNilLogError
    @"Can't log error messages because the logger is set to nil.":
    @"Can't log error messages because the logger is set to nil.",

    // BNCVersionError
    @"Incompatible version.":
    @"Incompatible version.",

    // BNCNetworkServiceInterfaceError
    @"The underlying network service does not conform to the BNCNetworkOperationProtocol.":
    @"The underlying network service does not conform to the BNCNetworkOperationProtocol.",

    // BNCInvalidNetworkPublicKeyError
    @"Public key is not an SecKeyRef type.":
    @"Public key is not an SecKeyRef type.",

    // BNCContentIdentifierError
    @"A canonical identifier or title are required to uniquely identify content.":
    @"A canonical identifier or title are required to uniquely identify content.",

    // BNCSpotlightNotAvailableError
    @"The Core Spotlight indexing service is not available on this device.":
    @"The Core Spotlight indexing service is not available on this device.",

    // BNCSpotlightTitleError
    @"Spotlight indexing requires a title.":
    @"Spotlight indexing requires a title.",

    // BNCRedeemZeroCreditsError
    @"Can't redeem zero credits.":
    @"Can't redeem zero credits.",

    // Unknown error
    @"Branch encountered an error.":
    @"Branch encountered an error.",

    // Network provider error messages
    @"A network operation instance is expected to be returned by the networkOperationWithURLRequest:completion: method.":
    @"A network operation instance is expected to be returned by the networkOperationWithURLRequest:completion: method.",

    @"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.":
    @"Network operation of class '%@' does not conform to the BNCNetworkOperationProtocol.",

    @"The network operation start date is not set. The Branch SDK expects the network operation start date to be set by the network provider.":
    @"The network operation start date is not set. The Branch SDK expects the network operation start date to be set by the network provider.",

    @"The network operation timeout date is not set. The Branch SDK expects the network operation timeout date to be set by the network provider.":
    @"The network operation timeout date is not set. The Branch SDK expects the network operation timeout date to be set by the network provider.",

    @"The network operation request is not set. The Branch SDK expects the network operation request to be set by the network provider.":
    @"The network operation request is not set. The Branch SDK expects the network operation request to be set by the network provider.",

    // Other errors
    @"The request was invalid.":
    @"The request was invalid.",

    @"Could not register view.":
    @"Could not register view.",

    @"Could not generate a URL.":
    @"Could not generate a URL.",

    };
    return en_dict;
}

+ (NSDictionary*) es_localized {
    NSDictionary* es_dict = @{

    @"Could not generate a URL.":
    @"No se pudo generar una URL.",
    
    };
    return es_dict;
}
@end

#pragma mark - BNCLocalizedString

static NSString *bnc_localizationLanguage = nil;

void BNCLocalizationSetLanguage(NSString*localization) {
    bnc_localizationLanguage = localization;
}

NSString* BNCLocalizationLanguage(void) {
    return bnc_localizationLanguage;
}

NSString* /**Nonnull*/ BNCLocalizedString(NSString* string) {
    if (!string) return @"";

    //  TODO: Fix the main bundle version of this determining default language.
    
    NSString *language =
        (bnc_localizationLanguage.length)
        ? bnc_localizationLanguage
        : [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];

    NSDictionary* languageDictionary = [BNCLocalization supportedLanguages][language];
    languageDictionary = languageDictionary ?: [BNCLocalization en_localized];

    NSString* localizedString = languageDictionary[string];
    if (!localizedString) {
        BNCLogWarning(@"Branch is missing the localization missing for language '%@' string '%@'.",
            language, string);
        localizedString = string;
    }
    return localizedString;
}


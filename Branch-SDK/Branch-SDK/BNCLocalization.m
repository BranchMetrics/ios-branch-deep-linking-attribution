//
//  BNCLocalization.m
//  Branch-SDK
//
//  Created by Parth Kalavadia on 7/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCLocalization.h"

@implementation BNCLocalization

extern NSString* BNCLocalizedString (NSString* string){
    
    NSString* preferredLang = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
    NSDictionary* localizedLanguage = [BNCLocalization getSupportedLanguages][preferredLang];
    localizedLanguage == nil?[BNCLocalization en_localised]:localizedLanguage;
    NSString* localizedString = localizedLanguage[string];

    return localizedString == nil?string:localizedString;
}

+(NSDictionary*) getSupportedLanguages {
    NSDictionary* supportedLanguages = @{@"en":[BNCLocalization en_localised]};
    return supportedLanguages;
}

+(NSDictionary*) en_localised {
    NSDictionary* en_dic = @{@"YES":@"Yes",
    @"Cannot use CoreSpotlight indexing service prior to iOS 9":@"Cannot use CoreSpotlight indexing service prior to iOS 9",
    @"CoreSpotlight is not available because the base SDK for this project is less than 9.0":@"CoreSpotlight is not available because the base SDK for this project is less than 9.0",
    @"Cannot use CoreSpotlight indexing service on this device/OS":@"Cannot use CoreSpotlight indexing service on this device/OS",
    @"Spotlight Indexing requires a title":@"Spotlight Indexing requires a title",
    @"Trouble reaching the Branch servers, please try again shortly":@"Trouble reaching the Branch servers, please try again shortly",
    @"A resource with this identifier already exists":@"A resource with this identifier already exists",
    @"Cannot redeem zero credits.":@"Cannot redeem zero credits.",
    @"You're trying to redeem more credits than are available. Have you loaded rewards?":@"You're trying to redeem more credits than are available. Have you loaded rewards?",
    @"Branch User Session has not been initialized":@"Branch User Session has not been initialized.",
    @"Cannot use CoreSpotlight indexing service prior to iOS 9":@"Cannot use CoreSpotlight indexing service prior to iOS 9",
    @"Cannot use CoreSpotlight indexing service on this device":@"Cannot use CoreSpotlight indexing service on this device",
    @"Spotlight Indexing requires a title":@"Spotlight Indexing requires a title",
    @"A canonicalIdentifier or title are required to uniquely identify content, so could not register view.":@"A canonicalIdentifier or title are required to uniquely identify content, so could not register view.",
    @"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.":@"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL."};
    
    return en_dic;
}

@end

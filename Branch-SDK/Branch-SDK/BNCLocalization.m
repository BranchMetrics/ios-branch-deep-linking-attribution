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
    NSDictionary* en_dic = @{@"YES":@"Yes"};
    @"Cannot use CoreSpotlight indexing service prior to iOS 9"
    @"CoreSpotlight is not available because the base SDK for this project is less than 9.0"
    @"Cannot use CoreSpotlight indexing service on this device/OS"
    @"Spotlight Indexing requires a title"
    
    
    return en_dic;
}

@end

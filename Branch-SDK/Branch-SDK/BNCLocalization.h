//
//  BNCLocalization.h
//  Branch-SDK
//
//  Created by Parth Kalavadia on 7/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

// Localization defaults to the default. TODO: 
void BNCLocalizationSetLanguage(NSString*localization);
NSString* BNCLocalizationLanguage(void);

NSString* /**Nonnull*/ BNCLocalizedString(NSString*string);

#define BNCLocalizedFormattedString(fmt, ...) \
    [NSString stringWithFormat:BNCLocalizedString(fmt), __VA_ARGS__]

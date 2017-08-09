//
//  BNCLocalization.h
//  Branch-SDK
//
//  Created by Parth Kalavadia on 7/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNCLocalization : NSObject

+ (instancetype) shared;
+ (NSString*) applicationLanguage;
+ (NSDictionary<NSString*, NSDictionary*>*) languageDictionaries;
- (NSString*) localizeString:(NSString*)string;

@property (copy) NSString* currentLanguage;
@property (strong, readonly) NSDictionary *currentLanguageDictionary;
@end

#pragma mark Convenience Functions

static inline NSString* /**_Nonnull*/ BNCLocalizedString(NSString*const string) {
    return [[BNCLocalization shared] localizeString:string];
}

extern NSString* /**_Nonnull*/ BNCLocalizedFormattedString(NSString*const format, ...) NS_FORMAT_FUNCTION(1,2);

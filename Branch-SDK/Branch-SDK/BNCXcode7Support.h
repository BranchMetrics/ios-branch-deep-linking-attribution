//
//  BNCXcode7Support.h
//  Branch-TestBed
//
//  Created by Edward on 10/26/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//


#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 100000
#warning Warning: Compiling with Xcode 7 support


#import <Foundation/Foundation.h>


@interface NSLocale (BranchXcode7Support)
- (NSString*) countryCode;
- (NSString*) languageCode;
@end


#endif

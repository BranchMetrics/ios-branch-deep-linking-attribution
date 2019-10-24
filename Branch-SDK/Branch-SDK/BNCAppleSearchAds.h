//
//  BNCAppleSearchAds.h
//  Branch
//
//  Created by Ernest Cho on 10/22/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCPreferenceHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCAppleSearchAds : NSObject

+ (BNCAppleSearchAds *)sharedInstance;

// checks Apple Search Ads and updates preferences.  This acquires a lock on BNCPreferenceHelper.
- (void)checkAppleSearchAdsSaveTo:(BNCPreferenceHelper *)preferenceHelper installDate:(NSDate *)installDate completion:(void (^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END

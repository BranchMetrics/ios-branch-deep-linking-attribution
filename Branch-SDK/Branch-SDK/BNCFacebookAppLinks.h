//
//  BNCFacebookAppLinks.h
//  Branch
//
//  Created by Ernest Cho on 10/24/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCPreferenceHelper.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCFacebookAppLinks : NSObject

+ (BNCFacebookAppLinks *)sharedInstance;

- (void)registerFacebookDeepLinkingClass:(id)appLinkUtility;

- (void)checkFacebookAppLinkSaveTo:(BNCPreferenceHelper *)preferenceHelper completion:(void (^_Nullable)(NSURL *__nullable appLink))completion;

@end

NS_ASSUME_NONNULL_END

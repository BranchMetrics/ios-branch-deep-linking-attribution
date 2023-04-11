//
//  BNCLocale.h
//  BranchSDK
//
//  Utility class to query country and language
//
//  Hides details of gathering country and language on iOS 8 and iOS 9. Remove once iOS 10 is the min version.
//
//  Created by Ernest Cho on 11/18/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCLocale : NSObject

- (nullable NSString *)country;
- (nullable NSString *)language;

@end

NS_ASSUME_NONNULL_END

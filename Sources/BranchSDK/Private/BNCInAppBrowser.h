//
//  BNCInAppBrowser.h
//  Branch
//
//  Created by Nidhi Dixit on 5/12/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCInAppBrowser : NSObject
+ (instancetype)sharedInstance;
- (void)openURLInSafariVC:(NSString *) urlStr;
@end

NS_ASSUME_NONNULL_END


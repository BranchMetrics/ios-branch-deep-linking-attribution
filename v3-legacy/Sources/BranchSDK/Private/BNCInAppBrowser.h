//
//  BNCInAppBrowser.h
//  Branch
//
//  Created by Nidhi Dixit on 5/12/25.
//  Copyright © 2025 Branch, Inc. All rights reserved.
//

#if !TARGET_OS_TV
#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCInAppBrowser : NSObject <SFSafariViewControllerDelegate>
/**
 Returns the shared singleton instance of `BNCInAppBrowser`.
 @return A shared instance of `BNCInAppBrowser`, or `nil` if `SFSafariViewController` is not available.
 */
+ (instancetype)sharedInstance;

/**
 Opens the given URL in a `SFSafariViewController`over  current top-most view controller.
 @param  url  The URL  to be opened.
 */
- (void)openURLInSafariVC:(NSURL *) url;

@end

NS_ASSUME_NONNULL_END

#endif

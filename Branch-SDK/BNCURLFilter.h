/**
 @file          BNCURLFilter.h
 @package       Branch-SDK
 @brief         Manages a list of sensitive URLs such as login data that should not be handled by Branch.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCURLFilter : NSObject

/**
 @brief Checks if a given URL should be ignored.

 @param url The URL to be checked.
 @return Returns true if the provided URL should be ignored.
*/
- (BOOL) shouldIgnoreURL:(NSURL*_Nullable)url;

/**
 @brief Returns the pattern that matches a URL, if any.

 @param url The URL to be checked.
 @return Returns the pattern matching the URL or `nil` if no patterns match.
*/
- (NSString*_Nullable) patternMatchingURL:(NSURL*_Nullable)url;

/// Refreshes the list of ignored URLs from the server.
- (void) updatePatternListWithCompletion:(void (^_Nullable) (NSError*_Nullable error, NSArray*_Nullable list))completion;

/// Is YES if the listed has already been updated from the server.
@property (assign, readonly, nonatomic) BOOL hasUpdatedPatternList;
@property (strong, nonatomic) NSArray<NSString*>*_Nullable patternList;
@end

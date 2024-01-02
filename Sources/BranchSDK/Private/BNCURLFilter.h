/**
 @file          BNCURLFilter.h
 @package       Branch-SDK
 @brief         Manages a list of sensitive URLs such as login data that should not be handled by Branch.

 @author        Edward Smith
 @date          February 14, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCURLFilter : NSObject

/**
 @brief Checks if a given URL should be ignored.
 
 @param url The URL to be checked.
 @return Returns true if the provided URL should be ignored.
 */
- (BOOL)shouldIgnoreURL:(NSURL *)url;

/**
 @brief Returns the pattern that matches a URL, if any.
 
 @param url The URL to be checked.
 @return Returns the pattern matching the URL or `nil` if no patterns match.
 */
- (nullable NSString *)patternMatchingURL:(NSURL *)url;

// Sets a list of ignored URL regex patterns
// Used for custom URL filtering and testing
- (void)useCustomPatternList:(NSArray<NSString *> *)patternList;

// Loads the saved list of ignored URL regex patterns
- (void)useSavedPatternList;

// Refreshes the list of ignored URL regex patterns from the server
- (void)updatePatternListFromServerWithCompletion:(void (^_Nullable) (void))completion;

@end

NS_ASSUME_NONNULL_END

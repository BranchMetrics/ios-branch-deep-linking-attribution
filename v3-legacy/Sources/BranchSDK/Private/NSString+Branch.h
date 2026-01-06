/**
 @file          NSString+Branch.h
 @package       Branch-SDK
 @brief         NSString Additions

 @author        Edward Smith
 @date          February 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface NSString (Branch)

///@discussion Compares the receiver to a masked string.  Masked characters (the '*' character) are
/// ignored for purposes of the compare.
///
///@return YES if string (ignoring any masked characters) is equal to the receiver.
- (BOOL)bnc_isEqualToMaskedString:(NSString * _Nullable)string;

@end

void BNCForceNSStringCategoryToLoad(void) __attribute__((constructor));

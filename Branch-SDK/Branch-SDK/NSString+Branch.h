

//--------------------------------------------------------------------------------------------------
//
//                                                                                 NSString+Branch.h
//                                                                                  Branch.framework
//
//                                                                                NSString Additions
//                                                                       Edward Smith, February 2017
//
//                                             -©- Copyright © 2017 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import <Foundation/Foundation.h>


@interface NSString (Branch)

///@discussion Compares the receiver to a masked string.  Masked characters (the '*' character) are
/// ignored for purposes of the compare.
///
///@return YES if string (ignoring any masked characters) is equal to the receiver.
- (BOOL) bnc_isEqualToMaskedString:(NSString*_Nullable)string;

///@return Returns a string that is truncated at the first null character.
- (NSString*_Nonnull) bnc_stringTruncatedAtNull;

@end

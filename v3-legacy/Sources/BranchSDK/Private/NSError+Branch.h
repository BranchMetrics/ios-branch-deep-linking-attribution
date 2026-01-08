/**
 @file          NSError+Branch.h
 @package       Branch-SDK
 @brief         Branch errors.

 @author        Qinwei Gong
 @date          November 2014
 @copyright     Copyright © 2014 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BNCErrorCode) {
    BNCInitError                    = 1000,
    BNCDuplicateResourceError       = 1001,
    BNCBadRequestError              = 1003,
    BNCServerProblemError           = 1004,
    BNCNilLogError                  = 1005, // Not used at the moment.
    BNCVersionError                 = 1006, // Not used at the moment.
    BNCNetworkServiceInterfaceError = 1007,
    BNCInvalidNetworkPublicKeyError = 1008,
    BNCContentIdentifierError       = 1009,
    BNCSpotlightNotAvailableError   = 1010,
    BNCSpotlightTitleError          = 1011,
    BNCSpotlightIdentifierError     = 1013,
    BNCSpotlightPublicIndexError    = 1014,
    BNCTrackingDisabledError        = 1015,
    BNCGeneralError                 = 1016, // General Branch SDK Error
    BNCDNSAdBlockerError                 = 1017,
    BNCVPNAdBlockerError                 = 1018,
    // Reflection and Google ODM Related Errors
    BNCClassNotFoundError                = 1019,
    BNCMethodNotFoundError               = 1020,
    BNCODCConversionManagerError         = 1021,
    BNCHighestError
};

@interface NSError (Branch)

+ (NSString *)bncErrorDomain;

+ (NSError *) branchErrorWithCode:(BNCErrorCode)errorCode;
+ (NSError *) branchErrorWithCode:(BNCErrorCode)errorCode error:(NSError *_Nullable)error;
+ (NSError *) branchErrorWithCode:(BNCErrorCode)errorCode localizedMessage:(NSString *_Nullable)message;

// Checks if an NSError looks like a DNS blocking error
+ (BOOL)branchDNSBlockingError:(NSError *)error;

// Checks if an NSError looks like a VPN blocking error
+ (BOOL)branchVPNBlockingError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

void BNCForceNSErrorCategoryToLoad(void) __attribute__((constructor));

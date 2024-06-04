/**
 @file          BNCKeyChain.h
 @package       Branch-SDK
 @brief         Simple access routines for secure keychain storage.

 @author        Edward Smith
 @date          January 8, 2018
 @copyright     Copyright © 2018 Branch. All rights reserved.
*/

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@interface BNCKeyChain : NSObject

/**
 @brief Remove all values for a service and key.

 @param service The name of the service under which to store the key.
 @param key The key to remove the value from. If `nil` is passed, all keys and values are removed for that service.
 @return Returns an `NSError` if an error occurs.
*/
+ (NSError * _Nullable) removeValuesForService:(NSString * _Nullable)service
                                           key:(NSString * _Nullable)key;


/**
 @brief Returns a date for the passed service and key.

 @param service The name of the service that the value is stored under.
 @param key The key that the value is stored under.
 @param error If an error occurs, and `error` is a pointer to an error pointer, the error is returned here.
 @return Returns the date stored under `service` and `key`, or `nil` if none found.
*/
+ (NSDate * _Nullable) retrieveDateForService:(NSString * _Nonnull)service
                                          key:(NSString * _Nonnull)key
                                        error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 @brief Stores a date in the keychain.

 @param date Date to store
 @param service The service name to store the item under.
 @param key The key to store the item under.
 @param accessGroup The iCloud security access group for sharing the item. Specify `nil` if item should not be shared.
 @return Returns an error if an error occurs.
 */
+ (NSError * _Nullable) storeDate:(NSDate * _Nonnull)date
                       forService:(NSString * _Nonnull)service
                              key:(NSString * _Nonnull)key
                 cloudAccessGroup:(NSString * _Nullable)accessGroup;

/**
 The security access group string is prefixed with the Apple Developer Team ID
 */
+ (NSString * _Nullable) securityAccessGroup;

@end

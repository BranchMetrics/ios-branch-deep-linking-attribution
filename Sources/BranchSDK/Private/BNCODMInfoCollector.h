//
//  BNCODMInfoCollector.h
//  BranchSDK
//
//  Created by Nidhi Dixit on 4/13/25.
//


#if !TARGET_OS_TV
#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

NS_ASSUME_NONNULL_BEGIN

//  Loads ODM Info either from device or pref helper
@interface BNCODMInfoCollector : NSObject

+ (BNCODMInfoCollector *_Nullable) instance;
/**
 * Checks if the given date is within the specified validity window from the current time.
 * @param initTime The reference date to check against.
 * @param timeInterval The validity window in seconds.
 * @return YES if the current time is within the validity window, NO otherwise.
 */
- (BOOL)isWithinValidityWindow:(NSDate *)initTime timeInterval:(NSTimeInterval)timeInterval;

/**
 * Loads ODM information with a specified timeout.
 * @param completion Optional completion handler called when ODM info is loaded.
 */
- (void)loadODMInfoWithCompletionHandler:(void (^_Nullable)(NSString * _Nullable odmInfo,  NSError * _Nullable error))completion;

- (void)fetchODMInfoFromDeviceWithInitDate:(NSDate *) date  andCompletion:(void (^)(NSString *odmInfo, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
#endif /* !TARGET_OS_TV */


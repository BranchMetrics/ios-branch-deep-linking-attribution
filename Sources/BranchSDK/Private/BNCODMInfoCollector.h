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

@property (nonatomic, copy, readwrite) NSString * _Nullable odmInfo;

- (BOOL)isWithinValidityWindow:(NSDate *)initTime timeInterval:(NSTimeInterval)timeInterval;
- (void)loadODMInfoWithCompletion:(void (^_Nullable)(NSString * _Nullable odmInfo,  NSError * _Nullable error))completion;
- (void)fetchODMInfoFromDeviceWithInitDate:(NSDate *) date  andCompletion:(void (^)(NSString *odmInfo, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
#endif /* !TARGET_OS_TV */


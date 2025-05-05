#import <Foundation/Foundation.h>

#import "ODCConversionTypes.h"

NS_ASSUME_NONNULL_BEGIN

/// The top level on-device conversion manager singleton that provides methods for fetching the
/// aggregate conversion info for conversion reports.
NS_SWIFT_NAME(ConversionManager)
@interface ODCConversionManager : NSObject

/// Returns the shared ConversionManager instance.
@property(class, nonatomic, readonly) ODCConversionManager *sharedInstance;

/// The SDK version in the format of three period-separated integers, such as "10.14.1".
@property(nonatomic, readonly) NSString *versionString;

/// Sets the timestamp when the application was first launched.
/// @param firstLaunchTime The timestamp when the application was first launched.
- (void)setFirstLaunchTime:(NSDate *)firstLaunchTime;

/// Asynchronously fetches the aggregate conversion info of the current app instance for conversion
/// reports.
///
/// The aggregate conversion info fetch could fail due to network failures etc.
///
/// @param interaction The type of interaction to fetch.
/// @param completion The completion handler to call when the fetch is complete. This handler is
///     executed on a system-defined global concurrent queue.
///     This completion handler takes the following parameters:
///     <b>aggregateConversionInfo</b> The aggregate conversion info of the current app instance, or
///         `nil` if it's not available.
///     <b>error</b> An error object that indicates why the request failed, or `nil` if the request
///         was successful.
///     When the aggregate conversion info is expired, both parameters are nil, i.e. the aggregate
///     conversion info is not available and there is no error.
- (void)fetchAggregateConversionInfoForInteraction:(ODCInteractionType)interaction
                                        completion:
                                            (void (^)(NSString *_Nullable aggregateConversionInfo,
                                                      NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

//
//  BNCCrashlyticsWrapper.h
//  Branch.framework
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Convenience class to dynamically wrap the Crashlytics SDK
 * if present. If it is not present, everything here is a no-op.
 */
@interface BNCCrashlyticsWrapper : NSObject

/// Reference to the Crashlytics.sharedInstance or nil.
@property (nonatomic, nullable, readonly) id crashlytics;

/// Convenience method to create new instances
+ (instancetype _Nonnull)wrapper;

/**
 * Use this method to set key values in a Crashlytics report. Note that
 * nil is acceptable for the value. Presumably this removes any key
 * previously set.
 *
 * This method name is deliberately chosen to match the Crashlytics
 * name in order to eliminate some compilation issues involving
 * unknown selectors.
 */
- (void)setObjectValue:(id _Nullable)value forKey:(NSString * _Nonnull)key;

@end

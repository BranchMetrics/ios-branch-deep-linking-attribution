//
//  BNCCrashlyticsWrapper.h
//  Branch.framework
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

/**
 * Convenience class to dynamically wrap the FIRCrashlytics SDK
 * if present. If it is not present, everything here is a no-op.
 */
@interface BNCCrashlyticsWrapper : NSObject

/// Convenience method to create new instances
+ (instancetype _Nonnull)wrapper;

/**
 * Use this method to set key values in a Crashlytics report.
 */
- (void)setCustomValue:(id _Nullable)value forKey:(NSString * _Nonnull)key;

@end

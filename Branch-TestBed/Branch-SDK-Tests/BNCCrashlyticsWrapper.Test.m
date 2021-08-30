//
//  BNCCrashlyticsWrapperTest.m
//  Branch-TestBed
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCCrashlyticsWrapper.h"
#import "BNCTestCase.h"

#pragma mark Crashlytics SDK Stand-In

@interface FIRCrashlytics : NSObject
+ (FIRCrashlytics *)crashlytics;
@property NSMutableDictionary *values;
- (void)setCustomValue:(id)value forKey:(NSString *)key;
-(id)getCustomValueForKey:(NSString *)key;
@end

@implementation FIRCrashlytics

+ (FIRCrashlytics *)crashlytics {
    @synchronized (self) {
        static FIRCrashlytics * sharedCrashlytics = nil;
        if (!sharedCrashlytics) sharedCrashlytics = [[self alloc] init];
        return sharedCrashlytics;
    }
}

- (void)setCustomValue:(id)value forKey:(NSString *)key {
    if (!_values) {
        _values = [[NSMutableDictionary alloc] init];
    }
    [_values setObject:value forKey:key];
}

-(id)getCustomValueForKey:(NSString *)key {
    return [_values valueForKey:key];
}
@end

#pragma mark - BNCCrashlyticsWrapperTest

@interface BNCCrashlyticsWrapperTest : BNCTestCase
@end

@implementation BNCCrashlyticsWrapperTest

- (void) testSetValue {

    BNCCrashlyticsWrapper *wrapper = [BNCCrashlyticsWrapper wrapper];
    NSString *value = @"TestString";
    NSString *key = @"TestKey";
    
    [wrapper setCustomValue:value forKey:key];
    
    XCTAssertEqual([[FIRCrashlytics crashlytics] getCustomValueForKey:key], value);
}

@end

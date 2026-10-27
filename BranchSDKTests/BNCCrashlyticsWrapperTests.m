//
//  BNCCrashlyticsWrapperTest.m
//  Branch-TestBed
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCCrashlyticsWrapper.h"
#import "Branch.h"
#import "BranchConfiguration.h"
#import "BNCConfig.h"

@interface Branch (BNCCrashlyticsWrapperTest)
+ (void)resetInitializationGuardForTesting;
@end

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

@interface BNCCrashlyticsWrapperTests : XCTestCase
@end

@implementation BNCCrashlyticsWrapperTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSetValue {
    BNCCrashlyticsWrapper *wrapper = [BNCCrashlyticsWrapper wrapper];
    NSString *value = @"TestString";
    NSString *key = @"TestKey";
    
    [wrapper setCustomValue:value forKey:key];
    
    XCTAssertEqual([[FIRCrashlytics crashlytics] getCustomValueForKey:key], value);
}

// +initialize: writes the SDK version to Crashlytics.
- (void)testInitializeAddsSDKVersionToCrashlytics {
    [FIRCrashlytics crashlytics].values = nil;

    [Branch resetInitializationGuardForTesting];
    [Branch initialize:[[BranchConfiguration alloc] initWithKey:@"key_live_hcnegAumkH7Kv18M8AOHhfgiohpXq5tB"]];

    XCTAssertEqualObjects([[FIRCrashlytics crashlytics] getCustomValueForKey:@"io.branch.sdk.version"], BNC_SDK_VERSION);
}

@end

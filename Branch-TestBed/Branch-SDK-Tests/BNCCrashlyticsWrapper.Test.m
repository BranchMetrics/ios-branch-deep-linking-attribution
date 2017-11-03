//
//  BNCCrashlyticsWrapperTest.m
//  Branch-TestBed
//
//  Created by Jimmy Dee on 7/18/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCCrashlyticsWrapper.h"
#import "BNCTestCase.h"
#import <OCMock/OCMock.h>

#pragma mark Crashlytics SDK Stand-In

@interface Crashlytics : NSObject
+ (Crashlytics *)sharedInstance;
- (void)setObjectValue:(id)value forKey:(NSString *)key;
- (void)setIntValue:(int)value forKey:(NSString *)key;
- (void)setFloatValue:(float)value forKey:(NSString *)key;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key;
@end

@implementation Crashlytics

+ (Crashlytics *)sharedInstance {
    @synchronized (self) {
        static Crashlytics * sharedCrashlytics = nil;
        if (!sharedCrashlytics) sharedCrashlytics = [[self alloc] init];
        return sharedCrashlytics;
    }
}

- (void)setObjectValue:(id)value forKey:(NSString *)key     {}
- (void)setIntValue:(int)value forKey:(NSString *)key       {}
- (void)setFloatValue:(float)value forKey:(NSString *)key   {}
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key     {}

@end

#pragma mark - BNCCrashlyticsWrapperTest

@interface BNCCrashlyticsWrapperTest : BNCTestCase
@end

@implementation BNCCrashlyticsWrapperTest

- (void)testInitialization {
    id classMock = OCMClassMock(Crashlytics.class);
    Crashlytics *expected = [[Crashlytics alloc] init];

    OCMStub([classMock sharedInstance]).andReturn(expected);

    BNCCrashlyticsWrapper *wrapper = [BNCCrashlyticsWrapper wrapper];
    Crashlytics *actual = wrapper.crashlytics;

    // The crashlytics property is whatever sharedInstance returns
    XCTAssertEqual(expected, actual);
}

- (void) testSetValue {
    id classMock = OCMClassMock(Crashlytics.class);
    OCMStub([classMock setObjectValue:[OCMArg any] forKey:[OCMArg any]]);
    OCMStub([classMock setIntValue:0 forKey:[OCMArg any]]);
    OCMStub([classMock setFloatValue:0.0 forKey:[OCMArg any]]);
    OCMStub([classMock setBoolValue:YES forKey:[OCMArg any]]);

    BNCCrashlyticsWrapper *wrapper = [BNCCrashlyticsWrapper wrapper];
    [wrapper setObjectValue:@"stringValue" forKey:@"stringKey"];
    [wrapper setIntValue:0 forKey:@"intKey"];
    [wrapper setFloatValue:0.0 forKey:@"floatKey"];
    [wrapper setIntValue:YES forKey:@"boolKey"];

    [classMock verify];
}

@end

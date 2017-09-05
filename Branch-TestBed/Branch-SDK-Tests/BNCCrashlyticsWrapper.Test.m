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

// stand-in for Crashlytics SDK
@interface Crashlytics : NSObject
+ (Crashlytics *)sharedInstance;

- (void)setObjectValue:(id)value forKey:(NSString *)key;
@end

@implementation Crashlytics
+ (Crashlytics *)sharedInstance
{
    return [[self alloc] init];
}

- (void)setObjectValue:(id)value forKey:(NSString *)key
{
}

- (void)setIntValue:(int)value forKey:(NSString *)key
{
}

- (void)setFloatValue:(float)value forKey:(NSString *)key
{
}

- (void)setBoolValue:(BOOL)value forKey:(NSString *)key
{
}
@end

// test case
@interface BNCCrashlyticsWrapperTest : BNCTestCase
@end

@implementation BNCCrashlyticsWrapperTest

- (void)testInitialization
{
    id classMock = OCMClassMock(Crashlytics.class);
    Crashlytics *expected = [[Crashlytics alloc] init];

    OCMStub([classMock sharedInstance]).andReturn(expected);

    BNCCrashlyticsWrapper *wrapper = [BNCCrashlyticsWrapper wrapper];
    Crashlytics *actual = wrapper.crashlytics;

    // The crashlytics property is whatever sharedInstance returns
    XCTAssertEqual(expected, actual);
}

// TODO: Test setObjectValue:forKey:

@end

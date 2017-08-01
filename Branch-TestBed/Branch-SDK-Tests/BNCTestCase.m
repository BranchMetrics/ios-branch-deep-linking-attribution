//
//  BNCTestCase.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"

@interface BNCTestCase ()
@property (assign, nonatomic) BOOL hasExceededExpectations;
@end

@implementation BNCTestCase

+ (void)setUp {
    [super setUp];
    
    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    if (!preferenceHelper.deviceFingerprintID) {
        preferenceHelper.deviceFingerprintID = @"foo_fingerprint";
    }
    if (!preferenceHelper.identityID) {
        preferenceHelper.identityID = @"foo_identity";
    }
    if (!preferenceHelper.sessionID) {
        preferenceHelper.sessionID = @"foo_sesion";
    }
    preferenceHelper.isDebug = NO;
}

- (void)setUp {
    [super setUp];
    [self resetExpectations];
}

- (void) testFailure {
    // Un-comment the next line to test a failure case:
    // XCTAssert(NO, @"Testing a test failure!");
    NSString * bundleID = [NSBundle mainBundle].bundleIdentifier;
    NSLog(@"The test bundleID is '%@'.", bundleID);
}

- (void)resetExpectations {
    self.hasExceededExpectations = NO;
}

- (void)safelyFulfillExpectation:(XCTestExpectation *)expectation {
    if (!self.hasExceededExpectations) {
        [expectation fulfill];
    }
}

- (void)awaitExpectations {
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        self.hasExceededExpectations = YES;
    }];
}

- (id)stringMatchingPattern:(NSString *)pattern {
    NSRegularExpression *regex =
        [[NSRegularExpression alloc]
            initWithPattern:pattern
            options:NSRegularExpressionCaseInsensitive
            error:nil];

    return [OCMArg checkWithBlock:^BOOL(NSString *param) {
        return [regex numberOfMatchesInString:param
            options:kNilOptions range:NSMakeRange(0, param.length)] > 0;
    }];
}

static BOOL _testBreakpoints = NO;

+ (BOOL) testBreakpoints {
    return _testBreakpoints;
}

+ (void) initialize {
    if (self != [BNCTestCase self]) return;

    // Load test options from environment variables:

    NSDictionary<NSString*, NSString*> *environment = [NSProcessInfo processInfo].environment;
    NSString *BNCTestBreakpoints = environment[@"BNCTestBreakpoints"];
    if ([BNCTestBreakpoints boolValue]) {
        _testBreakpoints = YES;
    }
}

@end

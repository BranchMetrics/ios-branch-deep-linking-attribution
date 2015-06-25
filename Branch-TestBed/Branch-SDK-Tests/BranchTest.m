//
//  BranchTest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchTest.h"
#import "BNCPreferenceHelper.h"

@interface BranchTest ()

@property (assign, nonatomic) BOOL hasExceededExpectations;

@end

@implementation BranchTest

+ (void)setUp {
    [super setUp];
    
    if (![BNCPreferenceHelper getDeviceFingerprintID]) {
        [BNCPreferenceHelper setDeviceFingerprintID:@"foo_fingerprint"];
    }

    if (![BNCPreferenceHelper getIdentityID]) {
        [BNCPreferenceHelper setIdentityID:@"foo_identity"];
    }

    if (![BNCPreferenceHelper getSessionID]) {
        [BNCPreferenceHelper setSessionID:@"foo_sesion"];
    }
}

- (void)setUp {
    [super setUp];
    
    [self resetExpectations];
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
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];

    return [OCMArg checkWithBlock:^BOOL(NSString *param) {
        return [regex numberOfMatchesInString:param options:kNilOptions range:NSMakeRange(0, param.length)] > 0;
    }];
}

@end

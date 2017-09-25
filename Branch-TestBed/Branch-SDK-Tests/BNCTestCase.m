//
//  BNCTestCase.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 4/27/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"
#import "BNCLog.h"

BOOL BNCTestStringMatchesRegex(NSString *string, NSString *regex) {
    NSError *error = nil;
    NSRegularExpression* nsregex = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
    if (error) {
        NSLog(@"Error in regex pattern: %@.", error);
        return NO;
    }
    NSRange stringRange = NSMakeRange(0, string.length);
    NSTextCheckingResult *match = [nsregex firstMatchInString:string options:0 range:stringRange];
    return NSEqualRanges(match.range, stringRange);
}

#pragma mark - BNCTestCase

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

- (NSString*) stringFromBundleWithKey:(NSString*)key {
    NSString *const kItemNotFound = @"<Item-Not-Found>";
    NSString *resource =
        [[NSBundle bundleForClass:self.class] localizedStringForKey:key value:kItemNotFound table:@"Branch-SDK-Tests"];
    if ([resource isEqualToString:kItemNotFound]) resource = nil;
    return resource;
}

- (NSMutableDictionary*) mutableDictionaryFromBundleJSONWithKey:(NSString*)key {

    NSString *jsonString = [self stringFromBundleWithKey:key];
    XCTAssertTrue(jsonString, @"Can't load '%@' resource from bundle JSON!", key);

    NSError *error = nil;
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
            options:0 error:&error];
    XCTAssertNil(error);
    XCTAssert(dictionary);
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    return mutableDictionary;
}

static BOOL _testBreakpoints = NO;

+ (BOOL) testBreakpoints {
    return _testBreakpoints;
}

+ (void) initialize {
    if (self != [BNCTestCase self]) return;
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    // Load test options from environment variables:

    NSDictionary<NSString*, NSString*> *environment = [NSProcessInfo processInfo].environment;
    NSString *BNCTestBreakpoints = environment[@"BNCTestBreakpoints"];
    if ([BNCTestBreakpoints boolValue]) {
        _testBreakpoints = YES;
    }
}

@end

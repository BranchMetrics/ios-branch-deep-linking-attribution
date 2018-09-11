/**
 @file          BNCTestCase.m
 @package       Branch-SDK-Tests
 @brief         The Branch testing framework super class.

 @author        Edward Smith
 @date          April 2017
 @copyright     Copyright © 2017 Branch. All rights reserved.
*/

#import "BNCTestCase.h"
#import "BNCLog.h"

NSString* kTestStringResourceName = @"BNCTestCase"; // File is 'BNCTestCase.strings'. Omit the '.string'.

#pragma mark - BNCTestStringMatchesRegex

BOOL BNCTestStringMatchesRegex(NSString *string, NSString *regex) {
    NSError *error = nil;
    NSRegularExpression* nsregex =
        [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
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
        [[NSBundle bundleForClass:self.class]
            localizedStringForKey:key value:kItemNotFound table:kTestStringResourceName];
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

static BOOL _breakpointsAreEnabledInTests = NO;

+ (BOOL) breakpointsAreEnabledInTests {
    return _breakpointsAreEnabledInTests;
}

+ (void) initialize {
    if (self != [BNCTestCase self]) return;
    BNCLogSetDisplayLevel(BNCLogLevelAll);

    // Load test options from environment variables:

    NSDictionary<NSString*, NSString*> *environment = [NSProcessInfo processInfo].environment;
    NSString *BNCTestBreakpoints = environment[@"BNCTestBreakpointsEnabled"];
    if ([BNCTestBreakpoints boolValue]) {
        _breakpointsAreEnabledInTests = YES;
    }
}

@end

//
//  BNCPasteboardTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 7/19/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPasteboard.h"

@interface BNCPasteboardTests : XCTestCase

@property (nonatomic, assign, readwrite) NSString *testString;
@property (nonatomic, strong, readwrite) NSURL *testBranchURL;

@end

@implementation BNCPasteboardTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.testString = @"Pasteboard String";
    self.testBranchURL = [NSURL URLWithString:@"https://123.app.link"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)addStringToPasteboard {
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        [UIPasteboard.generalPasteboard setString:self.testString];
    }
#endif
}

- (void)addBranchURLToPasteboard {
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        [UIPasteboard.generalPasteboard setURL:self.testBranchURL];
    }
#endif
}

- (void)addNonBranchURLToPasteboard {
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        [UIPasteboard.generalPasteboard setURL:[NSURL URLWithString:@"https://www.apple.com"]];
    }
#endif
}

- (void)clearPasteboard {
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        // cannot delete items from the pasteboard, but we can put something else on there
        [[UIPasteboard generalPasteboard] setString:@""];
    }
#endif
}

- (NSString *)getStringFromClipboard {
    NSString *string = nil;
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        string = [UIPasteboard.generalPasteboard string];
    }
#endif
    return string;
}

- (NSURL *)getURLFromPasteboard {
    NSURL *url = nil;
#if !TARGET_OS_TV
    if (@available(iOS 10.0, *)) {
        url = [UIPasteboard.generalPasteboard URL];
    }
#endif
    return url;
}

- (void)testStringUtilityMethods {
    
    // set and retrieve a string
    [self addStringToPasteboard];
    NSString *tmp = [self getStringFromClipboard];
    XCTAssert([self.testString isEqualToString:tmp]);
    
    // overwrite the pasteboard
    [self clearPasteboard];
    tmp = [self getStringFromClipboard];
    XCTAssert([@"" isEqualToString:tmp]);
}

- (void)testURLUtilityMethods {
    
    // set and retrieve a url
    [self addBranchURLToPasteboard];
    NSURL *tmp = [self getURLFromPasteboard];
    XCTAssert([self.testBranchURL.absoluteString isEqualToString:tmp.absoluteString]);
    
    // overwrite the pasteboard
    [self clearPasteboard];
    tmp = [self getURLFromPasteboard];
    XCTAssertNil(tmp);
}

- (void)testDefaultState {
    // host app sets this to true, should consider a no-op test host
    XCTAssertTrue([BNCPasteboard sharedInstance].checkOnInstall);
}

- (void)testIsUrlOnPasteboard {
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    [self addBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    [self clearPasteboard];
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);
}

- (void)testCheckForBranchLink {
    [self addBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssert([self.testBranchURL.absoluteString isEqualToString:tmp.absoluteString]);
    
    [self clearPasteboard];
}

- (void)testCheckForBranchLink_nonBranchLink {
    [self addNonBranchURLToPasteboard];
    XCTAssertTrue([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssertNil(tmp);
    
    [self clearPasteboard];
}

- (void)testCheckForBranchLink_noLink {
    [self addStringToPasteboard];
    XCTAssertFalse([[BNCPasteboard sharedInstance] isUrlOnPasteboard]);

    NSURL *tmp = [[BNCPasteboard sharedInstance] checkForBranchLink];
    XCTAssertNil(tmp);
    
    [self clearPasteboard];
}

@end

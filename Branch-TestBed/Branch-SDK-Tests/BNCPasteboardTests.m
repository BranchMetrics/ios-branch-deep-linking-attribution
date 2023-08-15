//
//  BNCPasteboardTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 7/19/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCPasteboard.h"
#import "Branch.h"

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
    [UIPasteboard.generalPasteboard setString:self.testString];
#endif
}

- (void)addBranchURLToPasteboard {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setURL:self.testBranchURL];
#endif
}

- (void)addNonBranchURLToPasteboard {
#if !TARGET_OS_TV
    [UIPasteboard.generalPasteboard setURL:[NSURL URLWithString:@"https://www.apple.com"]];
#endif
}

- (void)clearPasteboard {
#if !TARGET_OS_TV
    // cannot delete items from the pasteboard, but we can put something else on there
    [[UIPasteboard generalPasteboard] setString:@""];
#endif
}

- (NSString *)getStringFromClipboard {
    NSString *string = nil;
#if !TARGET_OS_TV
    string = [UIPasteboard.generalPasteboard string];
#endif
    return string;
}

- (NSURL *)getURLFromPasteboard {
    NSURL *url = nil;
#if !TARGET_OS_TV
    url = [UIPasteboard.generalPasteboard URL];
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

#if 0
// This test fails intermittently when executed with other tests - depending upon the order in which its executed
- (void) testPassPasteControl {
#if !TARGET_OS_TV
    if (@available(iOS 16.0, macCatalyst 16.0, *)) {
        
        long long timeStamp = ([[NSDate date] timeIntervalSince1970] - 5*60)*1000; // 5 minute earlier timestamp
        NSString *urlString = [NSString stringWithFormat:@"https://bnctestbed-alternate.app.link/9R7MbTmnRtb?__branch_flow_type=viewapp&__branch_flow_id=1105940563590163783&__branch_mobile_deepview_type=1&nl_opt_in=1&_cpts=%lld", timeStamp];
        NSURL *testURL = [[NSURL alloc] initWithString:urlString];
            
        NSArray<NSItemProvider *> *itemProviders = @[[[NSItemProvider alloc] initWithItem:testURL typeIdentifier:UTTypeURL.identifier]];
        XCTestExpectation *openExpectation = [self expectationWithDescription:@"Test open"];

        [[Branch getInstance] initSessionWithLaunchOptions:@{} andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
            [openExpectation fulfill];
            XCTAssertNil(error);
        }];
        
        [[Branch getInstance] passPasteItemProviders:itemProviders];
        [self waitForExpectationsWithTimeout:5.0 handler:NULL];
       
    }
#endif
}
#endif

@end

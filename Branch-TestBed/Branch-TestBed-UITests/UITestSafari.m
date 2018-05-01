//
//  UITestSafari.m
//  Branch-TestBed-UITests
//
//  Created by Parth Kalavadia on 8/2/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <XCTest/XCTest.h>
//#import "Branch/NSString+Branch.h"

// Ignore UITests availability for iOS 8 and lower in this example.
#pragma clang diagnostic ignored "-Wpartial-availability"

static NSTimeInterval const kDeepLinkSleepTimeInterval = 10.0;
static NSTimeInterval const kLoadWikiPageTimeInterval  = 3.0;
static NSString* const kWikiPageURL =
    @"https://github.com/BranchMetrics/ios-branch-deep-linking/wiki/"
     "UITest-for-Testbed-App-for-Universal-links";
static NSString* const kUniversalLinkTag = @"Universal Link TestBed Obj-c";

#pragma mark - UITestSafari

@interface UITestSafari : XCTestCase
@end

@interface XCUIApplication (Private)
- (id)initPrivateWithPath:(NSString *)path bundleID:(NSString *)bundleID;
- (void)resolve;
@end

@implementation UITestSafari

- (void)setUp {
    [super setUp];

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;

    // UI tests must launch the application that they test.
    // Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation -
    // required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testDeepLinking {
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationFaceUp;
    
    XCUIApplication *safariApp = [self openSafariWithUrl:kWikiPageURL];
    [safariApp.links[kUniversalLinkTag] tap];
    sleep(kDeepLinkSleepTimeInterval);
    
    XCUIApplication *currentApp = [[XCUIApplication alloc] init];
    XCUIElement* element = currentApp.textViews[@"DeepLinkData"];
    XCTAssertTrue([element.value containsString:@"Successfully Deeplinked"]);
}

-(XCUIApplication *) openSafariWithUrl:(NSString*) url {
    XCUIApplication *app =
        [[XCUIApplication alloc] initPrivateWithPath:nil bundleID:@"com.apple.mobilesafari"];
    [app launch];
    sleep(1.0);
    [app.otherElements[@"URL"] tap];
    [app.textFields[@"Search or enter website name"] tap];
    [app typeText:url];
    [app.buttons[@"Go"] tap];
    sleep(kLoadWikiPageTimeInterval);
    return app;
}

@end

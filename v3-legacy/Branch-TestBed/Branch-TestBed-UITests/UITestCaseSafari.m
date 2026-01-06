//
//  UITestCaseSafari.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/25/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"

@interface UITestCaseSafari : UITestCaseTestBed

@end

@implementation UITestCaseSafari

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
}

- (void)testSafari1OpenURLWarmApp {
    
    // Launch App and wait for some time
    [[[XCUIApplication alloc] init] launch];
    sleep(1);
    
    // Tap on URL
    [self clickLinkInWebPage:@"TestWebPage.html"];
    sleep(1);
    
    // Check if app is launched
    [self launchAppAndValidateData];
}

- (void)testSafari2OpenURLColdApp {
    
    // Terimnate App and wait for some time
    [[[XCUIApplication alloc] init] terminate];
    sleep(5);
    
    // Tap on URL
    [self clickLinkInWebPage:@"TestWebPage.html"];
    sleep(1);
    
    // Check if app is launched
    [self launchAppAndValidateData];
}

- (void) testSafari3PrivateWindowColdApp
{
    // Terimnate App and wait for some time
    [[[XCUIApplication alloc] init] terminate];
    sleep(5);
    [self openLinkAndValidateInPrivateWindow];
}

- (void) testSafari4PrivateWindowWarmApp
{
    // Launch App and wait for some time
    [[[XCUIApplication alloc] init] launch];
    sleep(5);
    [self openLinkAndValidateInPrivateWindow];
}

- (void)testSafari5DisableUniversalLink {

    // Terminate App
    [[[XCUIApplication alloc] init] terminate];

    // Open Link in New Tab - This will disable Universal links
    [self OpenLinkInNewTab:@"TestWebPage.html"];

    // Verify app is not launched.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    if ([ app waitForExistenceWithTimeout:5] != NO) {
        sleep(1);
        [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
        XCTFail("Application Launched - Universal Link is still working");
    }
}

- (void)testSafari6EnableUniversalLink {

    // Terminate App
    [[[XCUIApplication alloc] init] terminate];
    sleep(1);

    // Open Link in New Tab - This will disable Universal links
    [self OpenLinkWithMenuToEnableUniversalLink:@"TestWebPage.html"];

    // Verify app is not laucnhed.
    sleep(1);
    [self launchAppAndValidateData];
}

- (void)launchAppAndValidateData
{
    // Check if app is launched and validate deep link data
    XCUIApplication *app = [[XCUIApplication alloc] init];
    if ([ app waitForExistenceWithTimeout:15] != NO) {
        sleep(2);
        NSString *deepLinkData = app.textViews[@"DeepLinkData"].value;
        XCTAssertTrue([deepLinkData containsString:self.deeplinkDataToCheck]);
        [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    } else {
        XCTFail("Application not launched");
    }
}

- (void)openLinkAndValidateInPrivateWindow
{
    // Activate Safari
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
    [safariApp activate];
    sleep(1);
    
    // Click Tabs button
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Tabs"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate] tap];
    sleep(1);
    
    // Click Private
    NSPredicate *predicatePrivateWindow = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Private"]];
    XCUIElement *privateWindowToggleButton = [[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicatePrivateWindow];
    if (!privateWindowToggleButton.isSelected) {
        [privateWindowToggleButton tap];
    }
    sleep(1);
    
    // Click New Tab
    NSPredicate *predicateAddTab = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"New tab"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicateAddTab] tap];
    sleep(1);
    
    // Open Web page
    [safariApp.textFields[@"Search or enter website name"] tap];
    [safariApp typeText:@"https://ndixit-branch.github.io/TestWebPage.html"];
    [safariApp.buttons[@"Go"] tap];
    
    // Click Link
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    [testBedLink tap];
    sleep(1);
    
    // Select option open
    NSPredicate *predicateOpen = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Open"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeButton] elementMatchingPredicate:predicateOpen] tap];
    
    // Verify if deep link data if app is launched
    XCUIApplication *app = [[XCUIApplication alloc] init];
    if ([ app waitForExistenceWithTimeout:15] != NO) {
        sleep(1);
        NSString *deepLinkData = app.textViews[@"DeepLinkData"].value;
        XCTAssertTrue([deepLinkData containsString:self.deeplinkDataToCheck]);
        [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    } else {
        XCTFail("Application not launched");
    }
    
    // Terminate app and disable private browsing
    [app terminate];
    [safariApp activate];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate] tap];
    sleep(1);
    if (privateWindowToggleButton.isSelected) {
        [privateWindowToggleButton tap];
    }
    NSPredicate *predicateDone = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Done"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicateDone] tap];
}

@end

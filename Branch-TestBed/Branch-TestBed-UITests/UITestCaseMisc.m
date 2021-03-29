//
//  UITestCaseMisc.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 2/26/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"
#import "Branch.h"
#import "BranchEvent.h"

@interface UITestCaseMisc : UITestCaseTestBed

@end

@implementation UITestCaseMisc

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
}

- (void)testShareLink {
    
    // Tap on 'Creat Branch Link' and then 'Share Link'
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self disableTracking:FALSE];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Create Branch Link"]/*[[".cells",".buttons[@\"Create Branch Link\"].staticTexts[@\"Create Branch Link\"]",".staticTexts[@\"Create Branch Link\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [tablesQuery.staticTexts[@"Share Link"] tap];
    sleep(3);
    
    // Copy Link
    [[[[app/*@START_MENU_TOKEN@*/.collectionViews/*[[".otherElements[@\"ActivityListView\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons[@"Copy"].otherElements containingType:XCUIElementTypeImage identifier:@"copy"] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element tap];
    sleep(3);
    
    // Assert Link is copied in Pasteboard
    NSString *pasteboardString = [UIPasteboard generalPasteboard].string;
    if ([pasteboardString containsString:@"Shared through 'Pasteboard'"] != YES) {
        XCTFail("Link not copied");
    }
}

- (void)testCreateAndOpenURL {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self disableTracking:FALSE];
    
    //Tap "Create Branch Link" and assert text Field "Branch Link" shows link
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery.staticTexts[@"Create Branch Link"] tap];
    XCUIElement *branchLinkTextField = tablesQuery.textFields[@"Branch Link"];
    NSString *shortURL = branchLinkTextField.value;
    XCTAssertNotNil(shortURL);
    
    // Tap "Open Branch Link" and assert deep link data
    [tablesQuery.buttons[@"Open Branch Link"] tap];
    sleep(1);
    NSString *deepLinkData = app.textViews[@"DeepLinkData"].value;
    self.deeplinkDataToCheck = @"This text was embedded as data in a Branch link with the following characteristics:\n\ncanonicalUrl: https://dev.branch.io/getting-started/deep-link-routing/guide/ios/\n  title: Content Title\n  contentDescription: My Content Description\n  imageUrl: https://pbs.twimg.com/profile_images/658759610220703744/IO1HUADP.png\n";
    NSLog(@"%@" , self.deeplinkDataToCheck);
    XCTAssertTrue([deepLinkData containsString:self.deeplinkDataToCheck]);
    
}

- (void)testReferringParams
{
    // Launch App, disable tracking and logout
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self disableTracking:FALSE];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"SimulateLogout"]/*[[".cells",".buttons[@\"SimulateLogout\"].staticTexts[@\"SimulateLogout\"]",".staticTexts[@\"SimulateLogout\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.alerts[@"Logout succeeded"].scrollViews.otherElements.buttons[@"OK"] tap];

    // Tap 'View FirstReferringParams' and copy params
    XCUIElement *branchTestbedButton = app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"];
    XCUIElement *viewFirstreferringparamsStaticText = tablesQuery.staticTexts[@"View FirstReferringParams"];
    [viewFirstreferringparamsStaticText tap];
    NSString *viewFirstreferringString = app.textViews[@"DeepLinkData"].value;
    XCTAssertTrue([viewFirstreferringString containsString:@"{\n}"]);
    [branchTestbedButton tap];
    
    // Tap 'View LatestReferringParams' and copy params
    XCUIElement *viewLatestreferringparamsStaticText = tablesQuery.staticTexts[@"View LatestReferringParams"];
    [viewLatestreferringparamsStaticText tap];
    NSString *viewLatesttreferringString = app.textViews[@"DeepLinkData"].value;
    XCTAssertTrue([viewLatesttreferringString containsString:@"{\n}"]);
    [branchTestbedButton tap];
    
    // Tap "Set User ID" and then Tap 'View FirstReferringParams' & 'View LatestReferringParams' and copy params again
    [tablesQuery.buttons[@"Set User ID"] tap];
    [branchTestbedButton tap];
    sleep(1);
    [viewFirstreferringparamsStaticText tap];
    viewFirstreferringString = app.textViews[@"DeepLinkData"].value;
    [branchTestbedButton tap];
    [viewLatestreferringparamsStaticText tap];
     viewLatesttreferringString = app.textViews[@"DeepLinkData"].value;
    [branchTestbedButton tap];

    // Re-launch app.
    [app terminate];
    [app launch];
    
    // Tap on 'View FirstReferringParams' & 'View LatestReferringParams' again and check viewFirstreferringparamsStaticText is still same and viewLatestreferringparamsStaticText shows latest paramms.
    [viewFirstreferringparamsStaticText tap];
    NSString *viewFirstreferringStringNew = app.textViews[@"DeepLinkData"].value;
    [branchTestbedButton tap];
    XCTAssertTrue([viewFirstreferringString isEqualToString:viewFirstreferringStringNew]);
    [viewLatestreferringparamsStaticText tap];
    viewLatesttreferringString = app.textViews[@"DeepLinkData"].value;
    [branchTestbedButton tap];
    
    NSString *viewLatesttreferringStringNew =@"{\n    \"+clicked_branch_link\" = 0;\n    \"+is_first_session\" = 0;\n}";

    XCTAssertTrue([viewLatesttreferringString isEqualToString:viewLatesttreferringStringNew]);
    
}

- (void)testFBParams
{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self disableTracking:FALSE];
    
    XCUIElementQuery *tablesQuery = [[XCUIApplication alloc] init].tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.buttons[@"Set FB Params"]/*[[".cells.buttons[@\"Set FB Params\"]",".buttons[@\"Set FB Params\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    setFBParams = TRUE;
    checkFBParams = TRUE;
    [self sendEvent:BranchStandardEventAddToCart];
    XCUIElement *branchTestbedButton = app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"];
    [branchTestbedButton tap];
    [tablesQuery/*@START_MENU_TOKEN@*/.buttons[@"Clear FB Params"]/*[[".cells.buttons[@\"Clear FB Params\"]",".buttons[@\"Clear FB Params\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ tap];
    setFBParams = FALSE;
    [self sendEvent:BranchStandardEventAddToCart];
    checkFBParams = FALSE;
}

@end

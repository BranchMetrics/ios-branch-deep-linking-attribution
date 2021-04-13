//
//  UITestSetIdentity.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/6/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchEvent.h"
#import "UITestCaseTestBed.h"

@interface UITestSetIdentity : UITestCaseTestBed

@end

@implementation UITestSetIdentity

- (void)setUp {
    [super setUp];
    [[[XCUIApplication alloc] init] launch];
    [self disableTracking:FALSE];
}

- (void)tearDown {
}
/*
 Test Case:
 when setIdentity(“a_user_name”) is invoked, it should call out to /v1/identify
 */
- (void)testSetIdentity {
    
    // Click Logout
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"SimulateLogout"]/*[[".cells",".buttons[@\"SimulateLogout\"].staticTexts[@\"SimulateLogout\"]",".staticTexts[@\"SimulateLogout\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.alerts[@"Logout succeeded"].scrollViews.otherElements.buttons[@"OK"] tap];
    
    // Click 'Set User ID'
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Set User ID"]/*[[".cells",".buttons[@\"Set User ID\"].staticTexts[@\"Set User ID\"]",".staticTexts[@\"Set User ID\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    
    // Check for email ID
    NSString *dataReturned = app.textViews[@"DeepLinkData"].value;
    XCTAssertTrue([dataReturned containsString:@"Identity set to: ben@emailaddress.io"]);
    
    // Check for URL, identity, identity_id
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Load Logs for Last Command"]/*[[".cells",".buttons[@\"Load Logs for Last Command\"].staticTexts[@\"Load Logs for Last Command\"]",".staticTexts[@\"Load Logs for Last Command\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    XCUIElement *deeplinkdataTextView = app.textViews[@"DeepLinkData"];
    [deeplinkdataTextView tap];
    NSString *prevLogResults = app.textViews[@"DeepLinkData"].value;
    NSString *url;
    NSDictionary *json;
    [self parseURL:&url andJSON:&json FromLogs:prevLogResults];
    XCTAssertNotNil(url);
    XCTAssertNotNil(json);
    XCTAssertTrue([url containsString:@"/v1/profile"]);

    NSDictionary *identity = [json objectForKey:@"identity"];
    NSString *identity_id = [json objectForKey:@"identity_id"];
    XCTAssertNotNil(identity);
    XCTAssertNotNil(identity_id);

    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    
    
    // Send Event & check if it contains identity & identity_id
    setIdentity = TRUE;
    checkIdentity = TRUE;
    [self sendEvent:BranchStandardEventAddToCart];
    
    // Logout
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"SimulateLogout"]/*[[".cells",".buttons[@\"SimulateLogout\"].staticTexts[@\"SimulateLogout\"]",".staticTexts[@\"SimulateLogout\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.alerts[@"Logout succeeded"].scrollViews.otherElements.buttons[@"OK"] tap];
    
    // Send Event & check if it DOES NOT contains identity & identity_id
    setIdentity = FALSE;
    [self sendEvent:BranchStandardEventAddToCart];
    checkIdentity = FALSE;
    
}

@end

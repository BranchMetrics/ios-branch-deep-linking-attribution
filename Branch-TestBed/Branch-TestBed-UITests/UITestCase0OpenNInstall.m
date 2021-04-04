//
//  UITestOpenNInstall.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/10/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"
#import  <Foundation/Foundation.h>

@interface UITestCase0OpenNInstall : UITestCaseTestBed

@end

@implementation UITestCase0OpenNInstall

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
}
/*
 *  Test Case :
 *  1.1 First initSession call results in API call to /v1/install or /v1/open
 *  1.2 Subsequent initSession calls result in API call to /v1/open
 */
- (void)test0Install {
    
    // Launch App and Disable Tracking
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    [self disableTracking:FALSE];
    
    // Press Button "Load Logs for Last Command" and copy logs
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery.staticTexts[@"Load Logs for Last Command"] tap];
    XCUIElement *deeplinkdataTextView = app.textViews[@"DeepLinkData"];
    [deeplinkdataTextView tap];
    NSString *prevLogResults = app.textViews[@"DeepLinkData"].value;
    
    // Parse logs
    NSString *url;
    NSDictionary *json;
    NSString *status;
    NSDictionary *dataJson;
    [self parseURL:&url andJSON:&json andStatus:&status andDataJSON:&dataJson FromLogs:prevLogResults];
    
    // Check url contains /v1/install
    XCTAssertNotNil(url);
    XCTAssertNotNil(json);
    XCTAssertTrue([url containsString:@"/v1/install"]);
    
    // Get and Assert device_fingerprint_id & identity_id
    NSNumber *device_fingerprint_id = [dataJson objectForKey:@"device_fingerprint_id"];
    NSNumber *identity_id = [dataJson objectForKey:@"identity_id"];
    XCTAssertNotNil(identity_id);
    XCTAssertNotNil(device_fingerprint_id);
    
    //Re-launch App
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    [app terminate];
    [app launch];
    
    // Load logs and assert -
    // - URL contains /v1/open
    // - device_fingerprint_id is the same as returned above
    // - identity_id is the same as returned above
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Load Logs for Last Command"]/*[[".cells",".buttons[@\"Load Logs for Last Command\"].staticTexts[@\"Load Logs for Last Command\"]",".staticTexts[@\"Load Logs for Last Command\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    deeplinkdataTextView = app.textViews[@"DeepLinkData"];
    [deeplinkdataTextView tap];
    prevLogResults = app.textViews[@"DeepLinkData"].value;
    [self parseURL:&url andJSON:&json andStatus:&status andDataJSON:&dataJson FromLogs:prevLogResults];
    
    XCTAssertTrue([url containsString:@"/v1/open"]);
    
    XCTAssertNotNil([json valueForKey:@"identity_id"]);
    NSNumber *newID = [NSNumber numberWithInteger: [[json objectForKey:@"identity_id"] integerValue]] ;
    XCTAssertTrue([newID isEqualToNumber:identity_id]);
    
    XCTAssertNotNil([json valueForKey:@"device_fingerprint_id"]);
    NSNumber *newFPID = [NSNumber numberWithInteger: [[json objectForKey:@"device_fingerprint_id"] integerValue]] ;
    XCTAssertTrue([newFPID isEqualToNumber:device_fingerprint_id]);
    XCTAssertTrue([status containsString:@"200"]);
}

/*
 When a link is clicked with the app installed, it opens the app
 - the call to /v1/open should include information about the link clicked
 - the response from /v1/open should include deep link data inside the `data` object
 */
- (void) testOpenAppFromWebPage
{
    [self clickLinkInWebPage:@"TestWebPage.html"];
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    if ([ app waitForExistenceWithTimeout:15] != NO) {
        sleep(1);
        NSString *deepLinkData = app.textViews[@"DeepLinkData"].value;
        XCTAssertTrue([deepLinkData containsString:self.deeplinkDataToCheck]);
    } else {
        XCTFail("Application not launched");
    }
}

@end

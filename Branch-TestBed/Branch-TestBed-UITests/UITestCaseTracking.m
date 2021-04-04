//
//  UITestCaseTracking.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/21/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"
#import "Branch.h"
#import "BranchEvent.h"

@interface UITestCaseTracking : UITestCaseTestBed

@end

@implementation UITestCaseTracking

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
}

- (void)testTracking {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    // Tap Tracking button
    XCUIElement *trackingButton = app.buttons[@"tracking"];
    if (![trackingButton waitForExistenceWithTimeout:10]) {
        [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
        if (![trackingButton waitForExistenceWithTimeout:5]) {
                XCTFail("Timeout : Tracking button not found.");
        }
    }
   
    [trackingButton tap];
    // Send Event
    [self sendEvent:BranchStandardEventAddToCart];
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    // Tap Tracking button again
    [trackingButton tap];
    // Send Event again
    [self sendEvent:BranchStandardEventAddToCart];
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    [self disableTracking:FALSE];
}

@end

//
//  UITestRewards.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/7/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"

@interface UITestRewards : UITestCaseTestBed

@end

@implementation UITestRewards

- (void)setUp {
    [super setUp];
    [[[XCUIApplication alloc] init] launch];
    [self disableTracking:FALSE];
}

- (void)tearDown {
}

- (void)testRewards {
    
    // Click 'Set User ID' & then 'Refresh Rewards'
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery.buttons[@"Set User ID"] tap];
    [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
    sleep(1);
    [tablesQuery.buttons[@"Refresh Rewards"] tap];
    sleep(3);
    
    // Check Rewards
    XCUIElement *staticText = tablesQuery.staticTexts[@"rewardPoints"];
    NSInteger rewards = [staticText.label integerValue];
    XCTAssertGreaterThan(rewards, 0, "Incorrect Rewards.");
    
    // Click 'Redeem 5 Points'
    XCUIElement *redeem5PointsStaticText = tablesQuery.staticTexts[@"Redeem 5 Points"];
    [redeem5PointsStaticText tap];
    sleep(5);
    NSInteger newRewards = [staticText.label integerValue];
   
    // Check Rewards again
    XCTAssertTrue((rewards - newRewards) == 5);

    // Logout and Check Rewards again
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"SimulateLogout"]/*[[".cells",".buttons[@\"SimulateLogout\"].staticTexts[@\"SimulateLogout\"]",".staticTexts[@\"SimulateLogout\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [app.alerts[@"Logout succeeded"].scrollViews.otherElements.buttons[@"OK"] tap];
    [staticText tap];
    newRewards = [staticText.value integerValue];
    XCTAssertTrue(newRewards == 0);
    
}

@end

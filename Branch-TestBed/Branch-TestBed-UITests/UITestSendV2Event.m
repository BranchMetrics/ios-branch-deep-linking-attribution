//
//  UITestSendV2Event.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 12/27/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface UITestSendV2Event : XCTestCase

@end

@implementation UITestSendV2Event

- (void)setUp {
    [[[XCUIApplication alloc] init] launch];
}

- (void)tearDown {
}

- (void)testExample {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    sleep(3);
    
    XCUIElementQuery *tablesQuery = app.tables;
    
    XCUIElement *sendV2EventStaticText = tablesQuery.staticTexts[@"Send v2 Event"];
    [sendV2EventStaticText tap];
    
    XCUIElement * pickerWheel = [app.pickerWheels elementBoundByIndex:0];
    [pickerWheel adjustToPickerWheelValue:@"SHARE"];
   
    XCUIElement *sendButton = app.toolbars[@"Toolbar"].buttons[@"Send"];
    [sendButton tap];

}

- (void)testShareLink {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Create Branch Link"]/*[[".cells",".buttons[@\"Create Branch Link\"].staticTexts[@\"Create Branch Link\"]",".staticTexts[@\"Create Branch Link\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    [tablesQuery/*@START_MENU_TOKEN@*/.staticTexts[@"Share Link"]/*[[".cells",".buttons[@\"Share Link\"].staticTexts[@\"Share Link\"]",".staticTexts[@\"Share Link\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    sleep(6);
    [[[[app/*@START_MENU_TOKEN@*/.collectionViews/*[[".otherElements[@\"ActivityListView\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons[@"Copy"].otherElements containingType:XCUIElementTypeImage identifier:@"copy"] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element tap];
    sleep(3);
    XCUIElement *branchLinkTextField = tablesQuery/*@START_MENU_TOKEN@*/.textFields[@"Branch Link"]/*[[".cells.textFields[@\"Branch Link\"]",".textFields[@\"Branch Link\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/;
    NSString *pasteboardString = [UIPasteboard generalPasteboard].string;
    
    if ([pasteboardString containsString:@"Shared through 'Pasteboard'"] != YES) {
        XCTFail("Link not copied");
    }
}

@end

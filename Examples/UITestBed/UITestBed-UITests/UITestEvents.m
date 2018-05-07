//
//  UITestEvents.m
//  UITestBed-UITests
//
//  Created by Edward on 5/7/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface UITestEvents : XCTestCase
@property (strong) XCUIApplication*currentApp;
@end

@implementation UITestEvents

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    self.currentApp = [[XCUIApplication alloc] init];
    [self.currentApp launch];
}

- (void)tearDown {
    [super tearDown];
}

- (XCUIElement*) tableCellNamed:(NSString*)name {
    NSString*query = [NSString stringWithFormat:@"label contains '%@'", name];
    XCUIElementQuery*cells =
        [self.currentApp.cells containingPredicate:[NSPredicate predicateWithFormat:query]];
    return cells.firstMatch;
}

- (void)testExample {
    [self.currentApp.buttons[@"Done"] tap];
    [[self tableCellNamed:@"Send Commerce Event"] tap];
    XCUIElement*element = self.currentApp.textViews[@"Data"].firstMatch;
    NSString*value = element.value;
    XCTAssertTrue(value && [value isEqualToString:@"{\n  \"branch_view_enabled\" : true\n}"]);
}

@end

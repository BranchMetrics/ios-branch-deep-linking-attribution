//
//  UITestCaseTestBed.h
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/7/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#ifndef UITestCaseTestBed_h
#define UITestCaseTestBed_h

#import <XCTest/XCTest.h>

extern BOOL setIdentity;
extern BOOL checkIdentity;
extern BOOL setFBParams;
extern BOOL checkFBParams;

@interface UITestCaseTestBed : XCTestCase

@property NSString *deeplinkDataToCheck;

- (void)sendEvent:(NSString*)eventName;
-(void)parseURL:(NSString **)url andJSON:(NSDictionary **)json FromLogs:(NSString*)logs;
-(void)parseURL:(NSString **)url andJSON:(NSDictionary **)json andStatus:(NSString**)status andDataJSON:(NSDictionary **)dataJson FromLogs:(NSString*)logs;
- (void)clickLinkInWebPage:(NSString*)webPage;
- (void)OpenLinkInNewTab:(NSString*)webPage;
- (void) OpenLinkWithMenuToEnableUniversalLink:(NSString*)webPage;
- (XCUIApplication *) launchSafariNOpenLink:(NSString*)webPage;
- (void)disableTracking:(BOOL)disable;
@end

#endif /* UITestCaseTestBed_h */

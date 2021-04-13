//
//  UITestCaseTestBed.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 3/7/21.
//  Copyright © 2021 Branch, Inc. All rights reserved.
//

#import "UITestCaseTestBed.h"

BOOL setIdentity = FALSE;
BOOL checkIdentity = FALSE;
BOOL setFBParams = FALSE;
BOOL checkFBParams = FALSE;

@implementation UITestCaseTestBed

- (void)setUp {
    
    self.deeplinkDataToCheck = @"This text was embedded as data in a Branch link with the following characteristics:\n\ncanonicalUrl: https://dev.branch.io/getting-started/deep-link-routing/guide/ios/\n  title: Branch 0.19 TestBed Content Title\n  contentDescription: My Content Description\n  imageUrl: http://www.theweddingplayers.com/wp-content/new_folder/Mr_Wompy_web2.jpg\n";
    [self addUIInterruptionMonitorWithDescription:@"Allow notifications" handler:^BOOL(XCUIElement * _Nonnull interruptingElement) {
        [interruptingElement description];
        XCUIElement *button = interruptingElement.buttons[@"Allow"];
        if ([button exists]) {
            [button tap];
            return YES;
        }
        return NO;
    }];
}

- (void)tearDown {
}

- (void)sendEvent:(NSString*)eventName {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    XCUIElement *trackButton = app.buttons[@"tracking"];
    if (![trackButton waitForExistenceWithTimeout:10]) { [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
        if (![trackButton waitForExistenceWithTimeout:5]) {
                XCTFail("Timeout : Tracking button not found.");
        }
    }
    BOOL isTrackingEnabled = [trackButton.label isEqualToString:@"Disable Tracking"];
    XCUIElementQuery *tablesQuery = app.tables;
    sleep(1);
    XCUIElement *sendV2EventStaticText = tablesQuery.staticTexts[@"Send v2 Event"];
    [sendV2EventStaticText tap];
    sleep(1);
    
    XCUIElement * pickerWheel = [app.pickerWheels elementBoundByIndex:0];
    [pickerWheel adjustToPickerWheelValue:eventName];
    
    sleep(1);
    XCUIElement *sendButton = app.toolbars[@"Toolbar"].buttons[@"Send"];
   
    if (sendButton) {
        [sendButton tap];
    }
    else {
        XCTFail(@"Send Button not found");
    }
    sleep(1);
    
    XCUIElement *logResults = app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"];
    
    if ([logResults waitForExistenceWithTimeout:6] != NO) {
        XCUIElement *deeplinkdataTextView = app.textViews[@"DeepLinkData"];
        NSString *sendEventResults = deeplinkdataTextView.value;
        
        // Check for result value -- Its the first line -- RESULT : SUCCESS
        NSArray<NSString*> *substrings = [sendEventResults componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
        NSInteger count = [substrings count];
        
        for(int i = 0 ; i < count; i++ )
        {
            NSLog(@"substrings[i] : %@",substrings[i]);
            if ([substrings[i] hasPrefix:@"RESULT:"] == TRUE) {
                if (!isTrackingEnabled)
                {
                    XCTAssertTrue([substrings[i] hasSuffix:@"FAILED"]);
                    return;
                }
                else
                {
                XCTAssertTrue([substrings[i] hasSuffix:@"SUCCESS"]);
                }
                [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
                break;
            }
        }
    }
    
    [app.tables/*@START_MENU_TOKEN@*/.staticTexts[@"Load Logs for Last Command"]/*[[".cells",".buttons[@\"Load Logs for Last Command\"].staticTexts[@\"Load Logs for Last Command\"]",".staticTexts[@\"Load Logs for Last Command\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ tap];
    NSString *prevLogResults = app.textViews[@"DeepLinkData"].value;
    NSString *url;
    NSDictionary *json;
    [self parseURL:&url andJSON:&json FromLogs:prevLogResults];
    
    XCTAssertNotNil(url);
    XCTAssertNotNil(json);
    
    if ([eventName isEqualToString:@"iOS-CustomEvent"]) {
        XCTAssertTrue([url containsString:@"/v2/event/custom"]);
    } else {
        XCTAssertTrue([url containsString:@"/v2/event/standard"]);
    }

    if (checkIdentity) {
        if (setIdentity) {
            NSDictionary *user_data = [json objectForKey:@"user_data"];
            NSString *developer_identity = [user_data objectForKey:@"developer_identity"];
            XCTAssertNotNil(developer_identity);
        } else {
            NSDictionary *user_data = [json objectForKey:@"user_data"];
            NSString *developer_identity = [user_data objectForKey:@"developer_identity"];
            XCTAssertNil(developer_identity);
        }
    }
    
    if (checkFBParams) {
        if (setFBParams) {
            NSDictionary *fbParams = [[json objectForKey:@"partner_data"] objectForKey:@"fb"];
           
            NSString *pEM = [fbParams objectForKey:@"em"];
            NSString *pPH = [fbParams objectForKey:@"ph"];
            
            XCTAssertNotNil(pEM);
            XCTAssertNotNil(pPH);
            XCTAssertTrue([pEM isEqualToString:@"11234e56af071e9c79927651156bd7a10bca8ac34672aba121056e2698ee7088"]);
            XCTAssertTrue([pPH isEqualToString:@"b90598b67534f00b1e3e68e8006631a40d24fba37a3a34e2b84922f1f0b3b29b"]);
            
        } else {
            NSDictionary *fbParams = [[json objectForKey:@"partner_data"] objectForKey:@"fb"];
            XCTAssertNil(fbParams);
        }
    }
}

-(void)parseURL:(NSString **)url andJSON:(NSDictionary **)json FromLogs:(NSString*)logs
{
    [self parseURL:url andJSON:json andStatus:nil andDataJSON:nil FromLogs:logs];
}

-(void)parseURL:(NSString **)url andJSON:(NSDictionary **)json andStatus:(NSString**)status andDataJSON:(NSDictionary **)dataJson FromLogs:(NSString*)logs
{
    NSRange indexStart = [logs rangeOfString:@"URL:"];
    if (indexStart.location != NSNotFound) {
        *url = [logs substringFromIndex:indexStart.location];
    }
   
    NSRange indexEnd = [*url rangeOfString:@".\n"];
    if (indexEnd.location != NSNotFound) {
        *url = [*url substringToIndex:indexEnd.location + indexEnd.length];

    }
           
    // Get JSON
    NSString *jsonString;
    indexStart = [logs rangeOfString:@"JSON:" ];
    if (indexStart.location != NSNotFound) {
        jsonString = [logs substringFromIndex:(indexStart.location + indexStart.length)];
    }
    indexEnd = [jsonString rangeOfString:@"}."];
    if (indexEnd.location != NSNotFound) {
        jsonString = [jsonString substringToIndex:indexEnd.location+1];
    }
    
    if (jsonString) {
        NSError *error;
        *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error) {
            NSLog(@"%@", [error description]);
            XCTFail(@"%@", [error description]);
        }
    }
    
    if (status) {
        indexStart = [logs rangeOfString:@"Status: "];
        if (indexStart.location != NSNotFound) {
            *status = [logs substringFromIndex:(indexStart.location + indexStart.length)];
        }
        indexEnd = [*status rangeOfString:@"; Data:"];
        if (indexEnd.location != NSNotFound) {
            *status = [*status substringToIndex:indexEnd.location ];
        }
    }

    if (dataJson) {
        NSString *dataString;
        indexStart = [logs rangeOfString:@"; Data:"];
        if (indexStart.location != NSNotFound) {
            dataString = [logs substringFromIndex:(indexStart.location + indexStart.length)];
        }
        indexEnd = [dataString rangeOfString:@"}."];
        if (indexEnd.location != NSNotFound) {
            dataString = [dataString substringToIndex:indexEnd.location+1 ];
        }
        if (dataString) {
            NSMutableString *mutDataString = [dataString mutableCopy];
            [mutDataString replaceOccurrencesOfString:@"data" withString:@"\"data\"" options:0 range:NSMakeRange(0 , [mutDataString length])];
            [mutDataString replaceOccurrencesOfString:@"link =" withString:@"\"link\" =" options:0 range:NSMakeRange(0 , [mutDataString length])];
            [mutDataString replaceOccurrencesOfString:@" = " withString:@" : " options:0 range:NSMakeRange(0 , [mutDataString length])];
            [mutDataString replaceOccurrencesOfString:@";\n" withString:@",\n" options:0 range:NSMakeRange(0 , [mutDataString length])];
            
            NSError *error;
            *dataJson = [NSJSONSerialization JSONObjectWithData:[mutDataString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (error) {
                NSLog(@"%@", [error description]);
                XCTFail(@"%@", [error description]);
            }
        }
    }
}

- (void) clickLinkInWebPage:(NSString*)webPage
{
    XCUIApplication *safariApp = [self launchSafariNOpenLink:webPage];
  
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink tap];
}

- (void) OpenLinkInNewTab:(NSString*)webPage
{
   
    XCUIApplication *safariApp = [self launchSafariNOpenLink:webPage];
    sleep(1);
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink pressForDuration:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Open in New Tab"]];
    
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate] tap];
}

- (void) OpenLinkWithMenuToEnableUniversalLink:(NSString*)webPage
{
    XCUIApplication *safariApp = [self launchSafariNOpenLink:webPage];
    sleep(1);
    XCUIElement *testBedLink = [[safariApp.webViews descendantsMatchingType:XCUIElementTypeLink] elementBoundByIndex:0];
    
    [testBedLink pressForDuration:1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == 'Open in “Branch-TestBed”'"]];
    NSLog(@"%@" , [safariApp debugDescription]);
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate] tap];
}

- (XCUIApplication *) launchSafariNOpenLink:(NSString*)webPage
{
    NSString *webPageLink = [NSString stringWithFormat:@"%@%@", @"https://ndixit-branch.github.io/", webPage];
    XCUIApplication *safariApp = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.mobilesafari"];
    [safariApp activate];
    sleep(1.0);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Tabs"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicate] tap];
    sleep(1);
    NSPredicate *predicateAddTab = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"New tab"]];
    [[[safariApp descendantsMatchingType:XCUIElementTypeAny] elementMatchingPredicate:predicateAddTab] tap];
    sleep(3);

    NSPredicate *predicateURL = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"label == '%@'",@"Address"]];
    XCUIElement *addressBar = [[safariApp descendantsMatchingType:XCUIElementTypeTextField] elementMatchingPredicate:predicateURL];
    if ([addressBar waitForExistenceWithTimeout:10]) {
        [addressBar tap];
    }
    [safariApp activate];
    [safariApp typeText:webPageLink];
    [safariApp.buttons[@"Go"] tap];
    sleep(3.0);
    return safariApp;
}

- (void)disableTracking:(BOOL)disable
{
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElement *trackButton = app.buttons[@"tracking"];
    if (![trackButton waitForExistenceWithTimeout:10]) {
        [app.navigationBars[@"Branch-TestBed"].buttons[@"Branch-TestBed"] tap];
        if (![trackButton waitForExistenceWithTimeout:5]) {
                XCTFail("Timeout : Tracking button not found.");
        }
    }
    if ( disable && ([trackButton.label isEqualToString:@"Disable Tracking"])) {
        [trackButton tap];
    }
    if ( !disable && ([trackButton.label isEqualToString:@"Enable Tracking"])) {
        [trackButton tap];
    }
}

@end

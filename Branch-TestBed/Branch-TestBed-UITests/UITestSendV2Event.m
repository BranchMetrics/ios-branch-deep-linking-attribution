//
//  UITestSendV2Event.m
//  Branch-TestBed-UITests
//
//  Created by Nidhi on 12/27/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branch.h"
#import "BranchEvent.h"
#import "UITestCaseTestBed.h"

@interface UITestSendV2Event : UITestCaseTestBed

@end

@implementation UITestSendV2Event

- (void)setUp {
    [super setUp];
    [[[XCUIApplication alloc] init] launch];
    [self disableTracking:FALSE];
}

- (void)tearDown {
}

- (void)testBranchStandardEventAddToCart {
    [self sendEvent:BranchStandardEventAddToCart];
}

- (void)testBranchStandardEventAddToWishlist{
    [self sendEvent:BranchStandardEventAddToWishlist];
}

- (void)testBranchStandardEventViewCart{
    [self sendEvent:BranchStandardEventViewCart];
}

- (void)testBranchStandardEventInitiatePurchase{
    [self sendEvent:BranchStandardEventInitiatePurchase];
}

- (void)testBranchStandardEventAddPaymentInfo{
    [self sendEvent:BranchStandardEventAddPaymentInfo];
}

- (void)testBranchStandardEventPurchase{
    [self sendEvent:BranchStandardEventPurchase];
}

- (void)testBranchStandardEventSpendCredits{
    [self sendEvent:BranchStandardEventSpendCredits];
}

- (void)testBranchStandardEventSearch{
    [self sendEvent:BranchStandardEventSearch];
}

- (void)testBranchStandardEventViewItem{
    [self sendEvent:BranchStandardEventViewItem];
}

- (void)testBranchStandardEventViewItems{
    [self sendEvent:BranchStandardEventViewItems];
}

- (void)testBranchStandardEventRate{
    [self sendEvent:BranchStandardEventRate];
}

- (void)testBranchStandardEventShare{
    [self sendEvent:BranchStandardEventShare];
}

- (void)testBranchStandardEventCompleteRegistration{
    [self sendEvent:BranchStandardEventCompleteRegistration];
}

- (void)testBranchStandardEventCompleteTutorial{
    [self sendEvent:BranchStandardEventCompleteTutorial];
}

- (void)testBranchStandardEventAchieveLevel{
    [self sendEvent:BranchStandardEventAchieveLevel];
}

- (void)testBranchStandardEventUnlockAchievement{
    [self sendEvent:BranchStandardEventUnlockAchievement];
}

- (void)testBranchStandardEventInvite{
    [self sendEvent:BranchStandardEventInvite];
}

- (void)testBranchStandardEventLogin{
    [self sendEvent:BranchStandardEventLogin];
}

- (void)testBranchStandardEventReserve{
    [self sendEvent:BranchStandardEventReserve];
}

- (void)testBranchStandardEventSubscribe{
    [self sendEvent:BranchStandardEventSubscribe];
}

- (void)testBranchStandardEventStartTrial{
    [self sendEvent:BranchStandardEventStartTrial];
}

- (void)testBranchStandardEventClickAd{
    [self sendEvent:BranchStandardEventClickAd];
}

- (void)testBranchStandardEventViewAd{
    [self sendEvent:BranchStandardEventViewAd];
}

- (void)testiOSCustomEvent{
    [self sendEvent:@"iOS-CustomEvent"];
}

- (NSString *)pathToDocumentsDir
{
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [allPaths objectAtIndex:0];
    return documentsDirectory;
}

@end

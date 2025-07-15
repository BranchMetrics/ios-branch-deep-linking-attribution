//
//  BNCSKAdNetworkTests.m
//  Branch-SDK-Tests
//
//  Created by Ernest Cho on 8/13/20.
//  Copyright © 2020 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BNCSKAdNetwork.h"
#import "BranchEvent.h"

// Expose private methods for testing
@interface BNCSKAdNetwork()

@property (nonatomic, copy, readwrite) NSDate *installDate;

- (BOOL)shouldAttemptSKAdNetworkCallout;

@end

@interface BranchEvent()

// private BranchEvent methods used to check data before sending to network service.
- (NSDictionary *)buildEventDictionary;
- (BranchEventRequest *)buildRequestWithEventDictionary:(NSDictionary *)eventDictionary;

@end


@interface BNCSKAdNetworkTests : XCTestCase

@property (nonatomic, strong, readwrite) BNCSKAdNetwork *skAdNetwork;

@end

@implementation BNCSKAdNetworkTests

- (void)setUp {
    self.skAdNetwork = [BNCSKAdNetwork new];
    self.skAdNetwork.installDate = [NSDate date];
}

- (void)tearDown {

}

- (void)testDefaultMaxTimeout {
    NSTimeInterval days;
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        days = 3600.0 * 24.0 * 60.0; // one day
    } else {
        days = 3600.0 * 24.0; // one day
    }
    XCTAssertTrue(self.skAdNetwork.maxTimeSinceInstall == days);
}

- (void)testShouldAttemptSKAdNetworkCallout {
    XCTAssertTrue([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

- (void)testShouldAttemptSKAdNetworkCalloutFalse {
    self.skAdNetwork.maxTimeSinceInstall = 0.0;
    XCTAssertFalse([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

- (void)testPostbackCall {
    
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        self.skAdNetwork.maxTimeSinceInstall = 3600.0 * 24.0 * 60.0; 
    } else {
        self.skAdNetwork.maxTimeSinceInstall = 3600.0 * 24.0; // one day
    }
    
    XCTAssertTrue([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
    
    [[BNCSKAdNetwork sharedInstance] registerAppForAdNetworkAttribution];
   
    BranchEvent *event = [BranchEvent standardEvent:BranchStandardEventInvite];
    NSDictionary *eventDictionary = [event buildEventDictionary];
    BranchEventRequest *request = [event buildRequestWithEventDictionary:eventDictionary];
     
    XCTestExpectation *expectation = [self expectationWithDescription:@"TestPostback"];
    BNCServerResponse *openInstallResponse = [[BNCServerResponse alloc] init];
    
    openInstallResponse.data = @{ @"update_conversion_value": @60 };
    request.completion =  ^(NSDictionary*_Nullable response, NSError*_Nullable error){
            [expectation fulfill];
        };
    [request processResponse:openInstallResponse error:Nil];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSKAN4ParamsDefaultValues {
    
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        NSString *coarseValue = [[BNCSKAdNetwork sharedInstance] getCoarseConversionValueFromDataResponse:@{}];
        XCTAssertTrue([coarseValue isEqualToString:@"low"]);
        
        BOOL isLocked = [[BNCSKAdNetwork sharedInstance] getLockedStatusFromDataResponse:@{}];
        XCTAssertFalse(isLocked);
        
        BOOL ascendingOnly = [[BNCSKAdNetwork sharedInstance] getAscendingOnlyFromDataResponse:@{}];
        XCTAssertTrue(ascendingOnly);
    }
}

- (void)testSKAN4ParamsValues {
    
    if (@available(iOS 16.1, macCatalyst 16.1, *)) {
        
        NSDictionary *response = @{@"update_conversion_value": @16, @"coarse_key": @"high", @"locked": @YES, @"ascending_only":@NO };
        BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
        
        NSString *coarseValue = [adNetwork getCoarseConversionValueFromDataResponse:response];
        XCTAssertTrue([coarseValue isEqualToString:@"high"]);
        
        BOOL isLocked = [adNetwork getLockedStatusFromDataResponse:response];
        XCTAssertTrue(isLocked);
        
        BOOL ascendingOnly = [adNetwork getAscendingOnlyFromDataResponse:response];
        XCTAssertFalse(ascendingOnly);
    }
}

- (void)testSKAN4CurrentWindow {
    
    BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];

    NSDate *currentDateAndTime = [NSDate date];
    prefs.firstAppLaunchTime = [currentDateAndTime dateByAddingTimeInterval:-30];
    NSInteger win = [adNetwork calculateSKANWindowForTime:currentDateAndTime];
    XCTAssertTrue(win == 1);
    
    win = [adNetwork calculateSKANWindowForTime: [ currentDateAndTime dateByAddingTimeInterval:24*3600*3 ]];
    XCTAssertTrue(win == 2);
    
    win = [adNetwork calculateSKANWindowForTime: [ currentDateAndTime dateByAddingTimeInterval:24*3600*10 ]];
    XCTAssertTrue(win == 3);
    
    win = [adNetwork calculateSKANWindowForTime: [ currentDateAndTime dateByAddingTimeInterval:24*3600*36 ]];
    XCTAssertTrue(win == 0);
    
    prefs.firstAppLaunchTime = nil;
    [prefs synchronize];
    win = [adNetwork calculateSKANWindowForTime: currentDateAndTime];
    XCTAssertTrue(win == 0);
}

- (void)testSKAN4HighestConversionValue {
    
    BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];

    prefs.highestConversionValueSent = 0;
    prefs.skanCurrentWindow = 0;
    NSDate *currentDateAndTime = [NSDate date];
    prefs.invokeRegisterApp = YES;
    
    prefs.firstAppLaunchTime = [currentDateAndTime dateByAddingTimeInterval:-30 ];
    [adNetwork shouldCallPostbackForDataResponse:@{}];
    XCTAssertTrue(prefs.highestConversionValueSent == 0);
    
    [adNetwork shouldCallPostbackForDataResponse:@{@"update_conversion_value": @6}];
    XCTAssertTrue(prefs.highestConversionValueSent == 6);
    
    [adNetwork shouldCallPostbackForDataResponse:@{@"update_conversion_value": @3}];
    XCTAssertTrue(prefs.highestConversionValueSent == 6);
    
    
    prefs.firstAppLaunchTime = [currentDateAndTime dateByAddingTimeInterval:-24*3600*3 ];
    [adNetwork shouldCallPostbackForDataResponse:@{}];
    XCTAssertTrue(prefs.highestConversionValueSent == 0);
}

- (void)testSKAN4ShouldCallPostback {
    
    BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];

    prefs.firstAppLaunchTime = nil;
    [prefs synchronize];
    
    NSDictionary *response = @{@"update_conversion_value": @16, @"coarse_key": @"high", @"locked": @YES, @"ascending_only":@NO };
    
    BOOL shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertFalse(shouldCall);
    
}

- (void)testSKAN4ShouldCallPostback2 {
    
    BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    
    prefs.invokeRegisterApp = YES;
    prefs.highestConversionValueSent = 0;
    prefs.firstAppLaunchTime = [NSDate date];
    prefs.skanCurrentWindow = 0;
    [prefs synchronize];
    
    NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:
    @{@"update_conversion_value": @16, @"coarse_key": @"high", @"locked": @YES, @"ascending_only":@YES }];
    
    BOOL shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertFalse(shouldCall);
    
    response[@"update_conversion_value"] = @14;
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertFalse(shouldCall);
    
    response[@"update_conversion_value"] = @18;
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    prefs.firstAppLaunchTime = nil;
    prefs.firstAppLaunchTime = [[NSDate date] dateByAddingTimeInterval:-24*3600*3];
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    NSLog(@"Conv : %ld", prefs.highestConversionValueSent);
    XCTAssertTrue(shouldCall);
    
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertFalse(shouldCall);
}

- (void)testSKAN4ShouldCallPostback3 {
    BNCSKAdNetwork *adNetwork = [BNCSKAdNetwork sharedInstance];
    BNCPreferenceHelper *prefs = [BNCPreferenceHelper sharedInstance];
    
    prefs.invokeRegisterApp = YES;
    prefs.highestConversionValueSent = 0;
    prefs.firstAppLaunchTime = [NSDate date];
    [prefs synchronize];
    
    NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:
    @{@"update_conversion_value": @16, @"coarse_key": @"high", @"locked": @YES, @"ascending_only":@NO }];
    
    BOOL shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    response[@"update_conversion_value"] = @14;
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    response[@"update_conversion_value"] = @18;
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    XCTAssertTrue(shouldCall);
    
    prefs.firstAppLaunchTime = [[NSDate date] dateByAddingTimeInterval:-24*3600*3];
    //NSLog(@"Conv : %ld", (long)prefs.highestConversionValueSent);
    shouldCall = [adNetwork shouldCallPostbackForDataResponse:response];
    NSLog(@"Conv : %ld", prefs.highestConversionValueSent);
    XCTAssertTrue(shouldCall);
}

@end

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
    NSTimeInterval oneDay = 3600.0 * 24.0;
    XCTAssertTrue(self.skAdNetwork.maxTimeSinceInstall == oneDay);
}

- (void)testShouldAttemptSKAdNetworkCallout {
    XCTAssertTrue([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

- (void)testShouldAttemptSKAdNetworkCalloutFalse {
    self.skAdNetwork.maxTimeSinceInstall = 0.0;
    XCTAssertFalse([self.skAdNetwork shouldAttemptSKAdNetworkCallout]);
}

- (void)testPostbackCall {
    
    self.skAdNetwork.maxTimeSinceInstall = 3600.0 * 24.0; // one day
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

@end

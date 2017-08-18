//
//  BNCEvent.Test.m
//  Branch-TestBed
//
//  Created by Edward Smith on 8/15/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCTestCase.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import "BNCEvent.h"

@interface BNCEventTest : BNCTestCase
@end

@implementation BNCEventTest

- (void) testEvent {

    // Mock the result --

    NSString *jsonString = [self stringFromBundleWithKey:@"V2EventJSON"];
    XCTAssertTrue(jsonString, @"Can't load V2EventJSON resource from plist!");

    NSError *error = nil;
    NSDictionary *dictionary =
        [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
            options:0 error:&error];
    XCTAssertNil(error);
    XCTAssert(dictionary);
    NSMutableDictionary *expectedRequest = [NSMutableDictionary dictionaryWithDictionary:dictionary];

    // Fix up the expectedParameters -- 

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    expectedRequest[BRANCH_REQUEST_KEY_BRANCH_IDENTITY] = preferenceHelper.identityID;
    expectedRequest[BRANCH_REQUEST_KEY_DEVICE_FINGERPRINT_ID] = preferenceHelper.deviceFingerprintID;
    expectedRequest[BRANCH_REQUEST_KEY_SESSION_ID] = preferenceHelper.sessionID;

    id serverInterfaceMock = OCMClassMock([BNCServerInterface class]);
    [[serverInterfaceMock expect]
        postRequest:expectedRequest
        url:[self stringMatchingPattern:@"v2/event/standard"]
        key:[OCMArg any]
        callback:[OCMArg any]];

    // Set up the event --

    BranchUniversalObject *buo = [BranchUniversalObject new];
    BNCEventProperties *eventProperties = [BNCEventProperties new];

    // Test --

    Branch *branch = [[Branch alloc] init];
    [branch logStandardEvent:BNCStandardEventPurchase
        withProperties:eventProperties
        contentItems:@[buo]];

    [serverInterfaceMock verify];
}

@end



//--------------------------------------------------------------------------------------------------
//
//                                                                              BNCDeviceInfo.Test.m
//                                                                                  Branch.framework
//
//                                                                               BNCDeviceInfo Tests
//                                                                         Edward Smith, August 2017
//
//                                             -©- Copyright © 2017 Branch, all rights reserved. -©-
//
//--------------------------------------------------------------------------------------------------


#import "BNCTestCase.h"
#import "BNCDeviceInfo.h"
#import "NSString+Branch.h"

@interface BNCDeviceInfoTest : BNCTestCase
@end

@implementation BNCDeviceInfoTest

- (void)testGetDeviceInfo {
/*
@property (nonatomic, strong) NSString *hardwareId;
@property (nonatomic, strong) NSString *hardwareIdType;
@property (nonatomic) BOOL isRealHardwareId;
@property (nonatomic, strong) NSString *vendorId;
@property (nonatomic, strong) NSString *brandName;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *osName;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic, strong) NSNumber *screenWidth;
@property (nonatomic, strong) NSNumber *screenHeight;
@property (nonatomic) BOOL isAdTrackingEnabled;
*/
    BNCDeviceInfo *device = [BNCDeviceInfo getInstance];

    #define maskedStringAssert(field, maskedString) { \
        if (![device.field bnc_isEqualToMaskedString:maskedString]) { \
            NSLog(@"Assertion failed.\nValue of %@ is\n'%@'\nand not\n'%@'\n.", \
                @#field, device.field, maskedString); \
            XCTAssertTrue(false); \
        } \
    }

    maskedStringAssert(hardwareId,      @"********-****-****-*****************");
    maskedStringAssert(hardwareIdType,  @"vendor_id");
    XCTAssertTrue(device.isRealHardwareId);
    maskedStringAssert(vendorId,        @"********-****-****-*****************");
    maskedStringAssert(brandName,       @"Apple");
    maskedStringAssert(modelName,       @"x86_64");
    maskedStringAssert(osName,          @"iOS");
    XCTAssertEqualObjects(device.osVersion, [[UIDevice currentDevice] systemVersion]);
    XCTAssert(device.screenWidth.integerValue >= 320 && device.screenWidth.integerValue < 10000);
    XCTAssert(device.screenHeight.integerValue >= 320 && device.screenHeight.integerValue < 10000);
    XCTAssertTrue(device.isAdTrackingEnabled);
}

- (void)testClassMethods {
    //+ (BNCDeviceInfo *)getInstance;
    //+ (NSString*) userAgentString;
    //+ (NSString*) systemBuildVersion;

    NSString *string = [BNCDeviceInfo userAgentString];
    NSString *truth =
        @"Mozilla/5.0 (iPhone; CPU iPhone OS **** like Mac OS X) AppleWebKit/******** (KHTML, like Gecko) Mobile/*****";
    XCTAssertTrue([string bnc_isEqualToMaskedString:truth]);

    string = [BNCDeviceInfo systemBuildVersion];
    truth = @"*****";
    XCTAssertTrue([string bnc_isEqualToMaskedString:truth]);
}

- (void)testStress {
    for (int i = 0; i < 5000; i++) {
        [self testGetDeviceInfo];
    }
}

@end

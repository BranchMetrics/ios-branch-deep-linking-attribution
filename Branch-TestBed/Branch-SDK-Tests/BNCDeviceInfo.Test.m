

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
#import "BNCLog.h"

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
    XCTAssertTrue(
        [device.hardwareIdType isEqualToString:@"idfa"] ||
        [device.hardwareIdType isEqualToString:@"vendor_id"]
    );
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
    NSString *pattern =
        @"Mozilla\\/..0 \\(iP.+; CPU.+OS.+like Mac OS X\\) AppleWebKit\\/.+ \\(KHTML, like Gecko\\) Mobile\\/.+";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
        regularExpressionWithPattern:pattern
        options:NSRegularExpressionCaseInsensitive
        error:&error];

    NSRange range = NSMakeRange(0, string.length);
    NSArray<NSTextCheckingResult*>*matches = [regex matchesInString:string options:0 range:range];
    XCTAssert(matches.count == 1 && NSEqualRanges(matches[0].range, range));

    string = [BNCDeviceInfo systemBuildVersion];
    XCTAssertTrue([string isKindOfClass:[NSString class]] && string.length > 0);
}

- (void)testStress {
    NSDate *startTime = [NSDate date];
    dispatch_group_t  waitGroup = dispatch_group_create();

    dispatch_group_async(waitGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        for (int i = 0; i < 5000; i++) {
            [self testGetDeviceInfo];
        }
    });

    dispatch_group_async(waitGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        for (int i = 0; i < 5000; i++) {
            [self testGetDeviceInfo];
        }
    });

    dispatch_group_async(waitGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        for (int i = 0; i < 5000; i++) {
            [self testGetDeviceInfo];
        }
    });

    dispatch_group_async(waitGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        for (int i = 0; i < 5000; i++) {
            [self testGetDeviceInfo];
        }
    });

    dispatch_group_async(waitGroup,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        for (int i = 0; i < 5000; i++) {
            [self testGetDeviceInfo];
        }
    });

    dispatch_group_wait(waitGroup, DISPATCH_TIME_FOREVER);
    BNCLogCloseLogFile();
    NSLog(@"%@: Synchronized time: %1.5f.",
        BNCSStringForCurrentMethod(), - startTime.timeIntervalSinceNow);
}

@end

//
//  BNCDeviceInfo.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCDeviceInfo.h"
#import "BNCPreferenceHelper.h"
#import "BNCSystemObserver.h"

@interface BNCDeviceInfo()

@end

@implementation BNCDeviceInfo

static BNCDeviceInfo *bncDeviceInfo;

+ (BNCDeviceInfo *)getInstance {
    if (!bncDeviceInfo) {
        bncDeviceInfo = [[BNCDeviceInfo alloc] init];
    }
    return bncDeviceInfo;
}

- (id)init {
    if (self = [super init]) {
        BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
        BOOL isRealHardwareId;
        NSString *hardwareIdType;
        NSString *hardwareId = [BNCSystemObserver getUniqueHardwareId:&isRealHardwareId isDebug:preferenceHelper.isDebug andType:&hardwareIdType];
        if (hardwareId) {
            self.hardwareId = hardwareId;
            self.isRealHardwareId = isRealHardwareId;
            self.hardwareIdType = hardwareIdType;
        }
        
        self.vendorId = [BNCSystemObserver getVendorId];
        self.brandName = [BNCSystemObserver getBrand];
        self.modelName = [BNCSystemObserver getModel];
        self.osName = [BNCSystemObserver getOS];
        self.osVersion = [BNCSystemObserver getOSVersion];
        self.screenWidth = [BNCSystemObserver getScreenWidth];
        self.screenHeight = [BNCSystemObserver getScreenHeight];
        self.isAdTrackingEnabled = [BNCSystemObserver adTrackingSafe];
    }
    return self;
}

@end

//
//  BNCDeviceInfo.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/22/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
#import <Foundation/Foundation.h>
#ifndef BNCDeviceInfo_h
#define BNCDeviceInfo_h



#endif /* BNCDeviceInfo_h */

@interface BNCDeviceInfo : NSObject

//---------Properties-------------//
@property (nonatomic, strong) NSString *hardwareId;
@property (nonatomic, strong) NSString *hardwareIdType;
@property (nonatomic) BOOL isRealHardwareId;
@property (nonatomic, strong) NSString *vendorId;
@property (nonatomic, strong) NSString *brandName;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *osName;
@property (nonatomic, strong) NSString *osVersion;
@property (nonatomic) NSNumber *screenWidth;
@property (nonatomic) NSNumber *screenHeight;
@property (nonatomic) BOOL isAdTrackingEnabled;


//----------Methods----------------//
+ (BNCDeviceInfo *)getInstance;

@end
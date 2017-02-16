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
@property (nonatomic, strong) NSNumber *screenWidth;
@property (nonatomic, strong) NSNumber *screenHeight;
@property (nonatomic) BOOL isAdTrackingEnabled;

@property (nonatomic, strong) NSString* country;            //  iso2 Country name (us, in,etc).
@property (nonatomic, strong) NSString* language;           //  iso2 language code (en, ml).
@property (nonatomic, strong) NSString* browserUserAgent;   //  Simple user agent string.


//----------Methods----------------//
+ (BNCDeviceInfo *)getInstance;
+ (NSString*) userAgentString;          // Warning:  Has an implied lock on main thread on first call.
+ (NSString*) systemBuildVersion;

@end

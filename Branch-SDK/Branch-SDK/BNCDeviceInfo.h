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
@property (atomic, copy) NSString *hardwareId;
@property (atomic, copy) NSString *hardwareIdType;
@property (atomic) BOOL isRealHardwareId;
@property (atomic, copy) NSString *vendorId;
@property (atomic, copy) NSString *brandName;
@property (atomic, copy) NSString *modelName;
@property (atomic, copy) NSString *osName;
@property (atomic, copy) NSString *osVersion;
@property (atomic, copy) NSNumber *screenWidth;
@property (atomic, copy) NSNumber *screenHeight;
@property (atomic) BOOL isAdTrackingEnabled;

@property (atomic, copy) NSString* country;            //  iso2 Country name (us, in,etc).
@property (atomic, copy) NSString* language;           //  iso2 language code (en, ml).
@property (atomic, copy) NSString* browserUserAgent;   //  Simple user agent string.


//----------Methods----------------//
+ (BNCDeviceInfo *)getInstance;
+ (NSString*) userAgentString;          // Warning:  Has an implied lock on main thread on first call.
+ (NSString*) systemBuildVersion;

@end

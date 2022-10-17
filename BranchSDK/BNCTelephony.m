//
//  BNCTelephony.m
//  Branch
//
//  Created by Ernest Cho on 11/14/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCTelephony.h"
#if !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif
@implementation BNCTelephony

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadCarrierInformation];
    }
    return self;
}

// This only works if device has cell service, otherwise all values are nil
- (void)loadCarrierInformation {
    #if !TARGET_OS_MACCATALYST
    CTTelephonyNetworkInfo *networkInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier;
    if (@available( iOS 12.0, *))
    {
        NSDictionary *carriers = [networkInfo serviceSubscriberCellularProviders];
        for(id key in carriers.allKeys)
        {
            // Get the first carrier info and exit.
            carrier = carriers[key];
            break;
        }
    }
    else
    {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 12000
        carrier = [networkInfo subscriberCellularProvider];
#endif
    }
    
    self.carrierName = carrier.carrierName;
    self.isoCountryCode = carrier.isoCountryCode;
    self.mobileCountryCode = carrier.mobileCountryCode;
    self.mobileNetworkCode = carrier.mobileNetworkCode;
    #endif
}

@end

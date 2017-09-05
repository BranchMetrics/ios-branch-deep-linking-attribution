//
//  BNCDeviceInfoUpdateRequest.h
//  Branch-TestBed
//
//  Created by edward on 5/1/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Branch/Branch.h>
#import "BNCDeviceInfo.h"

@interface BNCDeviceInfoUpdateRequest : BNCServerRequest <NSCoding>

- (instancetype) initWithDeviceInfo:(BNCDeviceInfo*)deviceInfo
                         completion:(void (^) (NSDictionary*response, NSError*error))completion;

@end

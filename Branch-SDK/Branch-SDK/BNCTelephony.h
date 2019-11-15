//
//  BNCTelephony.h
//  Branch
//
//  Created by Ernest Cho on 11/14/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// general country, carrier level information
@interface BNCTelephony : NSObject

// Example: "AT&T"
@property (nonatomic, copy, readwrite) NSString *carrierName;

// Example: "us"
@property (nonatomic, copy, readwrite) NSString *isoCountryCode;

// Example: "310"
@property (nonatomic, copy, readwrite) NSString *mobileCountryCode;

// Example: "410"
@property (nonatomic, copy, readwrite) NSString *mobileNetworkCode;

@end

NS_ASSUME_NONNULL_END

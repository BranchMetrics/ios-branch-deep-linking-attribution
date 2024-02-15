//
//  BNCNetworkInterface.h
//  BranchSDK
//
//  Utility class to query device network information
//
//  Created by Ernest Cho on 11/19/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCNetworkInterface : NSObject

+ (nullable NSString *)localIPAddress;

+ (NSArray<NSString *> *)allIPAddresses;

@end

NS_ASSUME_NONNULL_END

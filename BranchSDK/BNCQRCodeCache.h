//
//  BNCQRCodeCache.h
//  Branch
//
//  Created by Nipun Singh on 5/5/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BNCQRCodeCache : NSObject

+ (BNCQRCodeCache *) sharedInstance;
- (void)addQRCodeToCache:(NSData *)qrCodeData withParams:(NSMutableDictionary *)parameters;
- (NSData *)checkQRCodeCache:(NSMutableDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END

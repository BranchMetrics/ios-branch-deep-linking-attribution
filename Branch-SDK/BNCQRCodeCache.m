//
//  BNCQRCodeCache.m
//  Branch
//
//  Created by Nipun Singh on 5/5/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "BNCQRCodeCache.h"

@interface BNCQRCodeCache()
@property (nonatomic, strong) NSMutableDictionary *cache;
@end

@implementation BNCQRCodeCache

//Can only hold one QR code in cache. Just used to debounce.
+ (BNCQRCodeCache *) sharedInstance {
    static BNCQRCodeCache *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [BNCQRCodeCache new];
    });
    return singleton;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addQRCodeToCache:(NSData *)qrCodeData withParams:(NSMutableDictionary *)parameters {
    @synchronized (self) {
        [self.cache removeAllObjects];
        NSMutableDictionary *tempParams = [parameters mutableCopy];
        [tempParams[@"data"] removeObjectForKey:@"$creation_timestamp"];
        self.cache[tempParams] = qrCodeData;
    }
}

- (NSData *)checkQRCodeCache:(NSMutableDictionary *)parameters {
    NSData *qrCode;
    @synchronized (self) {
        NSMutableDictionary *tempParams = [parameters mutableCopy];
        [tempParams[@"data"] removeObjectForKey:@"$creation_timestamp"];
        qrCode = self.cache[tempParams];
    }
    return qrCode;
}

@end

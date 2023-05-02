//
//  BNCAppleReceipt.m
//  Branch
//
//  Created by Ernest Cho on 7/11/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCAppleReceipt.h"
#import <CommonCrypto/CommonDigest.h>

@interface BNCAppleReceipt()

/*
 Simulator - no receipt, isSandbox = NO
 Testflight or developer side load - no receipt, isSandbox = YES
 App Store installed - receipt, isSandbox = NO
 */
@property (nonatomic, copy, readwrite) NSString *receipt;
@property (nonatomic, assign, readwrite) BOOL isSandboxReceipt;

@end

@implementation BNCAppleReceipt

+ (BNCAppleReceipt *)sharedInstance {
    static BNCAppleReceipt *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [BNCAppleReceipt new];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.receipt = nil;
        self.isSandboxReceipt = NO;
        
        [self readReceipt];
    }
    return self;
}

- (void)readReceipt {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if (receiptURL) {
        self.isSandboxReceipt = [receiptURL.lastPathComponent isEqualToString:@"sandboxReceipt"];
        
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        if (receiptData) {
            self.receipt = [receiptData base64EncodedStringWithOptions:0];
        }
    }
}

- (nullable NSString *)installReceipt {
    return self.receipt;
}

- (BOOL)isTestFlight {
    // sandbox receipts are from testflight or side loaded development devices
    return self.isSandboxReceipt;
}

+ (BOOL)isReceiptValid {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];

    if (!receiptData) {
        return NO;
    }

    NSString *receiptHash = [self sha256HashForData:receiptData];
    if (receiptHash) {
        return YES;
    }

    return NO;
}

+ (NSString *)sha256HashForData:(NSData *)data {
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end

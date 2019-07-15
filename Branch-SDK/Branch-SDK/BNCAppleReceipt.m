//
//  BNCAppleReceipt.m
//  Branch
//
//  Created by Ernest Cho on 7/11/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import "BNCAppleReceipt.h"

@interface BNCAppleReceipt()
@property (nonatomic, strong, readwrite) NSString *receipt;
@end

@implementation BNCAppleReceipt

+ (BNCAppleReceipt *)instance {
    static BNCAppleReceipt *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [BNCAppleReceipt new];
    });
    return singleton;
}

- (nullable NSString *)installReceipt {
    if (!self.receipt) {
        self.receipt = [self readReceipt];
    }
    return self.receipt;
}

- (nullable NSString *)readReceipt {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    return [receiptData base64EncodedStringWithOptions:NSUTF8StringEncoding];
}

@end

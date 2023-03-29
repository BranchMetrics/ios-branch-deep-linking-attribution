//
//  BNCEventUtils.h
//  BranchSDK
//
//  Created by Nipun Singh on 1/31/23.
//
// Apple's StoreKit API requires us to keep a strong reference to the SKProductsRequest in order to receive the response.
// But BranchEvent is designed to be fire and forget, so it doesn't persisnt after being used.
// To work around this, this class holds a reference to the BranchEvent until we receive a response from the StoreKit API.

#import <Foundation/Foundation.h>
#import "BranchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface BNCEventUtils : NSObject

+ (instancetype)shared;

- (void)storeEvent:(BranchEvent *)event;

- (void)removeEvent:(BranchEvent *)event;

@end

NS_ASSUME_NONNULL_END

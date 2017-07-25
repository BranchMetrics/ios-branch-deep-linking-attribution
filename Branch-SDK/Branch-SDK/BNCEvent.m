//
//  BNCEvent.m
//  Branch-TestBed
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCEvent.h"

// Commerce events

BNCStandardEvent BNCStandardEventAddToCart          = @"ADD_TO_CART";
BNCStandardEvent BNCStandardEventAddToWishlist      = @"ADD_TO_WISHLIST";
BNCStandardEvent BNCStandardEventViewCart           = @"VIEW_CART";
BNCStandardEvent BNCStandardEventInitiatePurchase   = @"INITIATE_PURCHASE";
BNCStandardEvent BNCStandardEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BNCStandardEvent BNCStandardEventPurchase           = @"PURCHASE";
BNCStandardEvent BNCStandardEventSpendCredits       = @"SPEND_CREDITS";

// Content Events

BNCStandardEvent BNCStandardEventSearch             = @"SEARCH";
BNCStandardEvent BNCStandardEventViewContent        = @"VIEW_CONTENT";
BNCStandardEvent BNCStandardEventViewContentList    = @"VIEW_CONTENT_LIST";
BNCStandardEvent BNCStandardEventRate               = @"RATE";
BNCStandardEvent BNCStandardEventShareContent       = @"SHARE_CONTENT";

// User Lifecycle Events

BNCStandardEvent BNCStandardEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BNCStandardEvent BNCStandardEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BNCStandardEvent BNCStandardEventAchieveLevel           = @"ACHIEVE_LEVEL";
BNCStandardEvent BNCStandardEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";

@implementation Branch (BNCStandardEvents)

- (void) trackStandardEvent:(BNCStandardEvent)event
             withCustomData:(NSDictionary<NSString*, id<NSObject>>*)customData {
}

- (void) trackStandardEvent:(BNCStandardEvent)standardEvent
              withEventData:(NSDictionary<NSString*, id<NSObject>>*)dictionary
               contentItems:(NSArray<BranchUniversalObject*>*)contentItems {
}

- (void) trackStandardEvent:(BNCStandardEvent)event
              withEventData:(NSDictionary<NSString*, id<NSObject>>*)eventData
               contentItems:(NSArray<BranchUniversalObject*>*)universalObject
                 customData:(NSDictionary<NSString*, id<NSObject>>*)customData {
}

- (void) trackCustomEvent:(NSString*)event
           withCustomData:(NSDictionary<NSString*, id<NSObject>>*)dictionary {
}

@end

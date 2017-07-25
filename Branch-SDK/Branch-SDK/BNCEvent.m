//
//  BNCEvent.m
//  Branch-TestBed
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCEvent.h"

// Commerce events

BNCStandardEvent BNCEventAddToCart          = @"ADD_TO_CART";
BNCStandardEvent BNCEventAddToWishlist      = @"ADD_TO_WISHLIST";
BNCStandardEvent BNCEventViewCart           = @"VIEW_CART";
BNCStandardEvent BNCEventInitiatePurchase   = @"INITIATE_PURCHASE";
BNCStandardEvent BNCEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BNCStandardEvent BNCEventPurchase           = @"PURCHASE";
BNCStandardEvent BNCEventSpendCredits       = @"SPEND_CREDITS";

// Content Events

BNCStandardEvent BNCEventSearch             = @"SEARCH";
BNCStandardEvent BNCEventViewContent        = @"VIEW_CONTENT";
BNCStandardEvent BNCEventViewContentList    = @"VIEW_CONTENT_LIST";
BNCStandardEvent BNCEventRate               = @"RATE";
BNCStandardEvent BNCEventShareContent       = @"SHARE_CONTENT";

// User Lifecycle Events

BNCStandardEvent BNCEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BNCStandardEvent BNCEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BNCStandardEvent BNCEventAchieveLevel           = @"ACHIEVE_LEVEL";
BNCStandardEvent BNCEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";

@implementation Branch (BNCStandardEvents)

- (void) trackStandardEvent:(BNCStandardEvent)standardEvent
              withEventData:(NSDictionary*)dictionary
               contentItems:(NSArray<BranchUniversalObject*>*)contentItems {
}

- (void) trackCustomEvent:(NSString*)event
            withEventData:(NSDictionary*)dictionary
             contentItems:(NSArray<BranchUniversalObject*>*)contentItems {
}

@end

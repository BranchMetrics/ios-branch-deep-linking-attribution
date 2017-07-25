//
//  BNCEvent.h
//  Branch-TestBed
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Branch.h"

typedef NSString*const BNCStandardEvent;

// Commerce Events

extern BNCStandardEvent BNCEventAddToCart;
extern BNCStandardEvent BNCEventAddToWishlist;
extern BNCStandardEvent BNCEventViewCart;
extern BNCStandardEvent BNCEventInitiatePurchase;
extern BNCStandardEvent BNCEventAddPaymentInfo;
extern BNCStandardEvent BNCEventPurchase;
extern BNCStandardEvent BNCEventSpendCredits;

// Content Events

extern BNCStandardEvent BNCEventSearch;
extern BNCStandardEvent BNCEventViewContent;
extern BNCStandardEvent BNCEventViewContentList;
extern BNCStandardEvent BNCEventRate;
extern BNCStandardEvent BNCEventShareContent;

// User Lifecycle Events

extern BNCStandardEvent BNCEventCompleteRegistration;
extern BNCStandardEvent BNCEventCompleteTutorial;
extern BNCStandardEvent BNCEventAchieveLevel;
extern BNCStandardEvent BNCEventUnlockAchievement;

// TODO: User Rated app event?

@interface Branch (BNCStandardEvents)

- (void) trackStandardEvent:(BNCStandardEvent)standardEvent
              withEventData:(NSDictionary<NSString*, id<NSObject>>*)dictionary
               contentItems:(NSArray<BranchUniversalObject*>*)contentItems;

- (void) trackCustomEvent:(NSString*)event
            withEventData:(NSDictionary<NSString*, id<NSObject>>*)dictionary
             contentItems:(NSArray<BranchUniversalObject*>*)contentItems;

@end

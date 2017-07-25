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

extern BNCStandardEvent BNCStandardEventAddToCart;
extern BNCStandardEvent BNCStandardEventAddToWishlist;
extern BNCStandardEvent BNCStandardEventViewCart;
extern BNCStandardEvent BNCStandardEventInitiatePurchase;
extern BNCStandardEvent BNCStandardEventAddPaymentInfo;
extern BNCStandardEvent BNCStandardEventPurchase;
extern BNCStandardEvent BNCStandardEventSpendCredits;

// Content Events

extern BNCStandardEvent BNCStandardEventSearch;
extern BNCStandardEvent BNCStandardEventViewContent;
extern BNCStandardEvent BNCStandardEventViewContentList;
extern BNCStandardEvent BNCStandardEventRate;
extern BNCStandardEvent BNCStandardEventShareContent;

// User Lifecycle Events

extern BNCStandardEvent BNCStandardEventCompleteRegistration;
extern BNCStandardEvent BNCStandardEventCompleteTutorial;
extern BNCStandardEvent BNCStandardEventAchieveLevel;
extern BNCStandardEvent BNCStandardEventUnlockAchievement;


// Extend the Branch class for standard events

@class BranchEventProperties;

@interface BranchEvent : NSObject

+ (BranchEvent*) newStandardEvent:(BNCStandardEvent)event;
- (BranchEvent*) addProperties:(BranchEventProperties*)properties;
- (BranchEvent*) addContentItems:(NSArray<BranchUniversalObject*>*)contentItems;
- (void) track;

@end

@interface Branch (BNCStandardEvents)

- (void) trackStandardEvent:(BNCStandardEvent)event
             withCustomData:(NSDictionary<NSString*, id<NSObject>>*)customData;

- (void) trackStandardEvent:(BNCStandardEvent)standardEvent
              withEventData:(NSDictionary<NSString*, id<NSObject>>*)dictionary
               contentItems:(NSArray<BranchUniversalObject*>*)contentItems;

- (void) trackStandardEvent:(BNCStandardEvent)event
              withEventData:(NSDictionary<NSString*, id<NSObject>>*)eventData
               contentItems:(NSArray<BranchUniversalObject*>*)universalObject
                 customData:(NSDictionary<NSString*, id<NSObject>>*)customData;

- (void) trackCustomEvent:(NSString*)event
           withCustomData:(NSDictionary<NSString*, id<NSObject>>*)dictionary;

@end

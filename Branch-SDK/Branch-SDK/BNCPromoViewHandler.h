//
//  BNCPromoViewHandler.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/3/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#ifndef BNCPromoViewHandler_h
#define BNCPromoViewHandler_h


#endif /* BNCPromoViewHandler_h */
#import "BNCAppPromoView.h"


@protocol BranchPromoViewControllerDelegate <NSObject>

- (void)promoViewVisible: (NSString *) actionName;
- (void)promoViewAccepted: (NSString *) actionName;
- (void)promoViewCancelled: (NSString *) actionName;

@end


@interface BNCPromoViewHandler : NSObject

//---- Properties---------------//

@property (nonatomic, assign) id  <BranchPromoViewControllerDelegate> promoViewCallback;

/**
 Cache for saving AppPromoViews locally
 */
@property (strong, nonatomic) NSMutableArray *promoViewCache;


//-- Methods--------------------//

/**
 Gets the global instance for BNCPromoViewHandler.
 */
+ (BNCPromoViewHandler *)getInstance;

/**
 Shows a promo view for the given action if available
 */
- (BOOL) showPromoView : (NSString*) actionName withCallback:(id) callback;

/**
  Adds a given list of promoviews to cache
 */
- (void) saveAppPromoViews : (NSArray *) promoViewList;

@end

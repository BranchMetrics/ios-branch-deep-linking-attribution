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
#import "AppPromoView.h"

@interface BNCPromoViewHandler : NSObject

//---- Properties---------------//
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
- (BOOL) showPromoView : (NSString *) actionName;

/**
  Adds a given list of promoviews to cache
 */
- (void) saveAppPromoViews : (NSArray *) promoViewList;

@end

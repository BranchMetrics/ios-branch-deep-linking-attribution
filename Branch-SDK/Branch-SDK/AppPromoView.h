//
//  AppPromoView.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface AppPromoView : NSObject
//-------- properties-------------------//
/**
 Unique ID for thsi app promo
 */
@property (strong, nonatomic) NSString *promoID;
/**
 User or Branch action associated with the app promo
 */
@property (strong, nonatomic) NSString *promoAction;
/**
 Number of times this promo view can be used
 */
@property (nonatomic) NSInteger numOfUse;
/**
 Epoach millisec denoting expiration for this app promo
 */
@property (nonatomic, strong) NSDate *expirationDate;
/**
 Web url to for showing html content for the promo iew
 */
@property (strong, nonatomic) NSString *webUrl;

//---------- Methods---------------//
/**
 Initialises promo view with the give promo view dictionary
 */
- (id) initWithPromoView : (NSDictionary *) promoViewDict;

/**
 check promo view for expiry and uasage count
 */
- (BOOL) isAvailable;

/**
 Decrement the usage count for this promo view by 1
 */
- (void) updateUsageCount;

@end

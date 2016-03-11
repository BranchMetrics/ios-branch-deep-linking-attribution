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
 Unique ID for this app promo
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
 Epoch millisec denoting expiration for this app promo
 */
@property (nonatomic, strong) NSDate *expirationDate;
/**
 Web url to for showing html content for the Branch View
 */
@property (strong, nonatomic) NSString *webUrl;
/**
 Html content for loading the web view
 */
@property (strong, nonatomic) NSString *webHtml;

//---------- Methods---------------//
/**
 Initialises promo view with the give promo view dictionary
 */
- (id)initWithPromoView:(NSDictionary *)promoViewDict;
/**
 check promo view for expiry and uasage count
 */
- (BOOL)isAvailable;
/**
 update the usage count for this Branch view
 */
- (void)updateUsageCount;

@end

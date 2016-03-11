//
//  AppPromoView.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/4/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCAppPromoView.h"

NSInteger const APP_PROMO_USAGE_UNLIMITED = -1;
NSString * const APP_PROMO_ID = @"app_promo_id";
NSString * const APP_PROMO_ACTION = @"app_promo_action";
NSString * const APP_PROMO_NUM_USE = @"num_of_use";
NSString * const APP_PROMO_EXPIRY = @"expiry";
NSString * const APP_PROMO_WEBURL = @"promo_view_url";
NSString * const APP_PROMO_WEBHTML = @"promo_view_html";

@interface AppPromoView()
@end

@implementation AppPromoView

- (id)initWithPromoView:(NSDictionary *)promoViewDict {
    if (self = [super init]) {
        self.promoID = [promoViewDict objectForKey:APP_PROMO_ID];
        self.promoAction = [promoViewDict objectForKey:APP_PROMO_ACTION];
        self.numOfUse = [[promoViewDict objectForKey:APP_PROMO_NUM_USE] integerValue];
        self.expirationDate = [NSDate dateWithTimeIntervalSince1970:[[promoViewDict objectForKey:APP_PROMO_EXPIRY] doubleValue]/1000];
        self.webUrl = [promoViewDict objectForKey:APP_PROMO_WEBURL];
        self.webHtml = [promoViewDict objectForKey:APP_PROMO_WEBHTML];
    }
    return self;
}

- (BOOL)isAvailable {
    return (self.expirationDate.timeIntervalSinceNow > 0
             && (self.numOfUse > 0 || self.numOfUse == APP_PROMO_USAGE_UNLIMITED));
}

- (void)updateUsageCount {
    if (self.numOfUse > 0) {
        self.numOfUse--;
    }
}

@end


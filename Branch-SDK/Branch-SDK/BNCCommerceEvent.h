//
//  BNCCommerceEvent.h
//  BranchSDK-iOS
//
//  Created by Edward Smith on 12/14/16.
//  Copyright (c) 2016 Branch Metrics. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BNCServerRequest.h"


@interface BNCProduct : NSObject
@property (nonatomic, strong) NSString *sku;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, strong) NSNumber *quantity;
@property (nonatomic, strong) NSString *brand;
@property (nonatomic, strong) NSString *category;
@property (nonatomic, strong) NSString *variant;
@end


@interface BNCCommerceEvent : NSObject
@property (nonatomic, strong) NSDecimalNumber *revenue;
@property (nonatomic, strong) NSString *currency;
@property (nonatomic, strong) NSString *transactionID;
@property (nonatomic, strong) NSDecimalNumber *shipping;
@property (nonatomic, strong) NSDecimalNumber *tax;
@property (nonatomic, strong) NSString *coupon;
@property (nonatomic, strong) NSString *affiliation;
@property (nonatomic, strong) NSArray<BNCProduct*> *products;
@end


@interface BranchCommerceEventRequest : BNCServerRequest <NSCoding>

- (instancetype) initWithCommerceEvent:(BNCCommerceEvent*)commerceEvent
							  metadata:(NSDictionary*)dictionary
							completion:(void (^)(NSDictionary* response, NSError* error))callBack;

@end

//
//  KindredServerInterface.m
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import "KindredServerInterface.h"
#import "DevPreferenceHelper.h"
@implementation KindredServerInterface

// PARTNER RELATED
- (void)getPartnerDetails {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/partner"] andTag:REQ_TAG_GET_PARTNER andIdentifier:kpServerIdentNone];
}

// USER RELATED
- (void)loginUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/login/"] andTag:REQ_TAG_LOGIN andIdentifier:kpServerIdentNone];
}
- (void)createUser:(NSDictionary *)post {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/create/"] andTag:REQ_TAG_REGISTER andIdentifier:kpServerIdentNone];
}
- (void)startPasswordReset:(NSDictionary *)post {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/send/password/reset/"] andTag:REQ_TAG_PASSWORD_RESET andIdentifier:kpServerIdentNone];
}
- (void)registerStripeToken:(NSDictionary *)post userId:(NSString *)userId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:userId] stringByAppendingString:@"/register/stripe/"] andTag:REQ_TAG_STRIPE_REG andIdentifier:kpServerIdentNone];
}
- (void)registerName:(NSDictionary *)post userId:(NSString *)userId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:userId] stringByAppendingString:@"/register/name/"] andTag:REQ_TAG_NAME_REG andIdentifier:kpServerIdentNone];
}

// ADDRESS RELATED
- (void)downloadAllAddresses:(NSDictionary *)post userId:(NSString *)userId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:userId] stringByAppendingString:@"/addresses/list/"] andTag:REQ_TAG_GET_ADDRESSES andIdentifier:kpServerIdentNone];
}
- (void)createNewAddress:(NSDictionary *)post userId:(NSString *)userId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:userId] stringByAppendingString:@"/addresses/create/"] andTag:REQ_TAG_CREATE_NEW_ADDRESS andIdentifier:kpServerIdentNone];
}
- (void)updateAddress:(NSDictionary *)post userId:(NSString *)userId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:userId] stringByAppendingString:@"/addresses/edit/"] andTag:REQ_TAG_UPDATE_ADDRESS andIdentifier:kpServerIdentNone];
}
- (void)getCountryList {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/countries"] andTag:REQ_TAG_GET_COUNTRIES andIdentifier:kpServerIdentNone];
}

- (void)getShipQuotes:(NSString *)orderId addressId:(NSString *)addressId {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/orders/"] stringByAppendingString:orderId] stringByAppendingString:@"/ship-quotes/"] stringByAppendingString:addressId] andTag:REQ_TAG_GET_SHIP_QUOTE andIdentifier:addressId];
}

// IMAGE RELATED
- (void)getCurrentImageSizes {
    [self getRequestAsync:[[NSDictionary alloc] init] url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/prices"] andTag:REQ_TAG_GET_IMAGE_SIZES andIdentifier:kpServerIdentNone];
}

- (void)createURLImage:(NSDictionary *)post withIdent:(NSString *)ident {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/images"] andTag:REQ_TAG_CREATE_URL_IMAGE andIdentifier:ident];
}
- (void)createImage:(NSDictionary *)post withIdent:(NSString *)ident {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/images"] andTag:REQ_TAG_CREATE_IMAGE andIdentifier:ident];
}
- (void)checkStatusOfImage:(NSDictionary *)post image:(NSString *)imageId origId:(NSString *)oridId{
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/images/"] stringByAppendingString:imageId] stringByAppendingString:@"/reupload"] andTag:REQ_TAG_GET_IMAGE_STATUS andIdentifier:oridId];
}
- (void)uploadImage:(NSDictionary *)post image:(NSData *)image imageId:(NSString *)imageId {
    [self postToAWSRequestWithImageAsync:[post objectForKey:@"params"] image:image url:[post objectForKey:@"url"] andTag:REQ_TAG_UPLOAD_IMAGE andIdentifier:imageId];
}

- (void)createPrintableImage:(NSDictionary *)post withIdent:(NSString *)ident {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/printableimages"] andTag:REQ_TAG_CREATE_PRINTABLE_IMAGE andIdentifier:ident];
}

- (void)createLineItem:(NSDictionary *)post withIdent:(NSString *)ident {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/lineitems"] andTag:REQ_TAG_CREATE_LINE_ITEM andIdentifier:ident];
}
- (void)updateLineItem:(NSDictionary *)post lineItemId:(NSString *)lineitemId withIdent:(NSString *)ident {
    [self postRequestAsync:post url:[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/lineitems/"] stringByAppendingString:lineitemId] andTag:REQ_TAG_UPDATE_LINE_ITEM andIdentifier:ident];
}

// PAYMENT RELATED

- (void)getUserPaymentDetails:(NSDictionary *)post userId:(NSString *)user_id {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v0/api/users/"] stringByAppendingString:user_id] stringByAppendingString:@"/get/payment/status/"] andTag:REQ_TAG_GET_USER_PAYMENT andIdentifier:kpServerIdentNone];
}

- (void)createOrderObject:(NSDictionary *)post {
    [self postRequestAsync:post url:[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/orders"] andTag:REQ_TAG_CREATE_ORDER_OBJ andIdentifier:kpServerIdentNone];
}

- (void)updateOrderObject:(NSDictionary *)post andOrderId:(NSString *)oid {
    [self postRequestAsync:post url:[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/orders/"] stringByAppendingString:oid] andTag:REQ_TAG_UPDATE_ORDER_OBJ andIdentifier:kpServerIdentNone];
}

- (void)checkoutOrder:(NSDictionary *)post andOrderId:(NSString *)oid {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/orders/"] stringByAppendingString:oid] stringByAppendingString:@"/checkout"] andTag:REQ_TAG_CHECKOUT_ORDER andIdentifier:kpServerIdentNone];
}

- (void)applyCouponToOrder:(NSDictionary *)post andOrderId:(NSString *)oid andCouponId:(NSString *)couponId {
    [self postRequestAsync:post url:[[[[DevPreferenceHelper getAPIServerAddress] stringByAppendingString:@"v1/orders/"] stringByAppendingString:oid] stringByAppendingString:@"/coupon"] andTag:REQ_TAG_APPLY_COUPON andIdentifier:couponId];
}

@end

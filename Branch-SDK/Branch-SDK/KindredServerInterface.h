//
//  KindredServerInterface.h
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import "ServerInterface.h"

static NSString *REQ_TAG_GET_PARTNER = @"t_get_partner";

static NSString *REQ_TAG_LOGIN = @"t_login";
static NSString *REQ_TAG_REGISTER = @"t_register";
static NSString *REQ_TAG_PASSWORD_RESET = @"t_password_reset";
static NSString *REQ_TAG_STRIPE_REG = @"t_reg_stripe";
static NSString *REQ_TAG_NAME_REG = @"t_reg_name";

static NSString *REQ_TAG_GET_ADDRESSES = @"t_get_addresses";
static NSString *REQ_TAG_CREATE_NEW_ADDRESS = @"t_create_address";
static NSString *REQ_TAG_UPDATE_ADDRESS = @"t_update_address";
static NSString *REQ_TAG_GET_COUNTRIES = @"t_get_countries";
static NSString *REQ_TAG_GET_SHIP_QUOTE = @"t_get_ship_quotes";

static NSString *REQ_TAG_GET_IMAGE_SIZES = @"t_get_image_sizes";

static NSString *REQ_TAG_CREATE_URL_IMAGE = @"t_create_url_image";
static NSString *REQ_TAG_CREATE_IMAGE = @"t_create_image";
static NSString *REQ_TAG_GET_IMAGE_STATUS = @"t_check_image_status";
static NSString *REQ_TAG_UPLOAD_IMAGE = @"t_upload_image";

static NSString *REQ_TAG_CREATE_PRINTABLE_IMAGE = @"t_create_printable_image";
static NSString *REQ_TAG_CREATE_LINE_ITEM = @"t_create_line_item";
static NSString *REQ_TAG_UPDATE_LINE_ITEM = @"t_update_line_item";

static NSString *REQ_TAG_CREATE_ORDER_OBJ = @"t_create_order_obj";
static NSString *REQ_TAG_UPDATE_ORDER_OBJ = @"t_update_order_obj";
static NSString *REQ_TAG_CHECKOUT_ORDER = @"t_checkout_order";
static NSString *REQ_TAG_APPLY_COUPON = @"t_apply_coupon";


static NSString *REQ_TAG_GET_USER_PAYMENT = @"t_get_user_payment";

@interface KindredServerInterface : ServerInterface

// PARTNER RELATED
- (void)getPartnerDetails;

// USER RELATED
- (void)loginUser:(NSDictionary *)post;
- (void)createUser:(NSDictionary *)post;
- (void)startPasswordReset:(NSDictionary *)post;
- (void)registerStripeToken:(NSDictionary *)post userId:(NSString *)userId;
- (void)registerName:(NSDictionary *)post userId:(NSString *)userId;

// ADDRESS RELATED
- (void)downloadAllAddresses:(NSDictionary *)post userId:(NSString *)userId;
- (void)createNewAddress:(NSDictionary *)post userId:(NSString *)userId;
- (void)updateAddress:(NSDictionary *)post userId:(NSString *)userId;
- (void)getCountryList;
- (void)getShipQuotes:(NSString *)orderId addressId:(NSString *)addressId;

// IMAGE RELATED
- (void)getCurrentImageSizes;
- (void)createURLImage:(NSDictionary *)post withIdent:(NSString *)ident;
- (void)createImage:(NSDictionary *)post withIdent:(NSString *)ident;
- (void)checkStatusOfImage:(NSDictionary *)post image:(NSString *)imageId origId:(NSString *)oridId;
- (void)uploadImage:(NSDictionary *)post image:(NSData *)image imageId:(NSString *)imageId;
- (void)createPrintableImage:(NSDictionary *)post withIdent:(NSString *)ident;
- (void)createLineItem:(NSDictionary *)post withIdent:(NSString *)ident;
- (void)updateLineItem:(NSDictionary *)post lineItemId:(NSString *)lineitemId withIdent:(NSString *)ident;

// PAYMENT RELATED
- (void)getUserPaymentDetails:(NSDictionary *)post userId:(NSString *)user_id;
- (void)createOrderObject:(NSDictionary *)post;
- (void)updateOrderObject:(NSDictionary *)post andOrderId:(NSString *)oid;
- (void)checkoutOrder:(NSDictionary *)post andOrderId:(NSString *)oid;
- (void)applyCouponToOrder:(NSDictionary *)post andOrderId:(NSString *)oid andCouponId:(NSString *)couponId;
@end

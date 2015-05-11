//
//  BNCServerInterface.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/4/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCServerResponse.h"

typedef void (^BNCServerCallback)(BNCServerResponse *response, NSError *error);

static NSString *REQ_TAG_DEBUG_CONNECT = @"t_debug_connect";
static NSString *REQ_TAG_DEBUG_LOG = @"t_debug_log";
static NSString *REQ_TAG_DEBUG_SCREEN = @"t_debug_screen";
static NSString *REQ_TAG_DEBUG_DISCONNECT = @"t_debug_disconnect";

@interface BNCServerInterface : NSObject

- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag;
- (BNCServerResponse *)getRequest:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log;
- (void)getRequest:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag callback:(BNCServerCallback)callback;
- (void)getRequest:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log callback:(BNCServerCallback)callback;

- (BNCServerResponse *)postRequest:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log;
- (void)postRequest:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag callback:(BNCServerCallback)callback;
- (void)postRequest:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log callback:(BNCServerCallback)callback;

- (void)genericHTTPRequest:(NSURLRequest *)request withTag:(NSString *)requestTag callback:(BNCServerCallback)callback;
- (BNCServerResponse *)genericHTTPRequest:(NSURLRequest *)request withTag:(NSString *)requestTag;

@end

//
//  BNCServerInterface.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/4/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCServerResponse.h"

@protocol BNCServerInterfaceDelegate <NSObject>

@optional
- (void)serverCallback:(BNCServerResponse *)returnedData;

@end

static NSString *kpServerIdentNone = @"no_value";
static NSString *REQ_TAG_DEBUG_CONNECT = @"t_debug_connect";
static NSString *REQ_TAG_DEBUG_LOG = @"t_debug_log";
static NSString *REQ_TAG_DEBUG_SCREEN = @"t_debug_screen";
static NSString *REQ_TAG_DEBUG_DISCONNECT = @"t_debug_disconnect";


@interface BNCServerInterface : NSObject

@property (nonatomic, strong) id <BNCServerInterfaceDelegate> delegate;

+ (NSString *)encodePostToUniversalString:(NSDictionary *)params;
+ (NSString *)encodePostToUniversalString:(NSDictionary *)params needSource:(BOOL)source;

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag;
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log;
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag;
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag log:(BOOL)log;
- (void)genericHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag;

@end

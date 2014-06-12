//
//  ServerInterface.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/4/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServerInterfaceDelegate <NSObject>

@optional
- (void)serverCallback:(NSDictionary *)returnedData;

@end

static NSString *kpServerIdentNone = @"no_value";

static NSString *kpServerRequestTag = @"server_request_tag";
static NSString *kpServerStatusCode = @"server_return_code";

@interface ServerInterface : NSObject

@property (nonatomic, strong) id <ServerInterfaceDelegate> delegate;

+ (NSString *)encodePostToUniversalString:(NSDictionary *)params;

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag;
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag;
- (void)genericHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag;

@end

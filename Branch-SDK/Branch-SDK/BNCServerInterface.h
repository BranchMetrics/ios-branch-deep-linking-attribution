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

@interface BNCServerInterface : NSObject

@property (nonatomic, strong) id <BNCServerInterfaceDelegate> delegate;

+ (NSString *)encodePostToUniversalString:(NSDictionary *)params;

- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag;
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag;
- (void)genericHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag;

@end

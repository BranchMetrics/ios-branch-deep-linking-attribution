//
//  ServerInterface.h
//  KindredPrints-iOS-TestBed
//
//  Created by Alex Austin on 1/31/14.
//  Copyright (c) 2014 Kindred Prints. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServerInterfaceDelegate <NSObject>

@optional
- (void)serverCallback:(NSDictionary *)returnedData;

@end

static NSString *kpServerIdentNone = @"none";

static NSString *kpServerRequestTag = @"server_request_tag";
static NSString *kpServerIdentTag = @"server_ident_tag";
static NSString *kpServerStatusCode = @"server_return_code";

@interface ServerInterface : NSObject

@property (nonatomic, strong) id <ServerInterfaceDelegate> delegate;

- (void)postToAWSRequestWithImageAsync:(NSDictionary *)post image:(NSData *)image url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident;
- (void)postRequestAsync:(NSDictionary *)post url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident;
- (void)getRequestAsync:(NSDictionary *)params url:(NSString *)url andTag:(NSString *)requestTag andIdentifier:(NSString *)ident;
- (void)genericHTTPRequest:(NSMutableURLRequest *)request withTag:(NSString *)requestTag andIdentifier:(NSString *)ident withAuth:(BOOL)auth;

@end

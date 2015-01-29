//
//  BNCServerRequest.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCLinkData.h"

@interface BNCServerRequest : NSObject

@property (strong, nonatomic) NSString *tag;
@property (strong, nonatomic) NSDictionary *postData;
@property (strong, nonatomic) BNCLinkData *linkData;

- (id)initWithTag:(NSString *)tag;
- (id)initWithTag:(NSString *)tag andData:(NSDictionary *)postData;

@end

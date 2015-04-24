//
//  BNCServerRequest.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCServerInterface.h"

@interface BNCServerRequest : NSObject

@property (strong, nonatomic) NSString *tag;
@property (strong, nonatomic) NSMutableDictionary *postData;
@property (strong, nonatomic) BNCServerCallback callback;

- (id)initWithTag:(NSString *)tag;
- (id)initWithTag:(NSString *)tag andData:(NSMutableDictionary *)postData;

@end

//
//  ServerRequest.h
//  Branch-SDK
//
//  Created by Alex Austin on 6/5/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerRequest : NSObject

@property (strong, nonatomic) NSString *tag;
@property (strong, nonatomic) NSDictionary *postData;

@end

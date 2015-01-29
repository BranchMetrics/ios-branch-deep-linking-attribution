//
//  BNCServerResponse.h
//  Branch-SDK
//
//  Created by Qinwei Gong on 10/10/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNCLinkData.h"

@interface BNCServerResponse : NSObject

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) BNCLinkData *linkData;

- (id)initWithTag:(NSString *)tag andStatusCode:(NSNumber *)code;

@end

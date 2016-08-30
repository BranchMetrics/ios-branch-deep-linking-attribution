//
//  ContentPathProperties.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/19/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#ifndef ContentPathProperties_h
#define ContentPathProperties_h


#endif /* ContentPathProperties_h */

@interface BranchContentPathProperties : NSObject

@property (strong, nonatomic) NSDictionary *pathInfo;
@property (nonatomic) BOOL isClearText;

- (instancetype)init:(NSDictionary *)pathInfo;
- (NSArray *)getFilteredElements;
- (BOOL)isSkipContentDiscovery;
- (BOOL)isClearText;

@end
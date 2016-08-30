//
//  ContentDiscoverer.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/17/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "BranchContentDiscoveryManifest.h"

#ifndef ContentDiscoverer_h
#define ContentDiscoverer_h


#endif /* ContentDiscoverer_h */

@interface BranchContentDiscoverer : NSObject

//----------- Methods ----------------//
+ (BranchContentDiscoverer *)getInstance:(BranchContentDiscoveryManifest *)manifest;
+ (BranchContentDiscoverer *)getInstance;
- (void)startContentDiscoveryTask;
- (void)stopContentDiscoveryTask;

@end

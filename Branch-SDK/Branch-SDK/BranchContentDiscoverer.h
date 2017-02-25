//
//  ContentDiscoverer.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/17/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "BranchContentDiscoveryManifest.h"


@interface BranchContentDiscoverer : NSObject

//----------- Methods ----------------//
+ (BranchContentDiscoverer *)getInstance;
- (void) startDiscoveryTaskWithManifest:(BranchContentDiscoveryManifest*)manifest;
- (void) startDiscoveryTask;
- (void) stopDiscoveryTask;

@property (nonatomic, strong) BranchContentDiscoveryManifest* contentManifest;
@end

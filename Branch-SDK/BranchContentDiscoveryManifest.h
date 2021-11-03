//
//  ContentDiscoverManifest.h
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/18/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import "BranchContentPathProperties.h"

@interface BranchContentDiscoveryManifest : NSObject

@property (strong, nonatomic) NSMutableDictionary *cdManifest;
@property (nonatomic, copy) NSString *referredLink;
@property (nonatomic, assign) NSInteger maxTextLen;
@property (nonatomic, assign) NSInteger maxViewHistoryLength;
@property (nonatomic, assign) NSInteger maxPktSize;
@property (nonatomic, assign) BOOL isCDEnabled;
@property (strong, nonatomic) NSMutableArray *contentPaths;

+ (BranchContentDiscoveryManifest *)getInstance;
- (NSString *)getManifestVersion;
- (BranchContentPathProperties *)getContentPathProperties:(UIViewController *)viewController;
- (void)onBranchInitialised:(NSDictionary *)branchInitDict withUrl:(NSString *)referringURL;
@end

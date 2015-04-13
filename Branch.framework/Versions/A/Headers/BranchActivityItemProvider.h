//
//  BranchActivityItemProvider.h
//  Branch-TestBed
//
//  Created by Scott Hasbrouck on 1/28/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BranchActivityItemProvider : UIActivityItemProvider

@property (strong, nonatomic) NSString *branchURL;
@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSString *alias;
@property dispatch_semaphore_t semaphore;

- (id)initWithDefaultURL:(NSString *)url
               andParams:(NSDictionary *)params
                 andTags:(NSArray *)tags
              andFeature:(NSString *)feature
                andStage:(NSString *)stage
                andAlias:(NSString *)alias;

@end

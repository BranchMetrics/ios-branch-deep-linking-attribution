//
//  BranchCSSearchableItemAttributeSet.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 9/8/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import <CoreSpotlight/CoreSpotlight.h>
#import "Branch.h"

@interface BranchCSSearchableItemAttributeSet : CSSearchableItemAttributeSet

- (id)init;
- (id)initWithContentType:(NSString *)type;

@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSSet *keywords;

// Defaults to YES
@property (nonatomic) BOOL publiclyIndexable;

- (void)indexWithCallback:(callbackWithUrlAndSpotlightIdentifier)callback;

@end

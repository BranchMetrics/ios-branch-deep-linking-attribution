//
//  BranchCSSearchableItemAttributeSet.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 9/8/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <CoreSpotlight/CoreSpotlight.h>
#endif
#import "Branch.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
@interface BranchCSSearchableItemAttributeSet : CSSearchableItemAttributeSet
#else
@interface BranchCSSearchableItemAttributeSet : NSObject
#endif

- (id)init;
- (id)initWithContentType:(NSString *)type;

@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSSet *keywords;

// Defaults to YES
@property (nonatomic) BOOL publiclyIndexable;

- (void)indexWithCallback:(callbackWithUrlAndSpotlightIdentifier)callback;

@end

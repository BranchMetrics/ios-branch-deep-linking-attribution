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

- (id)initWithParams:(NSDictionary *)params andTitle:(NSString *)title;
- (id)initWithParams:(NSDictionary *)params andTitle:(NSString *)title andContentType:(NSString *)type;

// Defaults to YES
- (void)setPubliclyIndexable:(BOOL)publiclyIndexable;

- (void)setKeywords:(NSSet *)keywords;

- (void)indexWithCallback:(callbackWithUrlAndSpotlightIdentifier)callback;

@end

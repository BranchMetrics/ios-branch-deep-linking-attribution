//
//  BranchCSSearchableItemAttributeSet.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 9/8/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//
#if !TARGET_OS_TV

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if __has_feature(modules)
@import CoreSpotlight;
@import MobileCoreServices;
#else
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BranchCSSearchableItemAttributeSet : CSSearchableItemAttributeSet

- (instancetype)init;

- (instancetype)initWithContentType:(UTType *)contentType API_AVAILABLE(ios(14), macCatalyst(14));

- (instancetype)initWithItemContentType:(NSString *)type;

- (void)indexWithCallback:(void (^) (NSString * _Nullable url, NSString * _Nullable spotlightIdentifier, NSError * _Nullable error))callback;

@property (nonatomic, strong, nullable) NSDictionary *params;
@property (nonatomic, strong, nullable) NSSet *keywords;
@property (nonatomic, assign) BOOL publiclyIndexable; //!< Defaults to YES

@end

NS_ASSUME_NONNULL_END
#endif

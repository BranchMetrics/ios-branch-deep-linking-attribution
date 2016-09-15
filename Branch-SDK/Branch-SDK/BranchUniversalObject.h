//
//  BranchUniversalObject.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Branch.h"

@class BranchLinkProperties;

typedef void (^shareCompletion) (NSString * _Nullable activityType, BOOL completed);
typedef void (^shareCompletionWithError) (NSString * _Nullable activityType, BOOL completed, NSError * _Nullable activityError);

typedef NS_ENUM(NSInteger, ContentIndexMode) {
    ContentIndexModePublic,
    ContentIndexModePrivate
};

@interface BranchUniversalObject : NSObject

@property (nonatomic, strong, nonnull) NSString *canonicalIdentifier;
@property (nonatomic, strong, nullable) NSString *canonicalUrl;
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSString *contentDescription;
@property (nonatomic, strong, nullable) NSString *imageUrl;
// Note: properties found in metadata will overwrite properties on the BranchUniversalObject itself
@property (nonatomic, strong, nullable) NSDictionary *metadata;
@property (nonatomic, strong, nullable) NSString *type;
@property (nonatomic) ContentIndexMode contentIndexMode;
@property (nonatomic, strong, nullable) NSArray *keywords;
@property (nonatomic, strong, nullable) NSDate *expirationDate;
@property (nonatomic, strong, nullable) NSString *spotlightIdentifier;
@property (nonatomic, assign) CGFloat price;
@property (nonatomic, strong, nullable) NSString *currency;
@property (nonatomic, assign) BOOL automaticallyListOnSpotlight;


- (nonnull instancetype)initWithCanonicalIdentifier:(nonnull NSString *)canonicalIdentifier;
- (nonnull instancetype)initWithTitle:(nonnull NSString *)title;

- (void)addMetadataKey:(nonnull NSString *)key value:(nonnull NSString *)value;

- (void)registerView;
- (void)registerViewWithCallback:(nullable callbackWithParams)callback;

- (void)userCompletedAction:(nonnull NSString *)action;

- (nullable NSString *)getShortUrlWithLinkProperties:(nonnull BranchLinkProperties *)linkProperties;
- (nullable NSString *)getShortUrlWithLinkPropertiesAndIgnoreFirstClick:(nonnull BranchLinkProperties *)linkProperties;
- (void)getShortUrlWithLinkProperties:(nonnull BranchLinkProperties *)linkProperties andCallback:(nonnull callbackWithUrl)callback;

- (nullable UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(nonnull BranchLinkProperties *)linkProperties;

- (void)showShareSheetWithShareText:(nullable NSString *)shareText completion:(nullable shareCompletion)completion;
- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController completion:(nullable shareCompletion)completion;
// Returns with activityError as well
- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController completionWithError:(nullable shareCompletionWithError)completion;
//iPad
- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController anchor:(nullable UIBarButtonItem *)anchor completion:(nullable shareCompletion)completion;
// Returns with activityError as well
- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController anchor:(nullable UIBarButtonItem *)anchor completionWithError:(nullable shareCompletionWithError)completion;

- (void)listOnSpotlight;
- (void)listOnSpotlightWithCallback:(nullable callbackWithUrl)callback;
- (void)listOnSpotlightWithIdentifierCallback:(nullable callbackWithUrlAndSpotlightIdentifier)spotlightCallback __attribute__((deprecated(("iOS 10 has changed how Spotlight indexing works and we’ve updated the SDK to reflect this. Please see https://dev.branch.io/features/spotlight-indexing/overview/ for instructions on migration"))));;

// Convenience method for initSession methods that return BranchUniversalObject, but can be used safely by anyone.
+ (nonnull BranchUniversalObject *)getBranchUniversalObjectFromDictionary:(nonnull NSDictionary *)dictionary;

- (nonnull NSString *)description;

@end

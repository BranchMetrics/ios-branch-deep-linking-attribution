//
//  BranchUniversalObject.h
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchLinkProperties.h"
#import "Branch.h"

typedef void (^callback) ();
typedef void (^shareCompletion) (NSString *activityType, BOOL completed);

@interface BranchUniversalObject : NSObject

typedef NS_ENUM(NSInteger, ContentIndexMode) {
    ContentIndexModePublic,
    ContentIndexModePrivate
};

@property (nonatomic, strong) NSString *canonicalIdentifier;
@property (nonatomic, strong) NSString *canonicalUrl;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *contentDescription;
@property (nonatomic, strong) NSString *imageUrl;
// Note: properties found in metadata will overwrite properties on the BranchUniversalObject itself
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) ContentIndexMode contentIndexMode;
@property (nonatomic, strong) NSArray *keywords;
@property (nonatomic, strong) NSDate *expirationDate;
@property (nonatomic, strong) NSString *spotlightIdentifier;

- (instancetype)initWithCanonicalIdentifier:(NSString *)canonicalIdentifier;
- (instancetype)initWithTitle:(NSString *)title;
- (void)addMetadataKey:(NSString *)key value:(NSString *)value;
- (void)registerView;
- (void)registerViewWithCallback:(callbackWithParams)callback;
- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties;
- (void)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties andCallback:(callbackWithUrl)callback;
- (UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(BranchLinkProperties *)linkProperties;
- (void)showShareSheetWithShareText:(NSString *)shareText andCallback:(callback)callback __attribute__((deprecated(("This method has been deprecated. Use -[showShareSheetWithShareText:completion:] instead."))));
- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController andCallback:(callback)callback __attribute__((deprecated(("This method has been deprecated. Use -[showShareSheetWithLinkProperties:andShareText:fromViewController:viewController:completion:] instead."))));
- (void)showShareSheetWithShareText:(NSString *)shareText completion:(shareCompletion)completion;
- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController completion:(shareCompletion)completion;

- (void)listOnSpotlight;
- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback;
- (void)listOnSpotlightWithIdentifierCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback;

// Convenience method for initSession methods that return BranchUniversalObject, but can be used safely by anyone.
+ (BranchUniversalObject *)getBranchUniversalObjectFromDictionary:(NSDictionary *)dictionary;

- (NSString *)description;

@end

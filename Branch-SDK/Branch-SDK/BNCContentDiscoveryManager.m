//
//  BNCContentDiscoveryManager.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 7/17/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCPreferenceHelper.h"
#import "BNCContentDiscoveryManager.h"
#import "BNCSystemObserver.h"
#import "BNCError.h"
#import "BranchConstants.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#ifndef kUTTypeGeneric
#define kUTTypeGeneric @"public.content"
#endif

#ifndef CSSearchableItemActionType
#define CSSearchableItemActionType @"com.apple.corespotlightitem"
#endif

#ifndef CSSearchableItemActivityIdentifier
#define CSSearchableItemActivityIdentifier @"kCSSearchableItemActivityIdentifier"
#endif

@interface BNCContentDiscoveryManager ()

@property (strong, nonatomic) NSMutableDictionary *userInfo;

@end

@implementation BNCContentDiscoveryManager

#pragma mark - Launch handling

- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    // If it has our prefix, then the link identifier is just the last piece of the identifier.
    NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
    BOOL isBranchIdentifier = [activityIdentifier hasPrefix:BRANCH_SPOTLIGHT_PREFIX];
    if (isBranchIdentifier) {
        return activityIdentifier;
    }
#endif
    
    return nil;
}

- (NSString *)standardSpotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    if (userActivity.userInfo[CSSearchableItemActivityIdentifier]) {
        return userActivity.userInfo[CSSearchableItemActivityIdentifier];
    }
#endif
    
    return nil;
}

#pragma mark - Content Indexing

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:NO
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:NO
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:(NSString *)kUTTypeGeneric
                   thumbnailUrl:nil
                       keywords:nil userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:nil
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback: callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:nil
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:nil
                 expirationDate:nil
                       callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:nil
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:kUTTypeGeneric
                   thumbnailUrl:thumbnailUrl
                       keywords:nil
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title
                    description:description
              publiclyIndexable:publiclyIndexable
                           type:kUTTypeGeneric
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate*)expirationDate
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                  canonicalId:(NSString *)canonicalId
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate*)expirationDate
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:canonicalId
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}


- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
                     callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:callback
              spotlightCallback:nil];
}

- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    [self indexContentWithTitle:title
                    description:description
                    canonicalId:nil
              publiclyIndexable:publiclyIndexable
                           type:type
                   thumbnailUrl:thumbnailUrl
                       keywords:keywords
                       userInfo:userInfo
                 expirationDate:nil
                       callback:nil
              spotlightCallback:spotlightCallback];
}

//This is the final one, which figures out which callback to use, if any
// The simpler callbackWithURL overrides spotlightCallback, so don't send both
- (void)indexContentWithTitle:(NSString *)title
                  description:(NSString *)description
                  canonicalId:(NSString *)canonicalId
            publiclyIndexable:(BOOL)publiclyIndexable
                         type:(NSString *)type
                 thumbnailUrl:(NSURL *)thumbnailUrl
                     keywords:(NSSet *)keywords
                     userInfo:(NSDictionary *)userInfo
               expirationDate:(NSDate *)expirationDate
                     callback:(callbackWithUrl)callback
            spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {

    if ([BNCSystemObserver getOSVersion].integerValue < 9) {
        NSError *error = [NSError branchErrorWithCode:BNCSpotlightNotAvailableError];
        if (callback) {
            callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
    NSError *error = [NSError branchErrorWithCode:BNCSpotlightNotAvailableError];
    if (callback) {
        callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
    }
    else if (spotlightCallback) {
        spotlightCallback(nil, nil, error);
    }
    return;
#endif

    BOOL isIndexingAvailable = NO;
    Class CSSearchableIndexClass = NSClassFromString(@"CSSearchableIndex");
    SEL isIndexingAvailableSelector = NSSelectorFromString(@"isIndexingAvailable");
    isIndexingAvailable =
        ((BOOL (*)(id, SEL))[CSSearchableIndexClass methodForSelector:isIndexingAvailableSelector])
            (CSSearchableIndexClass, isIndexingAvailableSelector);
    
    if (!isIndexingAvailable) {
        NSError *error = [NSError branchErrorWithCode:BNCSpotlightNotAvailableError];
        if (callback) {
            callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }

    if (!title) {
        NSError *error = [NSError branchErrorWithCode:BNCSpotlightTitleError];
        if (callback) {
            callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
        }
        else if (spotlightCallback) {
            spotlightCallback(nil, nil, error);
        }
        return;
    }
    
    // Type cannot be null
    NSString *typeOrDefault = type ?: (NSString *)kUTTypeGeneric;
    
    // Include spotlight info in params
    NSMutableDictionary *spotlightLinkData = [[NSMutableDictionary alloc] init];
    
    if (canonicalId) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = canonicalId;
    }
    spotlightLinkData[BRANCH_LINK_DATA_KEY_TITLE] = title;
    spotlightLinkData[BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE] = @(publiclyIndexable);
    spotlightLinkData[BRANCH_LINK_DATA_KEY_TYPE] = typeOrDefault;
    
    if (userInfo) {
        [spotlightLinkData addEntriesFromDictionary:userInfo];
    }
    
    // Default the OG Title, Description, and Image Url if necessary
    if (!spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_TITLE]) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_TITLE] = title;
    }
    
    if (description) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_DESCRIPTION] = description;
        if (!spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION]) {
            spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION] = description;
        }
    }
    
    NSString *thumbnailUrlString = [thumbnailUrl absoluteString];
    BOOL thumbnailIsRemote = thumbnailUrl && ![thumbnailUrl isFileURL];
    if (thumbnailUrlString) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_THUMBNAIL_URL] = thumbnailUrlString;
        
        // Only use the thumbnail url if it is a remote url, not a file system url
        if (thumbnailIsRemote && !spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL]) {
            spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL] = thumbnailUrlString;
        }
    }
    
    if (keywords) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_KEYWORDS] = [keywords allObjects];
    }
    
    [[Branch getInstance] getSpotlightUrlWithParams:spotlightLinkData callback:^(NSDictionary *data, NSError *urlError) {
        if (urlError) {
            if (callback) {
                callback([BNCPreferenceHelper preferenceHelper].userUrl, urlError);
            }
            else if (spotlightCallback) {
                spotlightCallback(nil, nil, urlError);
            }

            return;
        }
        
        if (thumbnailIsRemote) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *thumbnailData = [NSData dataWithContentsOfURL:thumbnailUrl];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL] spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER] canonicalId:canonicalId title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:thumbnailData publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords expirationDate:expirationDate callback:callback spotlightCallback:spotlightCallback];
                });
            });
        }
        else {
            [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL] spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER] canonicalId:canonicalId title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:nil publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords expirationDate:expirationDate callback:callback spotlightCallback:spotlightCallback];
        }
    }];
}


- (void)indexContentWithUrl:(NSString *)url
        spotlightIdentifier:(NSString *)spotlightIdentifier
                canonicalId:(NSString *)canonicalId
                      title:(NSString *)title
                description:(NSString *)description
                       type:(NSString *)type
               thumbnailUrl:(NSURL *)thumbnailUrl
              thumbnailData:(NSData *)thumbnailData
          publiclyIndexable:(BOOL)publiclyIndexable
                   userInfo:(NSDictionary *)userInfo
                   keywords:(NSSet *)keywords
             expirationDate:(NSDate *)expirationDate
                   callback:(callbackWithUrl)callback
          spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    
    id CSSearchableItemAttributeSetClass = NSClassFromString(@"CSSearchableItemAttributeSet");
    id attributes = [CSSearchableItemAttributeSetClass alloc];
    SEL initAttributesSelector = NSSelectorFromString(@"initWithItemContentType:");
    attributes = ((id (*)(id, SEL, NSString *))[attributes methodForSelector:initAttributesSelector])(attributes, initAttributesSelector, type);
    
    SEL setTitleSelector = NSSelectorFromString(@"setTitle:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setTitleSelector])(attributes, setTitleSelector, title);
    SEL setContentDescriptionSelector = NSSelectorFromString(@"setContentDescription:");
    ((void (*)(id, SEL, NSString *))[attributes methodForSelector:setContentDescriptionSelector])(attributes, setContentDescriptionSelector, description);
    SEL setThumbnailURLSelector = NSSelectorFromString(@"setThumbnailURL:");
    ((void (*)(id, SEL, NSURL *))[attributes methodForSelector:setThumbnailURLSelector])(attributes, setThumbnailURLSelector, thumbnailUrl);
    SEL setThumbnailDataSelector = NSSelectorFromString(@"setThumbnailData:");
    ((void (*)(id, SEL, NSData *))[attributes methodForSelector:setThumbnailDataSelector])(attributes, setThumbnailDataSelector, thumbnailData);

    SEL setWeakRelatedUniqueIdentifierSelector = NSSelectorFromString(@"setWeakRelatedUniqueIdentifier:");
    if (canonicalId && [attributes respondsToSelector:setWeakRelatedUniqueIdentifierSelector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [attributes performSelector:setWeakRelatedUniqueIdentifierSelector withObject:canonicalId];
        #pragma clang diagnostic pop
    }

    NSDictionary *userActivityIndexingParams = @{@"title": title,
                                                 @"url": url,
                                                 @"spotlightId": spotlightIdentifier,
                                                 @"userInfo": [userInfo mutableCopy],
                                                 @"keywords": keywords,
                                                 @"publiclyIndexable": [NSNumber numberWithBool:publiclyIndexable],
                                                 @"attributeSet": attributes
                                                 };
    [self indexUsingNSUserActivity:userActivityIndexingParams];
    
    // Not handling error scenarios because they are already handled upstream by the caller
    if (url) {
        if (callback) {
            callback(url, nil);
        } else if (spotlightCallback) {
            spotlightCallback(url, spotlightIdentifier, nil);
        }
    }

#endif
}

#pragma mark Delegate Methods

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    [userActivity addUserInfoEntriesFromDictionary:self.userInfo];
}

#pragma mark Helper Methods

- (UIViewController *)getActiveViewController {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    UIViewController *rootViewController = [UIApplicationClass sharedApplication].keyWindow.rootViewController;
    return [self getActiveViewController:rootViewController];
}

- (UIViewController *)getActiveViewController:(UIViewController *)rootViewController {
    UIViewController *activeController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        activeController = ((UINavigationController *)rootViewController).topViewController;
    } else if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        activeController = ((UITabBarController *)rootViewController).selectedViewController;
    } else {
        activeController = rootViewController;
    }
    return activeController;
}

- (void)indexUsingNSUserActivity:(NSDictionary *)params {
    self.userInfo = params[@"userInfo"];
    self.userInfo[CSSearchableItemActivityIdentifier] = params[@"spotlightId"];
    
    UIViewController *activeViewController = [self getActiveViewController];
    
    if (!activeViewController) {
        // if no view controller, don't index. Current use case: iMessage extensions
        return;
    }
    NSString *uniqueIdentifier = [NSString stringWithFormat:@"io.branch.%@", [[NSBundle mainBundle] bundleIdentifier]];
    // Can't create any weak references here to the userActivity, otherwise it will not index.
    activeViewController.userActivity = [[NSUserActivity alloc] initWithActivityType:uniqueIdentifier];
    activeViewController.userActivity.delegate = self;
    activeViewController.userActivity.title = params[@"title"];
    activeViewController.userActivity.webpageURL = [NSURL URLWithString:params[@"url"]];
    activeViewController.userActivity.eligibleForSearch = YES;
    activeViewController.userActivity.eligibleForPublicIndexing = [params[@"publiclyIndexable"] boolValue];
    activeViewController.userActivity.userInfo = self.userInfo; // This alone doesn't pass userInfo through
    activeViewController.userActivity.requiredUserInfoKeys = [NSSet setWithArray:self.userInfo.allKeys]; // This along with the delegate method userActivityWillSave, however, seem to force the userInfo to come through.
    activeViewController.userActivity.keywords = params[@"keywords"];
    SEL setContentAttributeSetSelector = NSSelectorFromString(@"setContentAttributeSet:");
    ((void (*)(id, SEL, id))[activeViewController.userActivity methodForSelector:setContentAttributeSetSelector])(activeViewController.userActivity, setContentAttributeSetSelector, params[@"attributeSet"]);
    
    [activeViewController.userActivity becomeCurrent];
}

@end

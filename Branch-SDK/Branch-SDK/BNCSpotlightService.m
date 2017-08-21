//
//  BNCSpotlightService.m
//  Branch-SDK
//
//  Created by Parth Kalavadia on 8/10/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BNCSpotlightService.h"
#import <CoreSpotLight/CoreSpotLight.h>
#import "BNCSystemObserver.h"
#import "BNCError.h"
#import "Branch.h"
#import "BranchConstants.h"

static NSString* const kUTTypeGeneric = @"public.content";
static NSString* const kDomainIdentifier = @"com.branch.io";

@interface BNCSpotlightService()<NSUserActivityDelegate> {
    dispatch_queue_t    _workQueue;
}
@property (strong, nonatomic) NSMutableDictionary *userInfo;
@property (strong, readonly) dispatch_queue_t workQueue;
@end

@implementation BNCSpotlightService

- (void)indexContentUsingUserActivityWithTitle:(NSString *)title
                                   description:(NSString *)description
                                   canonicalId:(NSString *)canonicalId
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
    NSMutableDictionary *spotlightLinkData = [self getSpotlightLinkDataWithCanonicalId:canonicalId
                                                                                 title:title
                                                                           description:description
                                                                              userInfo:userInfo
                                                                         typeOrDefault:typeOrDefault
                                                                     publiclyIndexable:YES
                                                                              keywords:keywords];
    NSString *thumbnailUrlString = [thumbnailUrl absoluteString];
    BOOL thumbnailIsRemote = thumbnailUrl && ![thumbnailUrl isFileURL];
    if (thumbnailUrlString) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_THUMBNAIL_URL] = thumbnailUrlString;
        
        // Only use the thumbnail url if it is a remote url, not a file system url
        if (thumbnailIsRemote && !spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL]) {
            spotlightLinkData[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL] = thumbnailUrlString;
        }
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
                    [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL]
                          spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER]
                                  canonicalId:canonicalId
                                        title:title
                                  description:description
                                         type:typeOrDefault
                                 thumbnailUrl:thumbnailUrl
                                thumbnailData:thumbnailData
                            publiclyIndexable:YES
                                     userInfo:userInfo
                                     keywords:keywords
                               expirationDate:expirationDate
                                     callback:callback
                            spotlightCallback:spotlightCallback];
                });
            });
        }
        else {
            [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL]
                  spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER]
                          canonicalId:canonicalId
                                title:title
                          description:description
                                 type:typeOrDefault
                         thumbnailUrl:thumbnailUrl
                        thumbnailData:nil
                    publiclyIndexable:YES
                             userInfo:userInfo
                             keywords:keywords
                       expirationDate:expirationDate
                             callback:callback
                    spotlightCallback:spotlightCallback];
        }
    }];
}

- (void)indexContentUsingCSSearchableItemWithTitle:(NSString *)title
                                       CanonicalId:(NSString *)canonicalId
                                       description:(NSString *)description
                                              type:(NSString *)type
                                      thumbnailUrl:(NSURL *)thumbnailUrl
                                          userInfo:(NSDictionary *)userInfo
                                          keywords:(NSSet *)keywords
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
    
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    
    NSString *typeOrDefault = type ?: kUTTypeGeneric;
    NSMutableDictionary *spotlightLinkData = [self getSpotlightLinkDataWithCanonicalId:canonicalId
                                                                                 title:title
                                                                           description:description
                                                                              userInfo:userInfo
                                                                         typeOrDefault:typeOrDefault
                                                                     publiclyIndexable:NO
                                                                              keywords:keywords];
    NSString* dynamicUrl = [[Branch getInstance] getLongURLWithParams:spotlightLinkData];
    
    BOOL thumbnailIsRemote = thumbnailUrl && ![thumbnailUrl isFileURL];
    if (thumbnailIsRemote) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *thumbnailData = [NSData dataWithContentsOfURL:thumbnailUrl];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self indexContentWithUrl:dynamicUrl
                      spotlightIdentifier:dynamicUrl
                              canonicalId:canonicalId
                                    title:title
                              description:description
                                     type:typeOrDefault
                             thumbnailUrl:thumbnailUrl
                            thumbnailData:thumbnailData
                        publiclyIndexable:NO
                                 userInfo:userInfo
                                 keywords:keywords
                           expirationDate:nil
                                 callback:callback
                        spotlightCallback:spotlightCallback];
            });
        });
    }
    else {
        [self indexContentWithUrl:dynamicUrl
              spotlightIdentifier:dynamicUrl
                      canonicalId:canonicalId
                            title:title
                      description:description
                             type:typeOrDefault
                     thumbnailUrl:thumbnailUrl
                    thumbnailData:nil
                publiclyIndexable:NO
                         userInfo:userInfo
                         keywords:keywords
                   expirationDate:nil
                         callback:callback
                spotlightCallback:spotlightCallback];
    }
#endif
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
    
    id attributes = [self getAttributeSetFromCanonicalId:canonicalId
                                                   title:title
                                             description:description
                                                    type:type
                                            thumbnailUrl:thumbnailUrl
                                           thumbnailData:thumbnailData
                                                userInfo:userInfo
                                                keywords:keywords];
    
    NSDictionary *indexingParams = @{@"title": title,
                                     @"url": url,
                                     @"spotlightId": spotlightIdentifier,
                                     @"userInfo": [userInfo mutableCopy],
                                     @"keywords": keywords,
                                     @"publiclyIndexable": [NSNumber numberWithBool:publiclyIndexable],
                                     @"attributeSet": attributes
                                     };

    if (publiclyIndexable) {
                [self indexUsingNSUserActivity:indexingParams];
        
        // Not handling error scenarios because they are already handled upstream by the caller
        if (url) {
            if (callback) {
                callback(url, nil);
            } else if (spotlightCallback) {
                spotlightCallback(url, spotlightIdentifier, nil);
            }
        }
    }else {
        
        [self indexUsingSearchableItem:indexingParams
                         thumbnailData:thumbnailData
                              callback:callback
                     spotlightCallback:spotlightCallback];
    }
#endif
}

-(NSMutableDictionary*) getSpotlightLinkDataWithCanonicalId: (NSString*)canonicalId
                                                      title:(NSString *)title
                                                description:(NSString *)description
                                                   userInfo:(NSDictionary *)userInfo
                                              typeOrDefault:(NSString*)typeOrDefault
                                          publiclyIndexable:(BOOL)publiclyIndexable
                                                   keywords:(NSSet*)keywords {
    
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
    if (keywords) {
        spotlightLinkData[BRANCH_LINK_DATA_KEY_KEYWORDS] = [keywords allObjects];
    }
    
    return spotlightLinkData;
}

-(CSSearchableItemAttributeSet *)getAttributeSetFromCanonicalId:(NSString *)canonicalId
                                                          title:(NSString *)title
                                                    description:(NSString *)description
                                                           type:(NSString *)type
                                                   thumbnailUrl:(NSURL *)thumbnailUrl
                                                  thumbnailData:(NSData *)thumbnailData
                                                       userInfo:(NSDictionary *)userInfo
                                                       keywords:(NSSet *)keywords {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    
    if([CSSearchableItemAttributeSet class]) {
        CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:type];
        attributeSet.title = title;
        attributeSet.contentDescription = description;
        attributeSet.thumbnailURL = thumbnailUrl;
        attributeSet.thumbnailData = thumbnailData;
        
        if (canonicalId) {
            attributeSet.weakRelatedUniqueIdentifier = canonicalId;
        }
        return attributeSet;
    }
    
#endif
    return nil;
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
   // activeViewController.userActivity.eligibleForPublicIndexing = [params[@"publiclyIndexable"] boolValue];
    activeViewController.userActivity.eligibleForPublicIndexing = YES;

    activeViewController.userActivity.userInfo = self.userInfo; // This alone doesn't pass userInfo through
    activeViewController.userActivity.requiredUserInfoKeys = [NSSet setWithArray:self.userInfo.allKeys]; // This along with the delegate method userActivityWillSave, however, seem to force the userInfo to come through.
    activeViewController.userActivity.keywords = params[@"keywords"];
    SEL setContentAttributeSetSelector = NSSelectorFromString(@"setContentAttributeSet:");
    ((void (*)(id, SEL, id))[activeViewController.userActivity methodForSelector:setContentAttributeSetSelector])(activeViewController.userActivity, setContentAttributeSetSelector, params[@"attributeSet"]);
    
    [activeViewController.userActivity becomeCurrent];
}

- (void) indexUsingSearchableItem:(NSDictionary*)indexingParam
                    thumbnailData:(NSData*)thumbnailData
                         callback:(callbackWithUrl)callback
                spotlightCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    
    if([CSSearchableItemAttributeSet class]) {
       CSSearchableItemAttributeSet *attributeSet = indexingParam[@"attributeSet"];
        NSString *dynamicUrl = indexingParam[@"url"];
        CSSearchableItem *item = [[CSSearchableItem alloc]
                                  initWithUniqueIdentifier:indexingParam[@"url"]
                                  domainIdentifier:kDomainIdentifier
                                  attributeSet:attributeSet];
        
        [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[item]
                                                       completionHandler: ^(NSError * __nullable error) {
                                                           NSString *url = error == nil?dynamicUrl:nil;
                                                           if (callback) {
                                                               callback(url, error);
                                                           } else if (spotlightCallback) {
                                                               spotlightCallback(url, url, nil);
                                                           }
                                                       }];

    }
    
}

#pragma mark Helper Methods

- (UIViewController *)getActiveViewController {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    UIViewController *rootViewController = [UIApplicationClass sharedApplication].keyWindow.rootViewController;
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

#pragma mark Delegate Methods

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    [userActivity addUserInfoEntriesFromDictionary:self.userInfo];
}

#pragma remove private content from spotlight

- (void)removePrivateContentWithSpotlightIdentifier:(NSString *)spotLightIdentifier completionHandler:(completion)completion {
    [self removeMultiplePrivateContentOfSpotlightIdentifiers:@[spotLightIdentifier] completionHandler:completion];
}

- (void)removeMultiplePrivateContentOfSpotlightIdentifiers:(NSArray<NSString *> *)identifiers completionHandler:(completion)completion {
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithIdentifiers:identifiers completionHandler:^(NSError * _Nullable error) {
        completion(error);
    }];
    
}

- (void)removeAllPrivateContentByBranchWithcompletionHandler:(completion)completion {
    [[CSSearchableIndex defaultSearchableIndex] deleteSearchableItemsWithDomainIdentifiers:@[kDomainIdentifier] completionHandler:^(NSError * _Nullable error) {
        completion(error);
    }];
}

@end

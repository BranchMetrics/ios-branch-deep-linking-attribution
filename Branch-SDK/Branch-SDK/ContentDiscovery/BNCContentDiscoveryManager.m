//
//  BNCContentDiscoveryManager.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 7/17/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCContentDiscoveryManager.h"
#import "BNCSystemObserver.h"
#import "BNCError.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#ifndef kUTTypeImage
#define kUTTypeImage @"public.image"
#endif

NSString * const SPOTLIGHT_TITLE = @"+spotlight_title";
NSString * const SPOTLIGHT_DESCRIPTION = @"+spotlight_description";
NSString * const SPOTLIGHT_PUBLICLY_INDEXABLE = @"+spotlight_publicly_indexable";
NSString * const SPOTLIGHT_TYPE = @"+spotlight_type";
NSString * const SPOTLIGHT_THUMBNAIL_URL = @"+spotlight_thumbnail_url";
NSString * const SPOTLIGHT_KEYWORDS = @"+spotlight_keywords";

NSString * const SPOTLIGHT_PREFIX = @"io.branch.link.v1";

@interface BNCContentDiscoveryManager ()

@property (strong, nonatomic) NSUserActivity *currentUserActivity;

@end

@implementation BNCContentDiscoveryManager

#pragma mark - Launch handling

- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        if ([userActivity.activityType hasPrefix:SPOTLIGHT_PREFIX]) {
            return userActivity.activityType;
        }

        // CoreSpotlight version. Matched if it has our prefix, then the link identifier is just the last piece of the identifier.
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
            BOOL isBranchIdentifier = [activityIdentifier hasPrefix:SPOTLIGHT_PREFIX];

            if (isBranchIdentifier) {
                return activityIdentifier;
            }
        }
    #endif

    return nil;
}


#pragma mark - Content Indexing

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description {
    [self indexContentWithTitle:title description:description publiclyIndexable:NO type:(NSString *)kUTTypeImage thumbnailUrl:nil keywords:nil userInfo:nil callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:NO type:(NSString *)kUTTypeImage thumbnailUrl:nil keywords:nil userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:(NSString *)kUTTypeImage thumbnailUrl:nil keywords:nil userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:nil keywords:nil userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:nil userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo callback:(callbackWithUrl)callback {
    if ([BNCSystemObserver getOSVersion].integerValue < 9) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCVersionError userInfo:@{ NSLocalizedDescriptionKey: @"Cannot use CoreSpotlight indexing service prior to iOS 9" }]);
        }
        return;
    }

    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        // Type cannot be null
        NSString *typeOrDefault = type;
        if (!typeOrDefault) typeOrDefault = (NSString *)kUTTypeImage;
        
        // Include spotlight info in params
        NSMutableDictionary *spotlightSearchInfo = [NSMutableDictionary dictionary];
        if (userInfo) [spotlightSearchInfo addEntriesFromDictionary:userInfo];
        if (title) [spotlightSearchInfo setObject:title forKey:SPOTLIGHT_TITLE];
        if (description) [spotlightSearchInfo setObject:description forKey:SPOTLIGHT_DESCRIPTION];
        if (publiclyIndexable) {
            [spotlightSearchInfo setObject:@YES forKey:SPOTLIGHT_PUBLICLY_INDEXABLE];
        } else {
            [spotlightSearchInfo setObject:@NO forKey:SPOTLIGHT_PUBLICLY_INDEXABLE];
        }
        [spotlightSearchInfo setObject:typeOrDefault forKey:SPOTLIGHT_TYPE];
        if (thumbnailUrl) [spotlightSearchInfo setObject:thumbnailUrl forKey:SPOTLIGHT_THUMBNAIL_URL];
        if (keywords && [keywords isKindOfClass:[NSSet class]]) {
            NSArray *keywordsAsArray = [keywords allObjects];
            if (keywordsAsArray) [spotlightSearchInfo setObject:keywordsAsArray forKey:SPOTLIGHT_KEYWORDS];
        }
        
        [[Branch getInstance] getSpotlightUrlWithParams:spotlightSearchInfo callback:^(NSDictionary *data, NSError *urlError) {
            if (urlError) {
                if (callback) {
                    callback(nil, urlError);
                }
                return;
            }

            NSString *url = data[@"url"];
            NSString *spotlightIdentifier = data[@"spotlight_identifier"];

            CSSearchableItemAttributeSet *attributes = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:typeOrDefault];
            attributes.identifier = spotlightIdentifier;
            attributes.relatedUniqueIdentifier = spotlightIdentifier;
            attributes.title = title;
            attributes.contentDescription = description;
            attributes.thumbnailURL = thumbnailUrl;
            attributes.contentURL = [NSURL URLWithString:url]; // The content url links back to our web content

            // Index via the NSUserActivity strategy
            // Currently (iOS 9 Beta 4) we need a strong reference to this, or it isn't indexed
            self.currentUserActivity = [[NSUserActivity alloc] initWithActivityType:spotlightIdentifier];
            self.currentUserActivity.title = title;
            self.currentUserActivity.webpageURL = [NSURL URLWithString:url]; // This should allow indexed content to fall back to the web if user doesn't have the app installed. Unable to test as of iOS 9 Beta 4
            self.currentUserActivity.eligibleForSearch = YES;
            self.currentUserActivity.eligibleForPublicIndexing = publiclyIndexable;
            self.currentUserActivity.contentAttributeSet = attributes;
            self.currentUserActivity.userInfo = userInfo; // As of iOS 9 Beta 4, this gets lost and never makes it through to application:continueActivity:restorationHandler:
            self.currentUserActivity.requiredUserInfoKeys = [NSSet setWithArray:userInfo.allKeys]; // This, however, seems to force the userInfo to come through.
            self.currentUserActivity.keywords = keywords;
            [self.currentUserActivity becomeCurrent];

            // Index via the CoreSpotlight strategy
            CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:spotlightIdentifier domainIdentifier:SPOTLIGHT_PREFIX attributeSet:attributes];
            [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ] completionHandler:^(NSError *indexError) {
                if (callback) {
                    if (indexError) {
                        callback(nil, indexError);
                    }
                    else {
                        callback(url, nil);
                    }
                }
            }];
        }];
    #endif
}

@end

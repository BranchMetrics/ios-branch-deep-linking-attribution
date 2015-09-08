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
#import "BranchConstants.h"

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#ifndef kUTTypeGeneric
#define kUTTypeGeneric @"public.content"
#endif

@interface BNCContentDiscoveryManager ()

@property (strong, nonatomic) NSUserActivity *currentUserActivity;

@end

@implementation BNCContentDiscoveryManager

#pragma mark - Launch handling

- (NSString *)spotlightIdentifierFromActivity:(NSUserActivity *)userActivity {
    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        if ([userActivity.activityType hasPrefix:BRANCH_SPOTLIGHT_PREFIX]) {
            return userActivity.activityType;
        }
        
        // CoreSpotlight version. Matched if it has our prefix, then the link identifier is just the last piece of the identifier.
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
            BOOL isBranchIdentifier = [activityIdentifier hasPrefix:BRANCH_SPOTLIGHT_PREFIX];
            
            if (isBranchIdentifier) {
                return activityIdentifier;
            }
        }
    #endif
    
    return nil;
}


#pragma mark - Content Indexing

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description {
    [self indexContentWithTitle:title description:description publiclyIndexable:NO type:(NSString *)kUTTypeGeneric thumbnailUrl:nil keywords:nil userInfo:nil callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:NO type:(NSString *)kUTTypeGeneric thumbnailUrl:nil keywords:nil userInfo:nil callback:callback];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable callback:(callbackWithUrl)callback {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:(NSString *)kUTTypeGeneric thumbnailUrl:nil keywords:nil userInfo:nil callback:callback];
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

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:nil callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:type thumbnailUrl:thumbnailUrl keywords:keywords userInfo:userInfo callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable thumbnailUrl:(NSURL *)thumbnailUrl userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:kUTTypeGeneric thumbnailUrl:thumbnailUrl keywords:nil userInfo:userInfo callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo {
    [self indexContentWithTitle:title description:description publiclyIndexable:publiclyIndexable type:kUTTypeGeneric thumbnailUrl:thumbnailUrl keywords:keywords userInfo:userInfo callback:NULL];
}

- (void)indexContentWithTitle:(NSString *)title description:(NSString *)description publiclyIndexable:(BOOL)publiclyIndexable type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl keywords:(NSSet *)keywords userInfo:(NSDictionary *)userInfo callback:(callbackWithUrl)callback {
    if ([BNCSystemObserver getOSVersion].integerValue < 9) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCVersionError userInfo:@{ NSLocalizedDescriptionKey: @"Cannot use CoreSpotlight indexing service prior to iOS 9" }]);
        }
        return;
    }

    if (!title) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCBadRequestError userInfo:@{ NSLocalizedDescriptionKey: @"Spotlight Indexing requires a title" }]);
        }
        return;
    }
    
    // Type cannot be null
    NSString *typeOrDefault = type ?: (NSString *)kUTTypeGeneric;
    
    // Include spotlight info in params
    NSMutableDictionary *spotlightLinkData = [[NSMutableDictionary alloc] init];
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
                callback(nil, urlError);
            }
            return;
        }
        
        if (thumbnailIsRemote) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *thumbnailData = [NSData dataWithContentsOfURL:thumbnailUrl];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL] spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER] title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:thumbnailData publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords callback:callback];
                });
            });
        }
        else {
            [self indexContentWithUrl:data[BRANCH_RESPONSE_KEY_URL] spotlightIdentifier:data[BRANCH_RESPONSE_KEY_SPOTLIGHT_IDENTIFIER] title:title description:description type:typeOrDefault thumbnailUrl:thumbnailUrl thumbnailData:nil publiclyIndexable:publiclyIndexable userInfo:userInfo keywords:keywords callback:callback];
        }
    }];
}

- (void)indexContentWithUrl:(NSString *)url spotlightIdentifier:(NSString *)spotlightIdentifier title:(NSString *)title description:(NSString *)description type:(NSString *)type thumbnailUrl:(NSURL *)thumbnailUrl thumbnailData:(NSData *)thumbnailData publiclyIndexable:(BOOL)publiclyIndexable userInfo:(NSDictionary *)userInfo keywords:(NSSet *)keywords callback:(callbackWithUrl)callback {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    CSSearchableItemAttributeSet *attributes = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:type];
    attributes.identifier = spotlightIdentifier;
    attributes.relatedUniqueIdentifier = spotlightIdentifier;
    attributes.title = title;
    attributes.contentDescription = description;
    attributes.thumbnailURL = thumbnailUrl;
    attributes.thumbnailData = thumbnailData;
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
    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:spotlightIdentifier domainIdentifier:BRANCH_SPOTLIGHT_PREFIX attributeSet:attributes];
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
#endif
}

@end

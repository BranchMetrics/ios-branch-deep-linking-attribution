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

@interface BNCContentDiscoveryManager ()

@property (strong, nonatomic) NSUserActivity *currentUserActivity;

@end

@implementation BNCContentDiscoveryManager

#pragma mark - Launch handling

- (NSString *)spotlightLinkIdentifierFromActivity:(NSUserActivity *)userActivity {
    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        NSString *spotlightIdentifier = [self spotlightIdentifierForApp];
        
        // NSUserActivity method. We should just be able to pull this from the contentAttributeSet, but this property is being cleared (iOS 9 Beta 3)
        // Instead we just pull the URL's last path component for the time being.
        if ([userActivity.activityType isEqualToString:spotlightIdentifier]) {
            return [userActivity.webpageURL lastPathComponent];
        }

        // CoreSpotlight version. Matched if it has our prefix, then the link identifier is just the last piece of the identifier.
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            NSString *activityIdentifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
            BOOL isBranchIdentifier = [activityIdentifier hasPrefix:spotlightIdentifier];

            if (isBranchIdentifier) {
                return [activityIdentifier substringFromIndex:spotlightIdentifier.length + 1];
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
        [[Branch getInstance] getShortURLWithParams:userInfo andChannel:@"spotlight" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url, NSError *error) {
            NSString *spotlightIdentifier = [self spotlightIdentifierForApp];
            NSString *identifier = [NSString stringWithFormat:@"%@.%@", spotlightIdentifier, [url lastPathComponent]];

            CSSearchableItemAttributeSet *attributes = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:type];
            attributes.identifier = identifier;
            attributes.relatedUniqueIdentifier = identifier;
            attributes.title = title;
            attributes.contentDescription = description;
            attributes.thumbnailURL = thumbnailUrl;
            attributes.contentURL = [NSURL URLWithString:url]; // The content url links back to our web content
            
            // Index via the NSUserActivity strategy
            // Currently (iOS 9 Beta 3) we need a strong reference to this, or it isn't indexed
            self.currentUserActivity = [[NSUserActivity alloc] initWithActivityType:spotlightIdentifier];
            self.currentUserActivity.title = title;
            self.currentUserActivity.webpageURL = [NSURL URLWithString:url]; // This should allow indexed content to fall back to the web if user doesn't have the app installed. Doesn't work as of iOS 9 Beta 3.
            self.currentUserActivity.eligibleForSearch = YES;
            self.currentUserActivity.eligibleForPublicIndexing = publiclyIndexable;
            self.currentUserActivity.contentAttributeSet = attributes;
            self.currentUserActivity.userInfo = userInfo; // As of iOS 9 Beta 3, this gets lost and never makes it through to application:continueActivity:restorationHandler:
            self.currentUserActivity.requiredUserInfoKeys = [NSSet setWithArray:userInfo.allKeys]; // This, however, seems to force the userInfo to come through.
            self.currentUserActivity.keywords = keywords;
            [self.currentUserActivity becomeCurrent];
            
            // Index via the CoreSpotlight strategy
            CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:identifier domainIdentifier:spotlightIdentifier attributeSet:attributes];
            [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ] completionHandler:^(NSError *indexError) {
                if (callback) {
                    if (!error) {
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

- (NSString *)spotlightIdentifierForApp {
    return [NSString stringWithFormat:@"%@.branch.spotlightlink", [BNCSystemObserver getBundleID]];
}

@end

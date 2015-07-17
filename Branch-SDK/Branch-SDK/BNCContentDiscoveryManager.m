//
//  BNCContentDiscoveryManager.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 7/17/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BNCContentDiscoveryManager.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "BNCSystemObserver.h"

@interface BNCContentDiscoveryManager ()

@property (strong, nonatomic) NSUserActivity *currentUserActivity;

@end

@implementation BNCContentDiscoveryManager

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
    [[Branch getInstance] getShortURLWithParams:userInfo andChannel:@"spotlight" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url, NSError *error) {
        NSString *activityType = [NSString stringWithFormat:@"%@.branch.spotlightlink", [BNCSystemObserver getBundleID]];
        NSString *identifier = [NSString stringWithFormat:@"%@.branch.spotlightlink.%@", [BNCSystemObserver getBundleID], [url lastPathComponent]];

        CSSearchableItemAttributeSet *attributes = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:type];
        attributes.identifier = identifier;
        attributes.relatedUniqueIdentifier = identifier;
        attributes.title = title;
        attributes.contentDescription = description;
        attributes.thumbnailURL = thumbnailUrl;
        attributes.contentURL = [NSURL URLWithString:url]; // The content url links back to our web content
        
        // Index via the NSUserActivity strategy
        // Currently (iOS 9 Beta 3) we need a strong reference to this, or it isn't indexed
        self.currentUserActivity = [[NSUserActivity alloc] initWithActivityType:activityType];
        self.currentUserActivity.title = title;
        self.currentUserActivity.webpageURL = [NSURL URLWithString:url]; // This should allow indexed content to fall back to the web if user doesn't have the app installed. Doesn't work as of iOS 9 Beta 3.
        self.currentUserActivity.eligibleForSearch = YES;
        self.currentUserActivity.eligibleForPublicIndexing = publiclyIndexable;
        self.currentUserActivity.contentAttributeSet = attributes;
        self.currentUserActivity.userInfo = userInfo; // As of iOS 9 Beta 3, this gets lost and never makes it through to application:continueActivity:restorationHandler:
        self.currentUserActivity.keywords = keywords;
        [self.currentUserActivity becomeCurrent];
        
        // Index via the CoreSpotlight strategy
        CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:identifier domainIdentifier:activityType attributeSet:attributes];
        [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:@[ item ] completionHandler:^(NSError *indexError) {
            if (!error) {
                callback(nil, indexError);
            }
            else {
                callback(url, nil);
            }
        }];
    }];
}

@end

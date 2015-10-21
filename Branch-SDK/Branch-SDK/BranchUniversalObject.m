//
//  BranchUniversalObject.m
//  Branch-TestBed
//
//  Created by Derrick Staten on 10/16/15.
//  Copyright © 2015 Branch Metrics. All rights reserved.
//

#import "BranchUniversalObject.h"
#import "BNCError.h"
#import "BranchConstants.h"

@implementation BranchUniversalObject

- (instancetype)initWithCanonicalIdentifier:(NSString *)canonicalIdentifier {
    if (self = [super init]) {
        self.canonicalIdentifier = canonicalIdentifier;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        self.title = title;
    }
    return self;
}

- (void)registerView {
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not register view.");
        return;
    }

    [[Branch getInstance] registerViewWithParams:[self getParamsForServerRequest]
                                     andCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback {
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain
                                              code:BNCInitError
                                          userInfo:@{ NSLocalizedDescriptionKey: @"A canonicalIdentifier or title are required to uniquely identify content, so could not register view." }]);
        }
        else {
            NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not register view.");
        }
        return;
    }

    [[Branch getInstance] registerViewWithParams:[self getParamsForServerRequest] andCallback:callback];
}

- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
        return nil;
    }

    return [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                               andTags:linkProperties.tags
                                              andAlias:linkProperties.alias
                                            andChannel:linkProperties.channel
                                            andFeature:linkProperties.feature
                                              andStage:linkProperties.stage
                                      andMatchDuration:linkProperties.matchDuration];
}

- (void)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties andCallback:(callbackWithUrl)callback {
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL." }]);
        }
        else {
            NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
        }
        return;
    }

    [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                        andTags:linkProperties.tags
                                       andAlias:linkProperties.alias
                               andMatchDuration:linkProperties.matchDuration
                                     andChannel:linkProperties.channel
                                     andFeature:linkProperties.feature
                                       andStage:linkProperties.stage
                                    andCallback:callback];
}

- (UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content. In order to not break the end user experience with sharing, Branch SDK will proceed to create a URL, but content analytics may not properly include this URL.");
    }

    NSMutableDictionary *params = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    if (linkProperties.matchDuration) {
        [params setObject:@(linkProperties.matchDuration) forKey:BRANCH_REQUEST_KEY_URL_DURATION];
    }
    return [Branch getBranchActivityItemWithParams:params
                                           feature:linkProperties.feature
                                             stage:linkProperties.stage
                                              tags:linkProperties.tags
                                             alias:linkProperties.alias];
}

- (void)showShareSheetWithShareText:(NSString *)shareText {
    [self showShareSheetWithLinkProperties:nil andShareText:shareText fromViewController:nil];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController {
    UIActivityItemProvider *itemProvider = [self getBranchActivityItemWithLinkProperties:linkProperties];
    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareText, itemProvider] applicationActivities:nil];
    if (viewController && [viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [viewController presentViewController:shareViewController animated:YES completion:nil];
    }
    else {
        [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:shareViewController animated:YES completion:nil];
    }
}

- (void)listOnSpotlight {
    [self listOnSpotlightWithCallback:nil];
}

- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback {
    NSNumber *publiclyIndexable;
    if (self.contentIndexMode == ContentIndexModePrivate) {
        publiclyIndexable = @0;
    }
    else {
        publiclyIndexable = @1;
    }
    [[Branch getInstance] createDiscoverableContentWithTitle:self.title
                                                 description:self.contentDescription
                                                thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                                        type:self.type
                                           publiclyIndexable:publiclyIndexable
                                                    keywords:[NSSet setWithArray:self.keywords]
                                                    callback:callback];
}


#pragma mark - Private methods

- (NSDictionary *)getParamsForServerRequest {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    [self safeSetValue:self.canonicalIdentifier forKey:BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER onDict:temp];
    [self safeSetValue:self.title forKey:BRANCH_LINK_DATA_KEY_OG_TITLE onDict:temp];
    [self safeSetValue:self.contentDescription forKey:BRANCH_LINK_DATA_KEY_OG_DESCRIPTION onDict:temp];
    [self safeSetValue:self.imageUrl forKey:BRANCH_LINK_DATA_KEY_OG_IMAGE_URL onDict:temp];
    if (self.contentIndexMode == ContentIndexModePrivate) {
        [self safeSetValue:@(0) forKey:BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE onDict:temp];
    }
    else {
        [self safeSetValue:@(1) forKey:BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE onDict:temp];
    }
    [self safeSetValue:self.keywords forKey:BRANCH_LINK_DATA_KEY_KEYWORDS onDict:temp];
    [self safeSetValue:@(self.expirationInMilliSec) forKey:BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE onDict:temp];
    [self safeSetValue:self.type forKey:BRANCH_LINK_DATA_KEY_CONTENT_TYPE onDict:temp];

    [temp addEntriesFromDictionary:[self.metatdata copy]];
    return [temp copy];
}

- (NSDictionary *)getParamsForServerRequestWithAddedLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = [[self getParamsForServerRequest] mutableCopy];
    [temp addEntriesFromDictionary:[linkProperties.controlParams copy]]; // TODO: Add warnings if controlParams contains non-control params
    return [temp copy];
}

- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end

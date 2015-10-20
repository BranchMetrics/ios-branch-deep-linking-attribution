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
    Branch *branch = [Branch getCurrentInstanceIfAny];
    if (!branch) {
        NSLog(@"[Branch Warning] getInstance has not yet been invoked, so could not register view.");
        return;
    }
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not register view.");
        return;
    }
    
    [branch registerViewWithParams:[self getParamsForServerRequest] andCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback {
    Branch *branch = [Branch getCurrentInstanceIfAny];
    if (!branch) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"getInstance has not yet been invoked, so could not register view." }]);
        }
        return;
    }
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"A canonicalIdentifier or title are required to uniquely identify content, so could not register view." }]);
        }
        else {
            NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not register view.");
        }
        return;
    }
    
    [branch registerViewWithParams:[self getParamsForServerRequest] andCallback:callback];
}

- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties {
    Branch *branch = [Branch getCurrentInstanceIfAny];
    if (!branch) {
        NSLog(@"[Branch Warning] getInstance has not yet been invoked, so could not generate a URL.");
        return nil;
    }
    if (!self.canonicalIdentifier && !self.title) {
        NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
        return nil;
    }
    
    return [branch getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] andTags:linkProperties.tags andAlias:linkProperties.alias andChannel:linkProperties.channel andFeature:linkProperties.feature andStage:linkProperties.stage andMatchDuration:linkProperties.matchDuration];
}

- (void)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties andCallback:(callbackWithUrl)callback {
    Branch *branch = [Branch getCurrentInstanceIfAny];
    if (!branch) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"getInstance has not yet been invoked, so could not generate a URL." }]);
        }
        return;
    }
    if (!self.canonicalIdentifier && !self.title) {
        if (callback) {
            callback(nil, [NSError errorWithDomain:BNCErrorDomain code:BNCInitError userInfo:@{ NSLocalizedDescriptionKey: @"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL." }]);
        }
        else {
            NSLog(@"[Branch Warning] a canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
        }
        return;
    }

    [branch getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] andTags:linkProperties.tags andAlias:linkProperties.alias andMatchDuration:linkProperties.matchDuration andChannel:linkProperties.channel andFeature:linkProperties.feature andStage:linkProperties.stage andCallback:callback];
}

- (UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *params = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    if (linkProperties.matchDuration) {
        [params setObject:@(linkProperties.matchDuration) forKey:BRANCH_REQUEST_KEY_URL_DURATION];
    }
    return [Branch getBranchActivityItemWithParams:params feature:linkProperties.feature stage:linkProperties.stage tags:linkProperties.tags alias:linkProperties.alias];
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

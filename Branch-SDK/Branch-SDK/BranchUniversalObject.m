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
#import "BNCFabricAnswers.h"
#import "BNCDeviceInfo.h"
#import "BNCLog.h"
#import "BNCLocalization.h"

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

- (NSDictionary *)metadata {
    if (!_metadata) {
        _metadata = [[NSDictionary alloc] init];
    }
    return _metadata;
}

- (void)addMetadataKey:(NSString *)key value:(NSString *)value {
    if (!key || !value) {
        return;
    }
    NSMutableDictionary *temp = [self.metadata mutableCopy];
    temp[key] = value;
    _metadata = [temp copy];
}

- (void)registerView {
    [self registerViewWithCallback:nil];
}

- (void)registerViewWithCallback:(callbackWithParams)callback {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = BNCLocalizedString(@"Could not register view.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        if (callback) callback([[NSDictionary alloc] init], error);
        return;
    }
    if (self.automaticallyListOnSpotlight) {
        [self listOnSpotlight];
    }
    [[Branch getInstance] registerViewWithParams:[self getParamsForServerRequest] andCallback:callback];
}

- (void)userCompletedAction:(NSString *)action
{
    [self userCompletedAction:action withState:nil];
}

- (void)userCompletedAction:(NSString *)action withState:(NSDictionary *)state {
    NSMutableDictionary *actionPayload = [[NSMutableDictionary alloc] init];
    NSDictionary *linkParams = [self getParamsForServerRequest];
    if (self.canonicalIdentifier && linkParams) {
        actionPayload[BNCCanonicalIdList] = @[self.canonicalIdentifier];
        actionPayload[self.canonicalIdentifier] = linkParams;

        if (state) {
            // Add in user params
            [actionPayload addEntriesFromDictionary:state];
        }

        [[Branch getInstance] userCompletedAction:action withState:actionPayload];
        if (self.automaticallyListOnSpotlight && [action isEqualToString:BNCRegisterViewEvent])
            [self listOnSpotlight];
    }
}

+ (BranchUniversalObject *)getBranchUniversalObjectFromDictionary:(NSDictionary *)dictionary {
    BranchUniversalObject *universalObject = [[BranchUniversalObject alloc] init];
    
    // Build BranchUniversalObject base properties
    universalObject.metadata = [dictionary copy];
    if (dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER]) {
        universalObject.canonicalIdentifier = dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_URL]) {
        universalObject.canonicalUrl = dictionary[BRANCH_LINK_DATA_KEY_CANONICAL_URL];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_TITLE]) {
        universalObject.title = dictionary[BRANCH_LINK_DATA_KEY_OG_TITLE];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION]) {
        universalObject.contentDescription = dictionary[BRANCH_LINK_DATA_KEY_OG_DESCRIPTION];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL]) {
        universalObject.imageUrl = dictionary[BRANCH_LINK_DATA_KEY_OG_IMAGE_URL];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE]) {
        if (dictionary[BRANCH_LINK_DATA_KEY_PUBLICLY_INDEXABLE] == 0) {
            universalObject.contentIndexMode = ContentIndexModePrivate;
        }
        else {
            universalObject.contentIndexMode = ContentIndexModePublic;
        }
    }
    
    if (dictionary[BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE] && [dictionary[BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE] isKindOfClass:[NSNumber class]]) {
        NSNumber *millisecondsSince1970 = dictionary[BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE];
        universalObject.expirationDate = [NSDate dateWithTimeIntervalSince1970:millisecondsSince1970.integerValue/1000];
    }
    if (dictionary[BRANCH_LINK_DATA_KEY_KEYWORDS]) {
        universalObject.keywords = dictionary[BRANCH_LINK_DATA_KEY_KEYWORDS];
    }
    if (dictionary[BNCPurchaseAmount]) {
        universalObject.price = [dictionary[BNCPurchaseAmount] floatValue];
    }
    if (dictionary[BNCPurchaseCurrency]) {
        universalObject.currency = dictionary[BNCPurchaseCurrency];
    }
    
    if (dictionary[BRANCH_LINK_DATA_KEY_CONTENT_TYPE]) {
        universalObject.type = dictionary[BRANCH_LINK_DATA_KEY_CONTENT_TYPE];
    }
    return universalObject;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"BranchUniversalObject \n canonicalIdentifier: %@ \n title: %@ \n contentDescription: %@ \n imageUrl: %@ \n metadata: %@ \n type: %@ \n contentIndexMode: %ld \n keywords: %@ \n expirationDate: %@", self.canonicalIdentifier, self.title, self.contentDescription, self.imageUrl, self.metadata, self.type, (long)self.contentIndexMode, self.keywords, self.expirationDate];
}

#pragma mark - Link Creation Methods

- (NSString *)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        BNCLogWarning(@"A canonicalIdentifier or title are required to uniquely identify content, so could not generate a URL.");
        return nil;
    }
    
    return [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                               andTags:linkProperties.tags
                                              andAlias:linkProperties.alias
                                            andChannel:linkProperties.channel
                                            andFeature:linkProperties.feature
                                              andStage:linkProperties.stage
                                           andCampaign:linkProperties.campaign
                                      andMatchDuration:linkProperties.matchDuration];
}

- (void)getShortUrlWithLinkProperties:(BranchLinkProperties *)linkProperties andCallback:(callbackWithUrl)callback {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = BNCLocalizedString(@"Could not generate a URL.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        if (callback) callback([BNCPreferenceHelper preferenceHelper].userUrl, error);
        return;
    }
    
    [[Branch getInstance] getShortUrlWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                        andTags:linkProperties.tags
                                       andAlias:linkProperties.alias
                               andMatchDuration:linkProperties.matchDuration
                                     andChannel:linkProperties.channel
                                     andFeature:linkProperties.feature
                                       andStage:linkProperties.stage
                                    andCampaign:linkProperties.campaign
                                    andCallback:callback];
}

- (NSString *)getShortUrlWithLinkPropertiesAndIgnoreFirstClick:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.title) {
        NSString *message = BNCLocalizedString(@"Could not generate a URL.");
        NSError *error = [NSError branchErrorWithCode:BNCContentIdentifierError localizedMessage:message];
        BNCLogWarning(@"%@", error);
        return nil;
    }
    // keep this operation outside of sync operation below.
    NSString *UAString = [BNCDeviceInfo userAgentString];

    return [[Branch getInstance] getShortURLWithParams:[self getParamsForServerRequestWithAddedLinkProperties:linkProperties]
                                        andTags:linkProperties.tags
                                     andChannel:linkProperties.channel
                                     andFeature:linkProperties.feature
                                       andStage:linkProperties.stage
                                           andCampaign:linkProperties.campaign
                                       andAlias:linkProperties.alias
                                 ignoreUAString:UAString
                              forceLinkCreation:YES];
}

#pragma mark - Share Sheets

- (UIActivityItemProvider *)getBranchActivityItemWithLinkProperties:(BranchLinkProperties *)linkProperties {
    if (!self.canonicalIdentifier && !self.canonicalUrl && !self.title) {
        BNCLogWarning(@"A canonicalIdentifier, canonicalURL, or title are required to uniquely identify content. "
            "In order to not break the end user experience with sharing, Branch SDK will proceed to create a URL, "
            "but content analytics may not properly include this URL.");
    }
    
    NSMutableDictionary *params = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    if (linkProperties.matchDuration) {
        [params setObject:@(linkProperties.matchDuration) forKey:BRANCH_REQUEST_KEY_URL_DURATION];
    }

    return [Branch getBranchActivityItemWithParams:params
                                           feature:linkProperties.feature
                                             stage:linkProperties.stage
                                          campaign:linkProperties.campaign
                                              tags:linkProperties.tags
                                             alias:linkProperties.alias];
}

- (void)showShareSheetWithShareText:(NSString *)shareText completion:(shareCompletion)completion {
    [self showShareSheetWithLinkProperties:nil andShareText:shareText fromViewController:nil completion:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController completion:(shareCompletion)completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:viewController anchor:nil completion:completion orCompletionWithError:nil];
}
- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController completionWithError:(shareCompletionWithError)completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:viewController anchor:nil completion:nil orCompletionWithError:completion];
}
- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController anchor:(nullable UIBarButtonItem *)anchor completion:(nullable shareCompletion)completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:viewController anchor:anchor completion:completion orCompletionWithError:nil];
}

- (void)showShareSheetWithLinkProperties:(nullable BranchLinkProperties *)linkProperties andShareText:(nullable NSString *)shareText fromViewController:(nullable UIViewController *)viewController anchor:(nullable UIBarButtonItem *)anchor completionWithError:(nullable shareCompletionWithError)completion {
    [self showShareSheetWithLinkProperties:linkProperties andShareText:shareText fromViewController:viewController anchor:anchor completion:nil orCompletionWithError:completion];
}

- (void)showShareSheetWithLinkProperties:(BranchLinkProperties *)linkProperties andShareText:(NSString *)shareText fromViewController:(UIViewController *)viewController anchor:(UIBarButtonItem *)anchor completion:(shareCompletion)completion orCompletionWithError:(shareCompletionWithError)completionError {
    // Log share initiated event
    [self userCompletedAction:BNCShareInitiatedEvent];
    UIActivityItemProvider *itemProvider = [self getBranchActivityItemWithLinkProperties:linkProperties];
    NSMutableArray *items = [NSMutableArray arrayWithObject:itemProvider];
    if (shareText) {
        [items insertObject:shareText atIndex:0];
    }
    UIActivityViewController *shareViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    if ([shareViewController respondsToSelector:@selector(completionWithItemsHandler)]) {
        shareViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            // Log share completed event
            [self userCompletedAction:BNCShareCompletedEvent];
            if (completion || completionError) {
                if (completion) { completion(activityType, completed); }
                else if (completionError) { completionError(activityType, completed, activityError); }
                [BNCFabricAnswers sendEventWithName:@"Branch Share" andAttributes:[self getDictionaryWithCompleteLinkProperties:linkProperties]];
            }
        };
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Deprecated in iOS 8.  Safe to hide deprecation warnings as the new completion handler is checked for above
        shareViewController.completionHandler = completion;
#pragma clang diagnostic pop
    }
    
    UIViewController *presentingViewController;
    if (viewController && [viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        presentingViewController = viewController;
    }
    else {
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        if ([[[[UIApplicationClass sharedApplication].delegate window] rootViewController] respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            presentingViewController = [[[UIApplicationClass sharedApplication].delegate window] rootViewController];
        }
    }
    
    if (linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT]) {
        @try {
            [shareViewController setValue:linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT] forKey:@"subject"];
        }
        @catch (NSException *exception) {
            BNCLogWarning(@"Unable to setValue 'emailSubject' forKey 'subject' on UIActivityViewController.");
        }
    }
    
    if (presentingViewController) {
        // Required for iPad/Universal apps on iOS 8+
        if ([presentingViewController respondsToSelector:@selector(popoverPresentationController)]) {
            shareViewController.popoverPresentationController.sourceView = presentingViewController.view;
            if (anchor) {
                shareViewController.popoverPresentationController.barButtonItem = anchor;
            }
        }
        [presentingViewController presentViewController:shareViewController animated:YES completion:nil];
    }
    else {
        BNCLogWarning(@"Unable to show the share sheet since no view controller is present.");
    }
}

#pragma mark - Spotlight

- (void)listOnSpotlight {
    [self listOnSpotlightWithCallback:nil];
}

- (void)listOnSpotlightWithCallback:(callbackWithUrl)callback {
    BOOL publiclyIndexable;
    if (self.contentIndexMode == ContentIndexModePrivate) {
        publiclyIndexable = NO;
    }
    else {
        publiclyIndexable = YES;
    }
    
    NSMutableDictionary *metadataAndProperties = [self.metadata mutableCopy];
    if (self.canonicalIdentifier) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = self.canonicalIdentifier;
    }
    if (self.canonicalUrl) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_URL] = self.canonicalUrl;
    }

    [[Branch getInstance] createDiscoverableContentWithTitle:self.title
                                                 description:self.contentDescription
                                                thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                                 canonicalId:self.canonicalIdentifier
                                                  linkParams:metadataAndProperties.copy
                                                        type:self.type
                                           publiclyIndexable:publiclyIndexable
                                                    keywords:[NSSet setWithArray:self.keywords]
                                              expirationDate:self.expirationDate
                                                    callback:callback];
}


//This one uses a callback that returns the SpotlightIdentifier
- (void)listOnSpotlightWithIdentifierCallback:(callbackWithUrlAndSpotlightIdentifier)spotlightCallback {
    BOOL publiclyIndexable;
    if (self.contentIndexMode == ContentIndexModePrivate) {
        publiclyIndexable = NO;
    }
    else {
        publiclyIndexable = YES;
    }
    
    NSMutableDictionary *metadataAndProperties = [self.metadata mutableCopy];
    if (self.canonicalIdentifier) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER] = self.canonicalIdentifier;
    }
    if (self.canonicalUrl) {
        metadataAndProperties[BRANCH_LINK_DATA_KEY_CANONICAL_URL] = self.canonicalUrl;
    }
    
    [[Branch getInstance] createDiscoverableContentWithTitle:self.title
                                                 description:self.contentDescription
                                                thumbnailUrl:[NSURL URLWithString:self.imageUrl]
                                                 canonicalId:self.canonicalIdentifier
                                                  linkParams:metadataAndProperties.copy
                                                        type:self.type
                                           publiclyIndexable:publiclyIndexable
                                                    keywords:[NSSet setWithArray:self.keywords]
                                              expirationDate:self.expirationDate
                                           spotlightCallback:spotlightCallback];
}

#pragma mark - Private methods

- (NSDictionary *)getParamsForServerRequest {
    NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
    [self safeSetValue:self.canonicalIdentifier forKey:BRANCH_LINK_DATA_KEY_CANONICAL_IDENTIFIER onDict:temp];
    [self safeSetValue:self.canonicalUrl forKey:BRANCH_LINK_DATA_KEY_CANONICAL_URL onDict:temp];
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
    [self safeSetValue:@(1000 * [self.expirationDate timeIntervalSince1970]) forKey:BRANCH_LINK_DATA_KEY_CONTENT_EXPIRATION_DATE onDict:temp];
    [self safeSetValue:self.type forKey:BRANCH_LINK_DATA_KEY_CONTENT_TYPE onDict:temp];
    [self safeSetValue:self.currency forKey:BNCPurchaseCurrency onDict:temp];
    if (self.price) {
        // have to add if statement because safeSetValue only accepts objects so even if self.price is not set
        // a valid NSNumber object will be created and the request will have amount:0 in all cases.
        [self safeSetValue:[NSNumber numberWithFloat:self.price] forKey:BNCPurchaseAmount onDict:temp];
    }
    
    [temp addEntriesFromDictionary:[self.metadata copy]];
    return [temp copy];
}

- (NSDictionary *)getParamsForServerRequestWithAddedLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = [[self getParamsForServerRequest] mutableCopy];
    [temp addEntriesFromDictionary:[linkProperties.controlParams copy]]; // TODO: Add warnings if controlParams contains non-control params
    return [temp copy];
}

- (NSDictionary *)getDictionaryWithCompleteLinkProperties:(BranchLinkProperties *)linkProperties {
    NSMutableDictionary *temp = [[self getParamsForServerRequestWithAddedLinkProperties:linkProperties] mutableCopy];
    
    [self safeSetValue:linkProperties.tags forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_TAGS] onDict:temp];
    [self safeSetValue:linkProperties.feature forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_FEATURE] onDict:temp];
    [self safeSetValue:linkProperties.alias forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_ALIAS] onDict:temp];
    [self safeSetValue:linkProperties.channel forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_CHANNEL] onDict:temp];
    [self safeSetValue:linkProperties.stage forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_STAGE] onDict:temp];
    [self safeSetValue:linkProperties.campaign forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_CAMPAIGN] onDict:temp];
    [self safeSetValue:@(linkProperties.matchDuration) forKey:[NSString stringWithFormat:@"~%@", BRANCH_REQUEST_KEY_URL_DURATION] onDict:temp];

    return [temp copy];
}
- (void)safeSetValue:(NSObject *)value forKey:(NSString *)key onDict:(NSMutableDictionary *)dict {
    if (value) {
        dict[key] = value;
    }
}

@end

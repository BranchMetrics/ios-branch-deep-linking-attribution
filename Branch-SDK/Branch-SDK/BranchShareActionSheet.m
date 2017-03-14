//
//  BranchShareActionSheet.m
//  Branch-TestBed
//
//  Created by Edward Smith on 3/13/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BranchShareActionSheet.h"
#import "BranchConstants.h"
#import "BNCFabricAnswers.h"
#import "BranchActivityItemProvider.h"
#import "BNCDeviceInfo.h"
@class BranchShareActivityItem;

typedef NS_ENUM(NSInteger, BranchShareActivityItemType) {
    BranchShareActivityItemTypeURL = 0,
    BranchShareActivityItemTypeShareText,
    BranchShareActivityItemTypeOther,
};

#pragma mark BranchShareActionSheet

@interface BranchShareActionSheet ()

- (id) shareObjectForItem:(BranchShareActivityItem*)activityItem
             activityType:(UIActivityType)activityType;

@property (nonatomic, strong) NSURL *shareURL;
@end

#pragma mark - BranchShareActivityItem

@interface BranchShareActivityItem : UIActivityItemProvider
@property (nonatomic, assign) BranchShareActivityItemType itemType;
@property (nonatomic, weak)   BranchShareActionSheet *parentSheet;
@end

@implementation BranchShareActivityItem

- (id) initWithPlaceholderItem:(id)placeholderItem {
    self = [super initWithPlaceholderItem:placeholderItem];
    if (!self) return self;

    if ([placeholderItem isKindOfClass:NSURL.class]) {
        self.itemType = BranchShareActivityItemTypeURL;
    } else if ([placeholderItem isKindOfClass:NSString.class]) {
        self.itemType = BranchShareActivityItemTypeShareText;
    } else {
        self.itemType = BranchShareActivityItemTypeOther;
    }

    return self;
}

- (id) item {
    return [self.parentSheet shareObjectForItem:self activityType:self.activityType];
}

@end

#pragma mark - BranchShareActionSheet

@implementation BranchShareActionSheet

- (instancetype _Nullable) initWithUniversalObject:(BranchUniversalObject*_Nonnull)universalObject
                                    linkProperties:(BranchLinkProperties*_Nonnull)linkProperties {
    self = [super init];
    if (!self) return self;

    _universalObject = universalObject;
    _linkProperties = linkProperties;
    return self;
}

- (void) shareDidComplete:(BOOL)completed activityError:(NSError*)error {
    if ([self.delegate respondsToSelector:@selector(branchShareSheet:didComplete:withError:)]) {
        [self.delegate branchShareSheet:self didComplete:completed withError:error];
    }
    [self.universalObject userCompletedAction:BNCShareCompletedEvent];
    NSDictionary *attributes = [self.universalObject getDictionaryWithCompleteLinkProperties:self.linkProperties];
    [BNCFabricAnswers sendEventWithName:@"Branch Share" andAttributes:attributes];
}

- (void) showFromViewController:(UIViewController*_Nullable)viewController
                         anchor:(UIBarButtonItem*_Nullable)anchor {

    // Make sure we can share

    if (!(self.universalObject.canonicalIdentifier ||
          self.universalObject.canonicalUrl ||
          self.universalObject.title)) {
        NSLog(@"Warning: A canonicalIdentifier, canonicalURL, or title are required to uniquely"
               " identify content. In order to not break the end user experience with sharing,"
               " Branch SDK will proceed to create a URL, but content analytics may not properly"
               " include this URL.");
    }
    
    self.serverParameters =
        [[self.universalObject getParamsForServerRequestWithAddedLinkProperties:self.linkProperties]
            mutableCopy];
    if (self.linkProperties.matchDuration) {
        [self.serverParameters
            setObject:@(self.linkProperties.matchDuration)
            forKey:BRANCH_REQUEST_KEY_URL_DURATION];
    }

    // Log share initiated event
    [self.universalObject userCompletedAction:BNCShareInitiatedEvent];

    NSString *URLString =
        [[Branch getInstance]
            getLongURLWithParams:self.serverParameters
            andChannel:self.linkProperties.channel
            andTags:self.linkProperties.tags
            andFeature:self.linkProperties.feature
            andStage:self.linkProperties.stage
            andAlias:self.linkProperties.alias];
    NSURL *URL = [[NSURL alloc] initWithString:URLString];

    BranchShareActivityItem *item = nil;
    NSMutableArray *items = [NSMutableArray new];
    if (self.shareText.length) {
        item = [[BranchShareActivityItem alloc] initWithPlaceholderItem:self.shareText];
        item.parentSheet = self;
        [items addObject:item];
    }

    item = [[BranchShareActivityItem alloc] initWithPlaceholderItem:URL];
    item.parentSheet = self;
    [items addObject:item];

    UIActivityViewController *shareViewController =
        [[UIActivityViewController alloc]
            initWithActivityItems:items
            applicationActivities:nil];
    
    if ([shareViewController respondsToSelector:@selector(completionWithItemsHandler)]) {
        shareViewController.completionWithItemsHandler =
        ^ (NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            [self shareDidComplete:completed activityError:activityError];
        };
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        shareViewController.completionHandler =
        ^ (UIActivityType activityType, BOOL completed) {
            [self shareDidComplete:completed activityError:nil];
        };
        #pragma clang diagnostic pop
    }
    
    UIViewController *presentingViewController = nil;
    if ([viewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        presentingViewController = viewController;
    } else {
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        UIViewController *rootController = [UIApplicationClass sharedApplication].delegate.window.rootViewController;
        if ([rootController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
            presentingViewController = [[[UIApplicationClass sharedApplication].delegate window] rootViewController];
        }
    }
    
    if (self.linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT]) {
        @try {
            [shareViewController
                setValue:self.linkProperties.controlParams[BRANCH_LINK_DATA_KEY_EMAIL_SUBJECT]
                forKey:@"subject"];
        }
        @catch (NSException *exception) {
            NSLog(@"Unable to setValue 'emailSubject' forKey 'subject' on UIActivityViewController.");
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
        NSLog(@"[Branch warning, fatal] No view controller is present to show the share sheet. Aborting.");
    }
}

- (id) shareObjectForItem:(BranchShareActivityItem*)activityItem
             activityType:(UIActivityType)activityType {

    _activityType = [activityType copy];
    self.linkProperties.channel =
        [BranchActivityItemProvider humanReadableChannelWithActivityType:self.activityType];

    if ([self.delegate respondsToSelector:@selector(branchShareSheetWillShare:)]) {
        [self.delegate branchShareSheetWillShare:self];
    }
    if (activityItem.itemType == BranchShareActivityItemTypeShareText) {
        return self.shareText;
    }
    if (activityItem.itemType == BranchShareActivityItemTypeOther) {
        return self.shareOther;
    }

    // Else activityItem.itemType == BranchShareActivityItemTypeURL

    // Because Facebook et al immediately scrape URLs, we add an additional parameter to the
    // existing list, telling the backend to ignore the first click.

    NSDictionary *scrapers = @{
        @"Facebook":    @1,
        @"Twitter":     @1,
        @"Slack":       @1,
        @"Apple Notes": @1
    };
    NSString *userAgentString = nil;
    if (self.linkProperties.channel && scrapers[self.linkProperties.channel]) {
        userAgentString = [BNCDeviceInfo userAgentString];
    }
    NSString *URLString =
        [[Branch getInstance]
            getShortURLWithParams:self.serverParameters
            andTags:self.linkProperties.tags
            andChannel:self.linkProperties.channel
            andFeature:self.linkProperties.feature
            andStage:self.linkProperties.stage
            andCampaign:self.linkProperties.campaign
            andAlias:self.linkProperties.alias
            ignoreUAString:userAgentString
            forceLinkCreation:YES];
    return [NSURL URLWithString:URLString];
}


@end

//
//  BranchActivityItemProvider.m
//  Branch-TestBed
//
//  Created by Scott Hasbrouck on 1/28/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#if !TARGET_OS_TV

#import "BranchActivityItemProvider.h"
#import "Branch.h"
#import "BranchConstants.h"
#import "BranchLinkBuilder.h"
#import "BNCSystemObserver.h"

#if !TARGET_OS_TV
#import "BNCUserAgentCollector.h"
#endif

@interface BranchActivityItemProvider ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSArray *tags;
@property (copy, nonatomic) NSString *feature;
@property (copy, nonatomic) NSString *stage;
@property (copy, nonatomic) NSString *campaign;
@property (copy, nonatomic) NSString *alias;
@property (copy, nonatomic) NSString *userAgentString;
@property (weak, nonatomic) id <BranchActivityItemProviderDelegate> delegate;

@end

@implementation BranchActivityItemProvider

- (id)initWithParams:(NSDictionary *)params
             andTags:(NSArray *)tags
          andFeature:(NSString *)feature
            andStage:(NSString *)stage
            andAlias:(NSString *)alias {
    return [self initWithParams:params tags:tags feature:feature stage:stage campaign:nil alias:alias delegate:nil];
}

- (id)initWithParams:(NSDictionary *)params
                tags:(NSArray *)tags
             feature:(NSString *)feature
               stage:(NSString *)stage
            campaign:(NSString *)campaign
               alias:(NSString *)alias
            delegate:(id <BranchActivityItemProviderDelegate>)delegate {

    // No channel here, so this URL is unaffected by the builder's channel= fix -- unlike the other
    // long-URL call sites, its output is byte-identical to what the old overload produced.
    BranchLinkBuilder *longURLBuilder = [[BranchLinkBuilder alloc] init];
    longURLBuilder.params = params;
    longURLBuilder.tags = tags;
    longURLBuilder.feature = feature;
    longURLBuilder.stage = stage;
    longURLBuilder.alias = alias;
    NSString *url = [longURLBuilder buildLongURL];

    if (self.returnURL) {
        if ((self = [super initWithPlaceholderItem:[NSURL URLWithString:url]])) {
            _params = params;
            _tags = tags;
            _feature = feature;
            _stage = stage;
            _campaign = campaign;
            _alias = alias;
            #if !TARGET_OS_TV
            _userAgentString = [BNCUserAgentCollector instance].userAgent;
            #endif
            _delegate = delegate;
        }
    } else {
        if ((self = [super initWithPlaceholderItem:url])) {
            _params = params;
            _tags = tags;
            _feature = feature;
            _stage = stage;
            _campaign = campaign;
            _alias = alias;
            #if !TARGET_OS_TV
            _userAgentString = [BNCUserAgentCollector instance].userAgent;
            #endif
            _delegate = delegate;
        }
    }
    return self;
}

- (BOOL) returnURL {
    BOOL returnURL = YES;
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 11.0 &&
        [UIDevice currentDevice].systemVersion.doubleValue  < 11.2 &&
        [self.activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
        returnURL = NO;
    }
    return returnURL;
}

- (id)item {
    NSString *channel = [BranchActivityItemProvider humanReadableChannelWithActivityType:self.activityType];

    // Allow for overrides specific to channel
    NSDictionary *params = [self paramsForChannel:channel];
    NSArray *tags = [self tagsForChannel:channel];
    NSString *feature = [self featureForChannel:channel];
    NSString *stage = [self stageForChannel:channel];
    NSString *campaign = [self campaignForChannel:channel];
    NSString *alias = [self aliasForChannel:channel];

    // Allow the channel param to be overridden, perhaps they want "fb" instead of "facebook"
    if ([self.delegate respondsToSelector:@selector(activityItemOverrideChannelForChannel:)]) {
        channel = [self.delegate activityItemOverrideChannelForChannel:channel];
    }

    // All three short-link paths below share these options and differ only in ignoreUAString, so
    // build one and set that per path. The builder is reusable, but each path returns immediately,
    // so only one is ever used.
    BranchLinkBuilder * (^shortURLBuilder)(NSString *) = ^(NSString *ignoreUAString) {
        BranchLinkBuilder *builder = [[BranchLinkBuilder alloc] init];
        builder.params = params;
        builder.tags = tags;
        builder.channel = channel;
        builder.feature = feature;
        builder.stage = stage;
        builder.campaign = campaign;
        builder.alias = alias;
        builder.ignoreUAString = ignoreUAString;
        return builder;
    };

    // Because Facebook et al immediately scrape URLs, we add an additional parameter to the
    // existing list, telling the backend to ignore the first click
    NSArray *scrapers = @[
        @"Facebook",
        @"Twitter",
        @"Slack",
        @"Apple Notes",
        @"Skype",
        @"SMS"
    ];
    for (NSString *scraper in scrapers) {
        if ([channel isEqualToString:scraper]) {
            NSURL *URL = [NSURL URLWithString:[shortURLBuilder(self.userAgentString) fetchShortURL]];
            return (self.returnURL) ? URL : URL.absoluteString;
        }
    }

    // Wrap the link in HTML content
    if (self.activityType == UIActivityTypeMail &&
        [params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_HEADER] &&
        [params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_FOOTER]) {
        NSURL *link = [NSURL URLWithString:[shortURLBuilder(nil) fetchShortURL]];
        NSString *emailLink;
        if ([params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_LINK_TEXT]) {
            emailLink = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>",
                link, [params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_LINK_TEXT]];
        } else {
            emailLink = link.absoluteString;
        }

        return [NSString stringWithFormat:@"<html>%@%@%@</html>",
            [params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_HEADER],
            emailLink,
            [params objectForKey:BRANCH_LINK_DATA_KEY_EMAIL_HTML_FOOTER]];
    }

    NSURL *URL = [NSURL URLWithString:[shortURLBuilder(nil) fetchShortURL]];
    return (self.returnURL) ? URL : URL.absoluteString;
}

#pragma mark - Internals

+ (NSString *)humanReadableChannelWithActivityType:(NSString *)activityString {
    NSDictionary *channelMappings = [[NSDictionary alloc] initWithObjectsAndKeys:
        @"Pasteboard",  UIActivityTypeCopyToPasteboard,
        @"Email",       UIActivityTypeMail,
        @"SMS",         UIActivityTypeMessage,
        @"Facebook",    UIActivityTypePostToFacebook,
        @"Twitter",     UIActivityTypePostToTwitter,
        @"Weibo",       UIActivityTypePostToWeibo,
        @"Reading List",UIActivityTypeAddToReadingList,
        @"Airdrop",     UIActivityTypeAirDrop,
        @"flickr",      UIActivityTypePostToFlickr,
        @"Tencent Weibo", UIActivityTypePostToTencentWeibo,
        @"Vimeo",       UIActivityTypePostToVimeo,
        @"Apple Notes", @"com.apple.mobilenotes.SharingExtension",
        @"Slack",       @"com.tinyspeck.chatlyio.share",
        @"WhatsApp",    @"net.whatsapp.WhatsApp.ShareExtension",
        @"WeChat",      @"com.tencent.xin.sharetimeline",
        @"LINE",        @"jp.naver.line.Share",
		@"Pinterest",   @"pinterest.ShareExtension",
        @"Skype",       @"com.skype.skype.sharingextension",
        @"Apple Reminders", @"com.apple.reminders.RemindersEditorExtension",

        //  Keys for older app versions --

        @"Facebook",    @"com.facebook.Facebook.ShareExtension",
        @"Twitter",     @"com.atebits.Tweetie2.ShareExtension",

        nil
    ];
    // Set to a more human readable string if we can identify it.
    if (activityString) {
        NSString*humanString = channelMappings[activityString];
        if (humanString) activityString = humanString;
    }
    return activityString;
}

- (NSDictionary *)paramsForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemParamsForChannel:)])
        ? [self.delegate activityItemParamsForChannel:channel]
        : self.params;
}

- (NSArray *)tagsForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemTagsForChannel:)])
        ? [self.delegate activityItemTagsForChannel:channel]
        : self.tags;
}

- (NSString *)featureForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemFeatureForChannel:)])
        ? [self.delegate activityItemFeatureForChannel:channel]
        : self.feature;
}

- (NSString *)stageForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemStageForChannel:)])
        ? [self.delegate activityItemStageForChannel:channel]
        : self.stage;
}

- (NSString *)campaignForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemCampaignForChannel:)])
        ? [self.delegate activityItemCampaignForChannel:channel]
        : self.campaign;
}

- (NSString *)aliasForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemAliasForChannel:)])
        ? [self.delegate activityItemAliasForChannel:channel]
        : self.alias;
}

@end
#endif

//
//  BranchActivityItemProvider.m
//  Branch-TestBed
//
//  Created by Scott Hasbrouck on 1/28/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchActivityItemProvider.h"
#import "Branch.h"
#import "BNCSystemObserver.h"
#import "BNCDeviceInfo.h"

@interface BranchActivityItemProvider ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSString *campaign;
@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) NSString *userAgentString;
@property (weak, nonatomic) id <BranchActivityItemProviderDelegate> delegate;

@end

@implementation BranchActivityItemProvider

- (id)initWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self initWithParams:params tags:tags feature:feature stage:stage campaign:nil alias:alias delegate:nil];
}

- (id)initWithParams:(NSDictionary *)params tags:(NSArray *)tags feature:(NSString *)feature stage:(NSString *)stage campaign:(NSString *)campaign alias:(NSString *)alias delegate:(id <BranchActivityItemProviderDelegate>)delegate {
    NSString *url = [[Branch getInstance] getLongURLWithParams:params andChannel:nil andTags:tags andFeature:feature andStage:stage andAlias:alias];
    
    if (self = [super initWithPlaceholderItem:[NSURL URLWithString:url]]) {
        _params = params;
        _tags = tags;
        _feature = feature;
        _stage = stage;
        _campaign = campaign;
        _alias = alias;
        _userAgentString = [BNCDeviceInfo userAgentString];
        _delegate = delegate;
    }
    
    return self;
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
    
    // Because Facebook et al immediately scrape URLs, we add an additional parameter to the existing list, telling the backend to ignore the first click
    NSArray *scrapers = @[@"Facebook", @"Twitter", @"Slack", @"Apple Notes"];
    for (NSString *scraper in scrapers) {
        if ([channel isEqualToString:scraper])
            return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:params andTags:tags andChannel:channel andFeature:feature andStage:stage andCampaign:campaign andAlias:alias ignoreUAString:self.userAgentString forceLinkCreation:YES]];
    }
    return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:params andTags:tags andChannel:channel andFeature:feature andStage:stage andCampaign:campaign andAlias:alias ignoreUAString:nil forceLinkCreation:YES]];

}

#pragma mark - Internals

+ (NSString *)humanReadableChannelWithActivityType:(NSString *)activityString {
    NSString *channel = activityString; //default
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

        //  Keys for older app versions --

        @"Facebook",    @"com.facebook.Facebook.ShareExtension",
        @"Twitter",     @"com.atebits.Tweetie2.ShareExtension",

        nil
    ];
    // Set to a more human readible sting if we can identify it
    if ([channelMappings objectForKey:activityString]) {
        channel = channelMappings[activityString];
    }
    return channel;
}

- (NSDictionary *)paramsForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemParamsForChannel:)]) ? [self.delegate activityItemParamsForChannel:channel] : self.params;
}

- (NSArray *)tagsForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemTagsForChannel:)]) ? [self.delegate activityItemTagsForChannel:channel] : self.tags;
}

- (NSString *)featureForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemFeatureForChannel:)]) ? [self.delegate activityItemFeatureForChannel:channel] : self.feature;
}

- (NSString *)stageForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemStageForChannel:)]) ? [self.delegate activityItemStageForChannel:channel] : self.stage;
}

- (NSString *)campaignForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemCampaignForChannel:)]) ? [self.delegate activityItemCampaignForChannel:channel] : self.campaign;
}


- (NSString *)aliasForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemAliasForChannel:)]) ? [self.delegate activityItemAliasForChannel:channel] : self.alias;
}

@end

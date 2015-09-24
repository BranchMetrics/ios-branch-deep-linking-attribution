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

// Define constants so that iOS 6 won't crash. Don't care about their values since you can't
// possible access them, just necessary for the sake of not accessing missing symbols.
#ifndef UIActivityTypeAddToReadingList
#define UIActivityTypeAddToReadingList @""
#define UIActivityTypePostToFlickr @""
#define UIActivityTypePostToVimeo @""
#define UIActivityTypePostToTencentWeibo @""
#define UIActivityTypeAirDrop @""
#endif

@interface BranchActivityItemProvider ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) NSString *userAgentString;
@property (weak, nonatomic) id <BranchActivityItemProviderDelegate> delegate;

@end

@implementation BranchActivityItemProvider

- (id)initWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    return [self initWithParams:params tags:tags feature:feature stage:stage alias:alias delegate:nil];
}

- (id)initWithParams:(NSDictionary *)params tags:(NSArray *)tags feature:(NSString *)feature stage:(NSString *)stage alias:(NSString *)alias delegate:(id <BranchActivityItemProviderDelegate>)delegate {
    NSString *url = [[Branch getInstance] getLongURLWithParams:params andChannel:nil andTags:tags andFeature:feature andStage:stage andAlias:alias];
    
    if (self = [super initWithPlaceholderItem:[NSURL URLWithString:url]]) {
        _params = params;
        _tags = tags;
        _feature = feature;
        _stage = stage;
        _alias = alias;
        _userAgentString = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
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
    NSString *alias = [self aliasForChannel:channel];
    
    // Allow the channel param to be overridden, perhaps they want "fb" instead of "facebook"
    if ([self.delegate respondsToSelector:@selector(activityItemOverrideChannelForChannel:)]) {
        channel = [self.delegate activityItemOverrideChannelForChannel:channel];
    }
    
    // Because Facebook immediately scrapes URLs, we add an additional parameter to the existing list, telling the backend to ignore the first click
    if ([channel isEqualToString:@"facebook"] || [channel isEqualToString:@"twitter"]) {
        return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:params andTags:tags andChannel:channel andFeature:feature andStage:stage andAlias:alias ignoreUAString:self.userAgentString forceLinkCreation:YES]];
    }
    
    return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:params andTags:tags andChannel:channel andFeature:feature andStage:stage andAlias:alias ignoreUAString:nil forceLinkCreation:YES]];
}

#pragma mark - Internals

+ (NSString *)humanReadableChannelWithActivityType:(NSString *)activityString {
    NSString *channel = activityString; //default
    
    // Set to a more human readible sting if we can identify it
    if ([activityString isEqualToString:UIActivityTypeAssignToContact]) {
        channel = @"assign_to_contact";
    } else if ([activityString isEqualToString:UIActivityTypeCopyToPasteboard]) {
        channel = @"pasteboard";
    } else if ([activityString isEqualToString:UIActivityTypeMail]) {
        channel = @"email";
    } else if ([activityString isEqualToString:UIActivityTypeMessage]) {
        channel = @"sms";
    } else if ([activityString isEqualToString:UIActivityTypePostToFacebook]) {
        channel = @"facebook";
    } else if ([activityString isEqualToString:UIActivityTypePostToTwitter]) {
        channel = @"twitter";
    } else if ([activityString isEqualToString:UIActivityTypePostToWeibo]) {
        channel = @"weibo";
    } else if ([activityString isEqualToString:UIActivityTypePrint]) {
        channel = @"print";
    } else if ([activityString isEqualToString:UIActivityTypeSaveToCameraRoll]) {
        channel = @"camera_roll";
    } else if ([BNCSystemObserver getOSVersion].integerValue >= 7) {
        if ([activityString isEqualToString:UIActivityTypeAddToReadingList]) {
            channel = @"reading_list";
        } else if ([activityString isEqualToString:UIActivityTypeAirDrop]) {
            channel = @"airdrop";
        } else if ([activityString isEqualToString:UIActivityTypePostToFlickr]) {
            channel = @"flickr";
        } else if ([activityString isEqualToString:UIActivityTypePostToTencentWeibo]) {
            channel = @"tencent_weibo";
        } else if ([activityString isEqualToString:UIActivityTypePostToVimeo]) {
            channel = @"vimeo";
        }
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

- (NSString *)aliasForChannel:(NSString *)channel {
    return ([self.delegate respondsToSelector:@selector(activityItemAliasForChannel:)]) ? [self.delegate activityItemAliasForChannel:channel] : self.alias;
}

@end

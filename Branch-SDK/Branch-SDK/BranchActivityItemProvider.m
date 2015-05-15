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

@interface BranchActivityItemProvider ()

@property (strong, nonatomic) NSDictionary *params;
@property (strong, nonatomic) NSArray *tags;
@property (strong, nonatomic) NSString *feature;
@property (strong, nonatomic) NSString *stage;
@property (strong, nonatomic) NSString *alias;
@property (strong, nonatomic) NSString *userAgentString;

@end

@implementation BranchActivityItemProvider

- (id)initWithParams:(NSDictionary *)params andTags:(NSArray *)tags andFeature:(NSString *)feature andStage:(NSString *)stage andAlias:(NSString *)alias {
    NSString *url = [[Branch getInstance] getLongURLWithParams:params andChannel:nil andTags:tags andFeature:feature andStage:stage andAlias:alias];
    
    if (self = [super initWithPlaceholderItem:[NSURL URLWithString:url]]) {
        self.params = params;
        self.tags = tags;
        self.feature = feature;
        self.stage = stage;
        self.alias = alias;
        self.userAgentString = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    }
    
    return self;
}

- (id)item {
    NSString *channel = [BranchActivityItemProvider humanReadableChannelWithActivityType:self.activityType];
    
    // Because Facebook immediately scrapes URLs, we add an additional parameter to the existing list, telling the backend to ignore the first click
    if ([channel isEqualToString:@"facebook"] || [channel isEqualToString:@"twitter"]) {
        return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:self.params andTags:self.tags andChannel:channel andFeature:self.feature andStage:self.stage andAlias:self.alias ignoreUAString:self.userAgentString]];
    }
    
    return [NSURL URLWithString:[[Branch getInstance] getShortURLWithParams:self.params andTags:self.tags andChannel:channel andFeature:self.feature andStage:self.stage andAlias:self.alias]];
}

// Human readable activity type string
+ (NSString *)humanReadableChannelWithActivityType:(NSString *)activityString {
    NSString *channel = activityString; //default
    
    // Set to a more human readible sting if we can identify it
    if (activityString == UIActivityTypeAssignToContact) {
        channel = @"assign_to_contact";
    } else if (activityString == UIActivityTypeCopyToPasteboard) {
        channel = @"pasteboard";
    } else if (activityString == UIActivityTypeMail) {
        channel = @"email";
    } else if (activityString == UIActivityTypeMessage) {
        channel = @"sms";
    } else if (activityString == UIActivityTypePostToFacebook) {
        channel = @"facebook";
    } else if (activityString == UIActivityTypePostToTwitter) {
        channel = @"twitter";
    } else if (activityString == UIActivityTypePostToWeibo) {
        channel = @"weibo";
    } else if (activityString == UIActivityTypePrint) {
        channel = @"print";
    } else if (activityString == UIActivityTypeSaveToCameraRoll) {
        channel = @"camera_roll";
    } else if ([BNCSystemObserver getOSVersion].integerValue >= 7) {
        if (activityString == UIActivityTypeAddToReadingList) {
            channel = @"reading_list";
        } else if (activityString == UIActivityTypeAirDrop) {
            channel = @"airdrop";
        } else if (activityString == UIActivityTypePostToFlickr) {
            channel = @"flickr";
        } else if (activityString == UIActivityTypePostToTencentWeibo) {
            channel = @"tencent_weibo";
        } else if (activityString == UIActivityTypePostToVimeo) {
            channel = @"vimeo";
        }
    }
    return channel;
}

@end

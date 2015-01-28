//
//  BranchActivityItemProvider.m
//  Branch-TestBed
//
//  Created by Scott Hasbrouck on 1/28/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchActivityItemProvider.h"
#import "Branch.h"

@implementation BranchActivityItemProvider

- (id)initWithDefaultURL:(NSString *)url {
    self = [super initWithPlaceholderItem:url];
    if (self) {
        self.branchURL = url;
        self.semaphore = dispatch_semaphore_create(0);
    }
    return self;
}

- (id) item {
    
    // Set's channel string automatically based on what share
    // channel the user selected in UIActivityViewController
    NSString *channel = self.activityType; //default
    
    // Set to a more human readible sting if we can identify it
    if (self.activityType == UIActivityTypeAddToReadingList) {
        channel = @"reading_list";
    } else if (self.activityType == UIActivityTypeAirDrop) {
        channel = @"airdrop";
    } else if (self.activityType == UIActivityTypeAssignToContact) {
        channel = @"assign_to_contact";
    } else if (self.activityType == UIActivityTypeCopyToPasteboard) {
        channel = @"pasteboard";
    } else if (self.activityType == UIActivityTypeMail) {
        channel = @"email";
    } else if (self.activityType == UIActivityTypeMessage) {
        channel = @"sms";
    } else if (self.activityType == UIActivityTypePostToFacebook) {
        channel = @"facebook";
    } else if (self.activityType == UIActivityTypePostToFlickr) {
        channel = @"flickr";
    } else if (self.activityType == UIActivityTypePostToTencentWeibo) {
        channel = @"tecent_weibo";
    } else if (self.activityType == UIActivityTypePostToTwitter) {
        channel = @"twitter";
    } else if (self.activityType == UIActivityTypePostToVimeo) {
        channel = @"vimeo";
    } else if (self.activityType == UIActivityTypePostToWeibo) {
        channel = @"weibo";
    } else if (self.activityType == UIActivityTypePrint) {
        channel = @"print";
    } else if (self.activityType == UIActivityTypeSaveToCameraRoll) {
        channel = @"camera_roll";
    }
    
    if ([self.placeholderItem isKindOfClass:[NSString class]]) {
        __weak BranchActivityItemProvider *weakSelf = self;
        [[Branch getInstance] getShortURLWithCallback:^(NSString *url, NSError *err) {
            if (!err) {
                self.branchURL = url;
            }
            dispatch_semaphore_signal(weakSelf.semaphore);
        }];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        return self.branchURL;
    }
    return self.placeholderItem;
}

@end

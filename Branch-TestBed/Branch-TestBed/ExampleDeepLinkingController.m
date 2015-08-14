//
//  ExampleDeepLinkingController.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 6/19/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "ExampleDeepLinkingController.h"
#import <CommonCrypto/CommonDigest.h>

@interface ExampleDeepLinkingController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@end

@implementation ExampleDeepLinkingController

@synthesize deepLinkingCompletionDelegate;

- (void)configureControlWithData:(NSDictionary *)data {
    NSString *email = data[@"gravatar_email"];
    
    // Create pointer to the string as UTF8
    const char *ptr = [email UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *emailHash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [emailHash appendFormat:@"%02x", md5Buffer[i]];
    }
    
    NSString *gravatarLink = [NSString stringWithFormat:@"https://www.gravatar.com/avatar/%@?s=256", emailHash];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:gravatarLink]];
        UIImage *image = [UIImage imageWithData:imageData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.profileImageView.image = image;
        });
    });
}

- (IBAction)closePressed {
    [self.deepLinkingCompletionDelegate deepLinkingControllerCompleted];
}

@end

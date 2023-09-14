//
//  BranchInstallRequest.m
//  Branch-TestBed
//
//  Created by Graham Mueller on 5/26/15.
//  Copyright (c) 2015 Branch Metrics. All rights reserved.
//

#import "BranchInstallRequest.h"
#import "BNCServerAPI.h"
#import "BranchConstants.h"

#import "BNCRequestFactory.h"

@implementation BranchInstallRequest

- (id)initWithCallback:(callbackWithStatus)callback {
    return [super initWithCallback:callback isInstall:YES];
}

- (void)makeRequest:(BNCServerInterface *)serverInterface key:(NSString *)key callback:(BNCServerCallback)callback {
    
    // TODO: move this logic
    super.clearLocalURL = NO;
        
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key];
    NSDictionary *params = [factory dataForInstall];

    // TODO: figure out why this is different
//    if ([BNCPasteboard sharedInstance].checkOnInstall) {
//        NSURL *pasteboardURL = nil;
//        if (@available(iOS 16.0, macCatalyst 16.0, *)) {
//            NSString *localURLString = [[BNCPreferenceHelper sharedInstance] localUrl];
//            if(localURLString){
//                pasteboardURL = [[NSURL alloc] initWithString:localURLString];
//                super.clearLocalURL = TRUE;
//            } else {
//                pasteboardURL = [[BNCPasteboard sharedInstance] checkForBranchLink];
//            }
//        } else {
//            pasteboardURL = [[BNCPasteboard sharedInstance] checkForBranchLink];
//        }
//
//        if (pasteboardURL) {
//            [self safeSetValue:pasteboardURL.absoluteString forKey:BRANCH_REQUEST_KEY_LOCAL_URL onDict:params];
//        }
//    }

    [serverInterface postRequest:params url:[[BNCServerAPI sharedInstance] installServiceURL].absoluteString key:key callback:callback];
}

- (NSString *)getActionName {
    return @"install";
}

@end

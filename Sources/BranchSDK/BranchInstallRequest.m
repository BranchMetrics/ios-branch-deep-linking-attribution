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
    BNCRequestFactory *factory = [[BNCRequestFactory alloc] initWithBranchKey:key UUID:self.requestUUID TimeStamp:self.requestCreationTimeStamp];
    NSDictionary *params = [factory dataForInstallWithURLString:self.urlString];

    self.requestParams = [params copy];
    self.requestServiceURL = [[BNCServerAPI sharedInstance] installServiceURL];
    
    [serverInterface postRequest:params url:self.requestServiceURL  key:key callback:callback];
}

- (NSString *)getActionName {
    return @"install";
}

@end

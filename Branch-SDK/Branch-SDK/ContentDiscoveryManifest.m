//
//  ContentDiscoverManifest.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/18/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDiscoveryManifest.h"
#import "BNCPreferenceHelper.h"
#import "ContentPathProperties.h"
#import <UIKit/UIKit.h>
#import "BranchConstants.h"

@implementation ContentDiscoveryManifest

NSString *manifestVersion;


static ContentDiscoveryManifest *contentDiscoveryManifest;

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *savedManifest = [[BNCPreferenceHelper preferenceHelper]getContentAnalyticsManifest];
        if(savedManifest != nil ) {
            _cdManifest = [savedManifest mutableCopy];
        }
        else {
            _cdManifest = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

+ (ContentDiscoveryManifest *)getInstance {
    if (!contentDiscoveryManifest) {
        contentDiscoveryManifest = [[ContentDiscoveryManifest alloc] init];
    }
    return contentDiscoveryManifest;
}



- (void) onBranchInitialised:(NSDictionary *) branchInitDict withUrl:(NSString *) referredUrl {
    _referredLink = referredUrl;
    if([branchInitDict objectForKey:CONTENT_DISCOVER_KEY] != nil) {
        _isCDEnabled = YES;
        NSDictionary *cdManifestDict = [branchInitDict objectForKey:CONTENT_DISCOVER_KEY];
        
        if([cdManifestDict objectForKey:MANIFEST_VERSION_KEY] != nil) {
            manifestVersion = [cdManifestDict objectForKey:MANIFEST_VERSION_KEY];
        }
        
        if([cdManifestDict objectForKey:MAX_VIEW_HISTORY_LENGTH] != nil) {
            _maxViewHistoryLength = [[cdManifestDict objectForKey:MAX_VIEW_HISTORY_LENGTH] integerValue];
        }
        
        if([cdManifestDict objectForKey:MANIFEST_KEY] != nil) {
            _contentPaths = [cdManifestDict objectForKey:MANIFEST_KEY];
        }
        
        if([cdManifestDict objectForKey:MAX_TEXT_LEN_KEY] != nil) {
            _maxTextLen = [[cdManifestDict objectForKey:MAX_TEXT_LEN_KEY]integerValue];
        }
        
        if([cdManifestDict objectForKey:MAX_PACKET_SIZE_KEY] != nil) {
            _maxPktSize = [[cdManifestDict objectForKey:MAX_PACKET_SIZE_KEY]integerValue];
        }
        
        [_cdManifest setObject:manifestVersion forKey:MANIFEST_VERSION_KEY];
        [_cdManifest setObject:_contentPaths forKey:MANIFEST_KEY];
        
        [[BNCPreferenceHelper preferenceHelper] saveContentAnalyticsManifest:_cdManifest];
    } else {
        _isCDEnabled = NO;
    }
    
}

- (NSString *) getManifestVersion {
    NSString *mVersion = @"-1";
    if(_cdManifest != nil && [_cdManifest objectForKey:MANIFEST_VERSION_KEY] != nil) {
        mVersion = [_cdManifest objectForKey:MANIFEST_VERSION_KEY] ;
    }
    return mVersion;
}

- (ContentPathProperties *) getContentPathProperties:(UIViewController *) viewController {
    ContentPathProperties *contentPathProperties;
    
    if(_contentPaths != nil) {
        NSString *viewPath = [NSString stringWithFormat:@"/%@",([viewController class])];        
        for(NSDictionary * pathObj in _contentPaths) {
            NSString *pathStr = [pathObj objectForKey:PATH_KEY];
            if(pathStr != nil && [pathStr isEqualToString:viewPath]){
                contentPathProperties = [[ContentPathProperties alloc]init:pathObj];
                break;
            }
        }
    }
    return contentPathProperties;
}



@end

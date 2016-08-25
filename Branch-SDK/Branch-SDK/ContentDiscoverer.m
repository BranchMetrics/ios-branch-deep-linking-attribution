//
//  ContentDiscoverer.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/17/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDiscoverer.h"
#import "ContentDiscoveryManifest.h"
#import "ContentPathProperties.h"
#import "BNCPreferenceHelper.h"
#import "BranchConstants.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>


@implementation ContentDiscoverer

static ContentDiscoverer *contentViewHandler;
UIViewController *lastViewController;
ContentDiscoveryManifest *cdManifest;
int numOfViewsDiscovered;
NSTimer *contentDiscoveryTimer;
int const CONTENT_DISCOVERY_INTERVAL = 5;


+ (ContentDiscoverer *)getInstance:(ContentDiscoveryManifest *)manifest {
    if (!contentViewHandler) {
        contentViewHandler = [[ContentDiscoverer alloc] init];
    }
    numOfViewsDiscovered = 0;
    cdManifest = manifest;
    return contentViewHandler;
}

+ (ContentDiscoverer *)getInstance {
    return contentViewHandler;
}

- (void) startContentDiscoveryTask {
    contentDiscoveryTimer = [NSTimer scheduledTimerWithTimeInterval:CONTENT_DISCOVERY_INTERVAL
                                                             target:self
                                                           selector:@selector(readContentDataIfNeeded)
                                                           userInfo:nil
                                                            repeats:YES];
}


- (void) stopContentDiscoveryTask {
    lastViewController = nil;
    if(contentDiscoveryTimer != nil) {
        [contentDiscoveryTimer invalidate];
    }
}

- (void) readContentDataIfNeeded {
    if(numOfViewsDiscovered < cdManifest.maxViewHistoryLength) {
        UIViewController *presentingViewController = [self getActiveViewController];
        if(lastViewController == nil || (lastViewController.class != presentingViewController.class)) {
            lastViewController = presentingViewController;
            [self readContentData];
        }
    } else {
        [self stopContentDiscoveryTask];
    }
}

- (void) readContentData {
    UIViewController * viewController = lastViewController;
    if (viewController != nil) {
        UIView * rootView = [viewController view];
        if([viewController isKindOfClass:UITableViewController.class]) {
            rootView = ((UITableViewController *) viewController).tableView;
        } else if([viewController isKindOfClass:UICollectionViewController.class]){
            rootView = ((UICollectionViewController *) viewController).collectionView;
        }
        
        NSMutableArray * contentDataArray = [[NSMutableArray alloc]init];
        NSMutableArray * contentKeysArray = [[NSMutableArray alloc]init];
        BOOL isClearText = YES;
        
        if( rootView != nil) {
            ContentPathProperties *pathProperties = [cdManifest getContentPathProperties:viewController];
            // Check for any existing path properties for this ViewController
            if(pathProperties != nil) {
                isClearText = pathProperties.isClearText;
                if(!pathProperties.isSkipContentDiscovery){
                    NSArray *filteredKeys = [pathProperties getFilteredElements];
                    if(filteredKeys == nil || filteredKeys.count == 0) {
                        [self discoverViewContents:rootView contentData:contentDataArray contentKeys:contentKeysArray clearText:isClearText ID:@""];
                    }
                    else {
                        contentKeysArray = filteredKeys.mutableCopy;
                        [self discoverFilteredViewContents:contentDataArray contentKeys:contentKeysArray clearText:isClearText];
                    }
                }
            } else if(cdManifest.referredLink != nil) { // else discover content if this session is started by a link click
                [self discoverViewContents:rootView contentData:nil contentKeys:contentKeysArray clearText:YES ID:@""];
            }
            
            if (contentKeysArray != nil && contentKeysArray.count > 0) {
                NSMutableDictionary *contentEventObj = [[NSMutableDictionary alloc] init];
                [contentEventObj setObject:[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] forKey: TIME_STAMP_KEY];
                if(cdManifest.referredLink != nil) {
                    [contentEventObj setObject:cdManifest.referredLink forKey: REFERRAL_LINK_KEY];
                }
                
                [contentEventObj setObject:[NSString stringWithFormat:@"/%@",lastViewController.class] forKey: VIEW_KEY];
                [contentEventObj setObject:isClearText? @"true":@"false" forKey: HASH_MODE_KEY];
                [contentEventObj setObject:contentKeysArray forKey:CONTENT_KEYS_KEY];
                if(contentDataArray != nil && contentDataArray.count > 0){
                    [contentEventObj setObject:contentDataArray forKey:CONTENT_DATA_KEY];
                }
                
                [[BNCPreferenceHelper preferenceHelper]saveBranchAnalyticsData:contentEventObj];
            }
        }
    }
}



- (void) discoverViewContents:(UIView *) rootView contentData:(NSMutableArray *)contentDataArray contentKeys:(NSMutableArray *) contentKeysArray clearText:(BOOL)isClearText ID:(NSString *) viewId {
    if([rootView isKindOfClass:UITableView.class]) {
        NSArray * cells = ((UITableView *)rootView).visibleCells;
        int cellCnt=-1;
        for (UIView* cell in cells) {
            cellCnt++;
            NSString *format;
            if(viewId.length > 0 ) {
                format = @"-%d";
            } else {
                format = @"%d";
            }
            NSString *cellViewId = [viewId stringByAppendingFormat:format ,cellCnt];
            [self discoverViewContents:cell contentData:contentDataArray contentKeys:contentKeysArray clearText:isClearText ID:cellViewId ];
        }
    } else {
        if([rootView respondsToSelector:@selector(text)]){
            NSString *contentData;
            contentData = [rootView valueForKey:@"text"];
            if(contentData != nil) {
                [contentKeysArray addObject:viewId];
                if(contentDataArray != nil) {
                    [self addFormatedContentData:contentDataArray withText:contentData clearText:isClearText];
                }
            }
        }
        NSArray *subViews = [rootView subviews];
        if (subViews.count > 0) {
            int childCount = -1;
            for (UIView* view in subViews ) {
                childCount++;
                NSString *subViewId = [viewId stringByAppendingFormat:@"-%d" ,childCount];
                [self discoverViewContents:view contentData:contentDataArray contentKeys:contentKeysArray clearText:isClearText ID:subViewId];
            }
        }
        
    }
}


- (void) discoverFilteredViewContents:(NSMutableArray *)contentDataArray contentKeys:(NSMutableArray *) contentKeysArray clearText:(BOOL)isClearText {
    for (NSString * contentKey in contentKeysArray) {
        NSString *contentData = [self getViewText:contentKey forController:lastViewController];
        if(contentData == nil) {
            contentData = @"";
        }
        if(contentDataArray != nil) {
            [self addFormatedContentData:contentDataArray withText:contentData clearText:isClearText];
        }
    }
}


- (NSString *) getViewText: (NSString *) viewId forController:(UIViewController *) viewController {
    NSString *viewTxt = @"";
    if (viewController != nil) {
        UIView * rootView = [viewController view];
        
        NSArray * viewIds = [viewId componentsSeparatedByString:@"-"];
        BOOL foundView = true;
        for(NSString *subViewIdStr in viewIds) {
            int subviewId = [subViewIdStr intValue];
            if([rootView isKindOfClass:UITableView.class]) {
                if( [((UITableView *)rootView) visibleCells].count > subviewId) {
                    rootView = [[((UITableView *)rootView) visibleCells] objectAtIndex:subviewId];
                }
                else {
                    foundView =false;
                    break;
                }
            }
            else {
                if([rootView subviews].count > subviewId) {
                    rootView = [[rootView subviews] objectAtIndex:subviewId];
                } else {
                    foundView =false;
                    break;
                }
            }
        }
        if(foundView == true && [rootView respondsToSelector:@selector(text)]) {
            viewTxt = [rootView valueForKey:@"text"];
        }
    }
    return viewTxt;
}


- (UIViewController *) getActiveViewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self getActiveViewController:rootViewController];
    
}

- (UIViewController *) getActiveViewController:(UIViewController *) rootViewController {
    UIViewController *activeController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        activeController = ((UINavigationController *)rootViewController).topViewController;
    }
    else if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        activeController = ((UITabBarController *)rootViewController).selectedViewController;
    }
    else {
        activeController = rootViewController;
    }
    return activeController;
}

- (void) addFormatedContentData:(NSArray *)contentDataArray withText:(NSString *)contentData clearText:(BOOL)isClearText {
    if (contentData != nil && contentData.length > cdManifest.maxTextLen) {
        contentData = [contentData substringToIndex:cdManifest.maxTextLen];
    }
    if(!isClearText) {
        contentData = [self hashContent:contentData];
    }
}

- (NSString*) hashContent:(NSString *)content {
    const char *ptr = [content UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}

@end




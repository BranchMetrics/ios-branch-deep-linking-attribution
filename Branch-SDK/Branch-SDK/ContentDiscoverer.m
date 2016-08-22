//
//  ContentDiscoverer.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 8/17/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ContentDiscoverer.h"
#import <UIKit/UIKit.h>


@implementation ContentDiscoverer

static ContentDiscoverer *contentViewHandler;

+ (ContentDiscoverer *)getInstance {
    if (!contentViewHandler) {
        contentViewHandler = [[ContentDiscoverer alloc] init];
    }
    return contentViewHandler;
}

- (void) readContentData: (UIViewController *) viewController {
    if (viewController != nil) {
        UIView * rootView = [viewController view];
        if([viewController isKindOfClass:UITableViewController.class]) {
            rootView = ((UITableViewController *) viewController).tableView;
        } else if([viewController isKindOfClass:UICollectionViewController.class]){
            rootView = ((UICollectionViewController *) viewController).collectionView;
        }
        
        NSMutableArray * contentDataArray = [[NSMutableArray alloc]init];
        NSMutableArray * contentKeysArray = [[NSMutableArray alloc]init];
        
        if( rootView != nil) {
            [self discoverViewContents:rootView contentData:contentDataArray contentKeys:contentKeysArray clearText:TRUE ID:@""];
            NSLog(@"Content keys %@",contentKeysArray);
            NSLog(@"Content data %@",contentDataArray);
            
            for (NSString * key in contentKeysArray) {
                NSLog(@" %@ - %@",key,[self getViewText:key forController:viewController] );
            }
        }
    }
}

- (void) discoverViewContents:(UIView *) rootView contentData:(NSMutableArray *)ContentDataArray contentKeys:(NSMutableArray *) contentKeysArray clearText:(BOOL)isClearText ID:(NSString *) viewId {
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
            [self discoverViewContents:cell contentData:ContentDataArray contentKeys:contentKeysArray clearText:isClearText ID:cellViewId ];
        }
    } else {
        if([rootView respondsToSelector:@selector(text)]){
            NSString *textVal;
            textVal = [rootView valueForKey:@"text"];
            if(textVal != nil) {
                [contentKeysArray addObject:viewId];
                [ContentDataArray addObject: textVal];
            }
        }
        NSArray *subViews = [rootView subviews];
        if (subViews.count > 0) {
            int childCount = -1;
            for (UIView* view in subViews ) {
                childCount++;
                NSString *subViewId = [viewId stringByAppendingFormat:@"-%d" ,childCount];
                [self discoverViewContents:view contentData:ContentDataArray contentKeys:contentKeysArray clearText:isClearText ID:subViewId];
            }
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


@end




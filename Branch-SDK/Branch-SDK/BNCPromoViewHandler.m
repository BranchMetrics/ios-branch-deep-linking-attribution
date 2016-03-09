//
//  BNCPromoViewHandler.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/3/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BNCPromoViewhandler.h"
#import "Branch.h"
#import "BNCAppPromoView.h"


@implementation BNCPromoViewHandler

static BNCPromoViewHandler *bncPromoViewHandler;

+ (BNCPromoViewHandler *)getInstance {
    if (!bncPromoViewHandler) {
        bncPromoViewHandler = [[BNCPromoViewHandler alloc] init];
        bncPromoViewHandler.promoViewCache = [[NSMutableArray alloc] init];
    }
    return bncPromoViewHandler;
}

- (void) saveAppPromoViews : (NSArray *) promoViewList {    
    for (NSDictionary *promoView in promoViewList) {
        AppPromoView *appPromoView = [[AppPromoView alloc]initWithPromoView: promoView];
        [self.promoViewCache addObject:appPromoView];
    }
}

- (BOOL) showPromoView : (NSString*) actionName {
    for (AppPromoView * promoView in self.promoViewCache) {
        if([promoView.promoAction isEqualToString:actionName] && [promoView isAvailable]) {
            [self showView:promoView];
            [promoView updateUsageCount];
            return TRUE;
        }
    }
    return FALSE;
}

- (void) showView : (AppPromoView*) appPromoView {    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIWebView *webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
   
    webview.scrollView.scrollEnabled = NO;
    webview.scrollView.bounces = NO;
  
    NSURL *url = [NSURL URLWithString:appPromoView.webUrl];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webview loadRequest:requestObj];

    UIViewController *holderView = [[UIViewController alloc] init];
    
    UITextView *txtview =  [[UITextView alloc]initWithFrame:CGRectMake(0, 0, screenRect.size.width, 40)];
    [txtview setText: @"Confirm"];
    [txtview setFont: [UIFont boldSystemFontOfSize:15]];
    [txtview setTextColor: [UIColor whiteColor]];
    [txtview setTextAlignment: NSTextAlignmentCenter];
    [txtview setBackgroundColor: [UIColor redColor]];
    [txtview setUserInteractionEnabled:TRUE];
    txtview.frame = CGRectMake(    holderView.view.frame.size.width - txtview.frame.size.width,
                                   holderView.view.frame.size.height - txtview.frame.size.height,
                                   txtview.frame.size.width,
                                   txtview.frame.size.height );
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePromoView:)];
    [txtview addGestureRecognizer:tap];
    
    [holderView.view addSubview:txtview];
    [holderView.view insertSubview:webview atIndex:0];
    
     UIViewController *presentingViewController = [[[UIApplication sharedApplication].delegate window] rootViewController];
    [presentingViewController presentViewController:holderView animated:YES completion:nil];
}

- (void)closePromoView:(UITapGestureRecognizer *)gesture {
     UIViewController *presentingViewController = [[[UIApplication sharedApplication].delegate window] rootViewController];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
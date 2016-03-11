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

@interface BNCPromoViewHandler() <UIWebViewDelegate>
@end

NSString * const APP_PROMO_REDIRECT_SCHEME = @"branch-cta";
NSString * const APP_PROMO_REDIRECT_ACTION_ACCEPT = @"accept";
NSString * const APP_PROMO_REDIRECT_ACTION_CANCEL = @"cancel";

@implementation BNCPromoViewHandler

static BNCPromoViewHandler *bncPromoViewHandler;
BOOL isPromoAccepted = false;
NSString * currentActionName;

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

- (BOOL) showPromoView : (NSString*) actionName withCallback:(id) callback {
    for (AppPromoView * promoView in self.promoViewCache) {
        if([promoView.promoAction isEqualToString:actionName] && [promoView isAvailable]) {
            self.promoViewCallback = callback;
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
    webview.delegate = self;
    
    if (appPromoView.webHtml) {
        [webview loadHTMLString:appPromoView.webHtml baseURL:nil];
    }
    else if (appPromoView.webUrl) {
        NSURL *url = [NSURL URLWithString:appPromoView.webUrl];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [webview loadRequest:requestObj];
    }
    else {
        return;
    }
    
    isPromoAccepted = false;
    currentActionName = appPromoView.promoAction;
    
    UIViewController *holderView = [[UIViewController alloc] init];
    [holderView.view insertSubview:webview atIndex:0];
    
     UIViewController *presentingViewController = [[[UIApplication sharedApplication].delegate window] rootViewController];
    [presentingViewController presentViewController:holderView animated:YES completion:nil];
    
    if (self.promoViewCallback) {
        [self.promoViewCallback promoViewVisible:appPromoView.promoAction];
    }
}

- (void) closePromoView {
    UIViewController *presentingViewController = [[[UIApplication sharedApplication].delegate window] rootViewController];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.promoViewCallback) {
        if (isPromoAccepted) {
            [self.promoViewCallback promoViewAccepted:currentActionName];
        }
        else {
            [self.promoViewCallback promoViewCancelled:currentActionName];
        }
    }

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL isRedirectHandled = [self handleUserActionRedirects:request];
    if (isRedirectHandled) {
        [self closePromoView];
    }
    return !isRedirectHandled;
}

- (BOOL)handleUserActionRedirects:(NSURLRequest *) request {
    BOOL isRedirectionHandled = NO;
    if ([[request.URL scheme] isEqual: APP_PROMO_REDIRECT_SCHEME]) {
        if ([[request.URL host] isEqual:APP_PROMO_REDIRECT_ACTION_ACCEPT]) {
            isPromoAccepted = true;
        }
        else if ([[request.URL host] isEqual:APP_PROMO_REDIRECT_ACTION_CANCEL]) {
            isPromoAccepted = false;
        }
        isRedirectionHandled = YES;
    }
    return isRedirectionHandled;
}


@end
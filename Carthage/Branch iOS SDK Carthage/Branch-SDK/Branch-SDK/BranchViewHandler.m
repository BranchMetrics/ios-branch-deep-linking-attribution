//
//  BranchViewHandler.m
//  Branch-TestBed
//
//  Created by Sojan P.R. on 3/3/16.
//  Copyright © 2016 Branch Metrics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BranchViewhandler.h"
#import "Branch.h"
#import "BranchView.h"

@interface BranchViewHandler() <UIWebViewDelegate>
@end

NSString * const BRANCH_VIEW_REDIRECT_SCHEME = @"branch-cta";
NSString * const BRANCH_VIEW_REDIRECT_ACTION_ACCEPT = @"accept";
NSString * const BRANCH_VIEW_REDIRECT_ACTION_CANCEL = @"cancel";

@implementation BranchViewHandler

static BranchViewHandler *branchViewHandler;
BOOL isBranchViewAccepted = NO;
NSString *currentActionName;
NSString *currentBranchViewID;

+ (BranchViewHandler *)getInstance {
    if (!branchViewHandler) {
        branchViewHandler = [[BranchViewHandler alloc] init];
    }
    return branchViewHandler;
}

- (BOOL)showBranchView:(NSString *)actionName withBranchViewDictionary:(NSDictionary*)branchViewDict andWithDelegate:(id)callback {
    BranchView *branchView = [[BranchView alloc] initWithBranchView:branchViewDict andActionName:actionName];
    return[self showBranchView:branchView withDelegate:callback];
}

- (BOOL)showBranchView:(BranchView *)branchView withDelegate:(id)callback {
    if ([branchView isAvailable]){
        self.branchViewCallback = callback;
        [self showView:branchView];
        [branchView updateUsageCount];
        return YES;
    } else {
        return NO;
    }
}

- (void)showView:(BranchView *)branchView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIWebView *webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    webview.scrollView.scrollEnabled = NO;
    webview.scrollView.bounces = NO;
    webview.delegate = self;
    
    if (branchView.webHtml) {
        [webview loadHTMLString:branchView.webHtml baseURL:nil];
    }
    else if (branchView.webUrl) {
        NSURL *url = [NSURL URLWithString:branchView.webUrl];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [webview loadRequest:requestObj];
    }
    else {
        return;
    }
    
    isBranchViewAccepted = NO;
    currentActionName = branchView.branchViewAction;
    currentBranchViewID = branchView.branchViewID;
    
    UIViewController *holderView = [[UIViewController alloc] init];
    [holderView.view insertSubview:webview atIndex:0];
    UIViewController *presentingViewController = [[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
    [presentingViewController presentViewController:holderView animated:YES completion:nil];
    
    if (self.branchViewCallback) {
        [self.branchViewCallback branchViewVisible:branchView.branchViewAction withID:branchView.branchViewID];
    }
}

- (void)closeBranchView {
    UIViewController *presentingViewController = [[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.branchViewCallback) {
        if (isBranchViewAccepted) {
            [self.branchViewCallback branchViewAccepted:currentActionName withID:currentBranchViewID];
        }
        else {
            [self.branchViewCallback branchViewCancelled:currentActionName withID:currentBranchViewID];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL isRedirectHandled = [self handleUserActionRedirects:request];
    if (isRedirectHandled) {
        [self closeBranchView];
    }
    return !isRedirectHandled;
}

- (BOOL)handleUserActionRedirects:(NSURLRequest *)request {
    BOOL isRedirectionHandled = NO;
    if ([[request.URL scheme] isEqualToString:BRANCH_VIEW_REDIRECT_SCHEME]) {
        if ([[request.URL host] isEqualToString:BRANCH_VIEW_REDIRECT_ACTION_ACCEPT]) {
            isBranchViewAccepted = YES;
        }
        else if ([[request.URL host] isEqualToString:BRANCH_VIEW_REDIRECT_ACTION_CANCEL]) {
            isBranchViewAccepted = NO;
        }
        isRedirectionHandled = YES;
    }
    return isRedirectionHandled;
}


@end
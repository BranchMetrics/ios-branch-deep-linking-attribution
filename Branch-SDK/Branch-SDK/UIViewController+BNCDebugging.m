//
//  UIViewController+BNCDebugging.m
//  Branch-TestBed
//
//  Created by Qinwei Gong on 11/12/14.
//  Copyright (c) 2014 Branch Metrics. All rights reserved.
//

#import "UIViewController+BNCDebugging.h"
#import <objc/runtime.h>
#import "BNCPreferenceHelper.h"

@interface UIViewController () <UIGestureRecognizerDelegate, BNCDebugConnectionDelegate>

@end

@implementation UIViewController (BNCDebugging)

static dispatch_queue_t bnc_asyncDebugQueue = nil;
static NSTimer *bnc_debugTimer = nil;
static UIWindow *bnc_debugWindow = nil;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // viewDidLoad
        SEL originalWillSelector = @selector(viewDidLoad);
        SEL swizzledWillSelector = @selector(bnc_viewDidLoad);
        
        Method originalWillMethod = class_getInstanceMethod(class, originalWillSelector);
        Method swizzledWillMethod = class_getInstanceMethod(class, swizzledWillSelector);
        
        BOOL willAddMethod = class_addMethod(class, originalWillSelector, method_getImplementation(swizzledWillMethod), method_getTypeEncoding(swizzledWillMethod));
        
        if (willAddMethod) {
            class_replaceMethod(class, swizzledWillSelector, method_getImplementation(originalWillMethod), method_getTypeEncoding(originalWillMethod));
        } else {
            method_exchangeImplementations(originalWillMethod, swizzledWillMethod);
        }
        
        // viewDidAppear
        SEL originalDidSelector = @selector(viewDidAppear:);
        SEL swizzledDidSelector = @selector(bnc_viewDidAppear:);
        
        Method originalDidMethod = class_getInstanceMethod(class, originalDidSelector);
        Method swizzledDidMethod = class_getInstanceMethod(class, swizzledDidSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalDidSelector, method_getImplementation(swizzledDidMethod), method_getTypeEncoding(swizzledDidMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledDidSelector, method_getImplementation(originalDidMethod), method_getTypeEncoding(originalDidMethod));
        } else {
            method_exchangeImplementations(originalDidMethod, swizzledDidMethod);
        }
    });
}

- (void)bnc_viewDidAppear:(BOOL)animated {
    [self bnc_viewDidAppear:animated];
    bnc_debugWindow = self.view.window;
}

- (void)bnc_viewDidLoad {
    [self bnc_viewDidLoad];
    [self bnc_addDebugGestureRecognizers];
}

- (void)bnc_addDebugGestureRecognizers {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(bnc_connectToDebug:)];
    longPress.minimumPressDuration = 1.0;
    longPress.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bnc_endDebug:)];
    tap.numberOfTapsRequired = 2;
    tap.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:tap];
}

- (void)bnc_connectToDebug:(UILongPressGestureRecognizer *)gesture {
    [BNCPreferenceHelper setDebugConnectionDelegate:self];
    [BNCPreferenceHelper setDebug];
}

- (void)bnc_startDebug {
    NSLog(@"======= Start Debug Session =======");
    if (!bnc_asyncDebugQueue) {
        bnc_asyncDebugQueue = dispatch_queue_create("bnc_debug_queue", NULL);
    }
    
    //TODO: screenshots for future
//    if (!bnc_debugTimer || !bnc_debugTimer.isValid) {
//        bnc_debugTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f
//                                                               target:self
//                                                             selector:@selector(bnc_takeScreenshot)
//                                                             userInfo:nil
//                                                              repeats:YES];
//    }
}

- (void)bnc_endDebug:(UITapGestureRecognizer *)gesture {
    NSLog(@"======= End Debug Session =======");
    [BNCPreferenceHelper clearDebug];
    bnc_asyncDebugQueue = nil;
    [bnc_debugTimer invalidate];
}

- (void)bnc_takeScreenshot {
    if (bnc_asyncDebugQueue) {
        dispatch_async(bnc_asyncDebugQueue, ^{
            if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
                UIGraphicsBeginImageContextWithOptions(bnc_debugWindow.bounds.size, NO, [UIScreen mainScreen].scale);
            } else {
                UIGraphicsBeginImageContext(bnc_debugWindow.bounds.size);
            }
            
            [bnc_debugWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            NSData * data = UIImagePNGRepresentation(image);
            [BNCPreferenceHelper sendScreenshot:data];
        });
    }
}

#pragma mark - BNCDebugConnectionDelegate delegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (void)bnc_debugConnectionEstablished {
    [self bnc_startDebug];
}

#pragma clang diagnostic pop

@end

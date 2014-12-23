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
#import "BNCSystemObserver.h"

static int BNCDebugTriggerDuration = 2.9;
static int BNCDebugTriggerFingers = 4;
static int BNCDebugTriggerFingersSimulator = 2;

@interface UIViewController () <UIGestureRecognizerDelegate, BNCDebugConnectionDelegate>

@end

@implementation UIViewController (BNCDebugging)

static dispatch_queue_t bnc_asyncDebugQueue = nil;
static NSTimer *bnc_debugTimer = nil;
static UIWindow *bnc_debugWindow = nil;
static UILongPressGestureRecognizer *BNCLongPress = nil;

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
    [self bnc_addDebugGestureRecognizer];
}

- (void)bnc_addDebugGestureRecognizer {
    [self bnc_addGesterRecognizer:@selector(bnc_connectToDebug:)];
}

- (void)bnc_addCancelDebugGestureRecognizer {
    [self bnc_addGesterRecognizer:@selector(bnc_endDebug:)];
}

- (void)bnc_addGesterRecognizer:(SEL)action {
    BNCLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:action];
    BNCLongPress.cancelsTouchesInView = NO;
    BNCLongPress.minimumPressDuration = BNCDebugTriggerDuration;
    if (![BNCSystemObserver isSimulator]) {
        BNCLongPress.numberOfTouchesRequired = BNCDebugTriggerFingers;
    } else {
        BNCLongPress.numberOfTouchesRequired = BNCDebugTriggerFingersSimulator;
    }
    [self.view addGestureRecognizer:BNCLongPress];
}

- (void)bnc_connectToDebug:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan){
        NSLog(@"======= Start Debug Session =======");
        [BNCPreferenceHelper setDebugConnectionDelegate:self];
        [BNCPreferenceHelper setDebug];
    }
}

- (void)bnc_startDebug {
    NSLog(@"======= Connected to Branch Remote Debugger =======");
    
    if (!bnc_asyncDebugQueue) {
        bnc_asyncDebugQueue = dispatch_queue_create("bnc_debug_queue", NULL);
    }
    
    [self.view removeGestureRecognizer:BNCLongPress];
    [self bnc_addCancelDebugGestureRecognizer];
    
    //TODO: change to send screenshots instead in future
    if (!bnc_debugTimer || !bnc_debugTimer.isValid) {
        bnc_debugTimer = [NSTimer scheduledTimerWithTimeInterval:20.0f
                                                               target:self
                                                             selector:@selector(bnc_keepDebugAlive)     //change to @selector(bnc_takeScreenshot)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (void)bnc_endDebug:(UILongPressGestureRecognizer *)sender {
    NSLog(@"======= End Debug Session =======");
    
    [self.view removeGestureRecognizer:sender];
    [BNCPreferenceHelper clearDebug];
    bnc_asyncDebugQueue = nil;
    [bnc_debugTimer invalidate];
    [self bnc_addDebugGestureRecognizer];
}

- (void)bnc_keepDebugAlive {
    if (bnc_asyncDebugQueue) {
        dispatch_async(bnc_asyncDebugQueue, ^{
            [BNCPreferenceHelper keepDebugAlive];
        });
    }
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

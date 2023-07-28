//
//  PasteControlViewController.m
//  Branch-TestBed
//
//  Created by Nidhi Dixit on 9/27/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#import "PasteControlViewController.h"
#import "Branch.h"
#import "BranchOpenRequest.h"
#import "BranchPasteControl.h"
#import "LogOutputViewController.h"
#import "AppDelegate.h"

@interface PasteControlViewController ()
@property (weak, nonatomic) IBOutlet UIView *applePasteControlView;
@property (weak, nonatomic) IBOutlet UIView *branchPasteControlView;

@end

@implementation PasteControlViewController

@synthesize pasteConfiguration;

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 16.0, macCatalyst 16.0, *)) {
        CGRect rectPC = CGRectMake(0, 0, _applePasteControlView.frame.size.width, _applePasteControlView.frame.size.height);
        UIPasteControl *pc = [[UIPasteControl alloc] initWithFrame:rectPC];
        pc.target = self;
        [_applePasteControlView addSubview:pc];
        
        CGRect rectBC = CGRectMake(0, 0, _branchPasteControlView.frame.size.width, _branchPasteControlView.frame.size.height);
        BranchPasteControl *bc = [[BranchPasteControl alloc] initWithFrame:rectBC AndConfiguration:nil];
        [_branchPasteControlView addSubview:bc];
        
        pasteConfiguration = [[UIPasteConfiguration alloc] initWithAcceptableTypeIdentifiers:@[UTTypeURL.identifier]];
    }
}

- (void)pasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders {
    if (@available(iOS 16, macCatalyst 16.0, *)) {
        [[Branch getInstance] passPasteItemProviders:itemProviders];
    }
}

- (BOOL)canPasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders {
    for (NSItemProvider* item in itemProviders)
        if (@available(iOS 14.0, macCatalyst 14.0, *)) {
            if ( [item hasItemConformingToTypeIdentifier: UTTypeURL.identifier] )
                return true;
        }
    return false;
}

- (IBAction)sendOpenEvent:(id)sender {
    [(AppDelegate  *)[[UIApplication sharedApplication] delegate] setLogFile:@"Open"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
  }

- (IBAction)showLogs:(id)sender {
    UINavigationController *navigationController =
        (UINavigationController *)self.view.window.rootViewController;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LogOutputViewController *logOutputViewController =
        [storyboard instantiateViewControllerWithIdentifier:@"LogOutputViewController"];
   
    [navigationController pushViewController:logOutputViewController animated:YES];
    
    NSString *logFileContents = [NSString stringWithContentsOfFile:((AppDelegate *)[UIApplication sharedApplication].delegate).PrevCommandLogFileName encoding:NSUTF8StringEncoding error:nil];
    logOutputViewController.logOutput = [NSString stringWithFormat:@"%@", logFileContents];
}

@end

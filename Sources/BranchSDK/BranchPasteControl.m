//
//  BranchPasteControl.m
//  Branch
//
//  Created by Nidhi Dixit on 9/26/22.
//  Copyright © 2022 Branch, Inc. All rights reserved.
//

#if !TARGET_OS_TV
#import "BranchPasteControl.h"
#import "Branch.h"

@implementation BranchPasteControl

@synthesize pasteConfiguration;

// Make it designated initializer and block all others.
- (instancetype)initWithFrame:(CGRect)frame AndConfiguration:( UIPasteControlConfiguration * _Nullable) config {
    
    self = [super initWithFrame:frame];
    if(self){
        // 1. Create a UIPasteControl with dimensions = frame or with given configuration // 2. add it as subview to current view
        UIPasteControl *pc;
        CGRect rect = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        if(config){
            pc = [[UIPasteControl alloc] initWithConfiguration:config];
            pc.frame = rect;
        } else {
            
            pc = [[UIPasteControl alloc] initWithFrame:rect];
        }
        [self addSubview:pc];
        
        // 3. Setup pasteConfiguration
        pasteConfiguration = [[UIPasteConfiguration alloc] initWithAcceptableTypeIdentifiers:@[UTTypeURL.identifier]];
        pc.target = self;
    }
    return self;
}

- (void)pasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders {
    [[Branch getInstance] passPasteItemProviders:itemProviders];
}

- (BOOL)canPasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders {
    for (NSItemProvider* item in itemProviders)
        if ( [item hasItemConformingToTypeIdentifier: UTTypeURL.identifier] )
            return true;
    return false;
}

@end
#endif

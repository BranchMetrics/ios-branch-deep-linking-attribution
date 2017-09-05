//
//  BNCDeepLinkViewControllerInstance.h
//  Branch-TestBed
//
//  Created by Parth Kalavadia on 5/15/17.
//  Copyright © 2017 Parth Kalavadia. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BranchDeepLinkingController.h"
@interface BNCDeepLinkViewControllerInstance : NSObject

@property (strong, nonatomic)UIViewController<BranchDeepLinkingController>* viewController;
@property (assign)BNCViewControllerPresentationOption option;

@end
